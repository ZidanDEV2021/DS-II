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
