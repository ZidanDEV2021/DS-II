--1 priklad
CREATE OR REPLACE PROCEDURE P_Create_Game (
    p_home_short_name IN Game.team_short_name%TYPE,
    p_away_short_name IN Game.team_short_name%TYPE,
    p_date_time IN Game.game_datetime%TYPE,
    p_venue IN Game.venue%TYPE
) AS
    v_home_team_id Game.team_id%TYPE;
    v_away_team_id Game.team_id%TYPE;
    v_season Game.season%TYPE;
    v_game_id Game.game_id%TYPE;
BEGIN
    -- Determine home team ID
    SELECT team_id INTO v_home_team_id
    FROM Team
    WHERE team_short_name = p_home_short_name;
    
    -- Determine away team ID
    SELECT team_id INTO v_away_team_id
    FROM Team
    WHERE team_short_name = p_away_short_name;
    
    -- Determine season
    IF EXTRACT(MONTH FROM p_date_time) BETWEEN 1 AND 7 THEN
        v_season := TO_CHAR(p_date_time - INTERVAL '1' YEAR, 'YYYY') || TO_CHAR(p_date_time, 'YYYY');
    ELSE
        v_season := TO_CHAR(p_date_time, 'YYYY') || TO_CHAR(p_date_time + INTERVAL '1' YEAR, 'YYYY');
    END IF;
    
    -- Check for existing regular season match between the two teams
    SELECT MAX(game_id) INTO v_game_id
    FROM Game
    WHERE (home_team_id = v_home_team_id AND away_team_id = v_away_team_id)
    OR (home_team_id = v_away_team_id AND away_team_id = v_home_team_id)
    AND type = 'R';
    
    IF v_game_id IS NOT NULL THEN
        dbms_output.put_line('Error: There is already a regular season match between ' || p_home_short_name || ' and ' || p_away_short_name);
        RETURN;
    END IF;
    
    -- Insert new game record
    SELECT NVL(MAX(game_id), 0) + 1 INTO v_game_id FROM Game;
    
    INSERT INTO Game (game_id, home_team_id, away_team_id, game_datetime, venue, season, type)
    VALUES (v_game_id, v_home_team_id, v_away_team_id, p_date_time, p_venue, v_season, 'R');
    
    dbms_output.put_line('New game record created with ID: ' || v_game_id);
END P_Create_Game;

/*
We declare the procedure with four input parameters: p_home_short_name, p_away_short_name, p_date_time, and p_venue.

We declare some variables to store the home and away team IDs, season number, and new game ID.

We determine the home team ID and away team ID by querying the Team table based on the input parameters p_home_short_name and p_away_short_name.

We determine the season number based on the month and year of p_date_time. If the month is January to July, we concatenate the previous and current year; otherwise, we concatenate the current and next year.

We check if there is already a regular season match between the two teams by querying the Game table. If there is, we print an error message and exit the procedure.

We determine the new game ID by finding the highest existing ID in the Game table and incrementing it by 1.

We insert a new record into the Game table with the new game ID,
*/


-- 2.

CREATE OR REPLACE FUNCTION F_Export_Game_Stats (
    p_game_id IN Game.game_id%TYPE
) RETURN CLOB AS
    v_xml CLOB;
BEGIN
    SELECT XMLAGG(
        XMLELEMENT("game",
            XMLFOREST(home_team_id AS "home_team_id", home_team_name AS "home_team_name",
                      away_team_id AS "away_team_id", away_team_name AS "away_team_name"),
            XMLAGG(
                XMLELEMENT("player",
                    XMLFOREST(p.first_name AS "first_name", p.last_name AS "last_name", t.team_name AS "team_name"),
                    XMLATTRIBUTES(p.player_id AS "player_id", s.goals AS "goals")
                )
            )
        )
    )
    INTO v_xml
    FROM (
        SELECT g.home_team_id, t1.team_name AS home_team_name,
               g.away_team_id, t2.team_name AS away_team_name
        FROM Game g
        JOIN Team t1 ON g.home_team_id = t1.team_id
        JOIN Team t2 ON g.away_team_id = t2.team_id
        WHERE g.game_id = p_game_id
    ) game
    JOIN (
        SELECT s.player_id, s.team_id, s.goals, ROW_NUMBER() OVER (ORDER BY s.goals DESC) AS rank
        FROM Score s
        WHERE s.game_id = p_game_id
    ) s ON game.home_team_id = s.team_id OR game.away_team_id = s.team_id
    JOIN Player p ON s.player_id = p.player_id
    JOIN Team t ON s.team_id = t.team_id
    WHERE s.rank <= 3
    GROUP BY game.home_team_id, game.home_team_name, game.away_team_id, game.away_team_name;
    
    RETURN v_xml;
END F_Export_Game_Stats;

/*
Explanation of the code:

We declare the function with one input parameter p_game_id of type Game.game_id%TYPE and return type CLOB.

We declare a variable v_xml of type CLOB to store the XML string.

We use the XMLAGG and XMLELEMENT functions to generate the XML string. We start by creating a root element named "game" and add child elements for the home and away teams, using the XMLFOREST function to specify the element names and values.

We use a subquery to get the team names for the given game ID.

We join the Score table to get the players who scored goals in the match, and use the ROW_NUMBER function to rank them by the number of goals.

We join the Player and Team tables to get the names of the players and the team they played for, and filter the results to include only the top 3 scorers.

We group the results by the home and away team IDs and names.

Finally, we return the XML string using the RETURN statement.

Note: This code assumes that the Game, Team, Score, and Player tables are already created in the database and contain the necessary columns. It also assumes that the Score table has a foreign key constraint on Game.game_id and Team.team_id.

*/
