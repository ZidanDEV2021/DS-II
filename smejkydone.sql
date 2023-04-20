create or replace PROCEDURE P_Create_Game(
    p_home_short_name IN Game.home_team_id%TYPE,
    p_away_short_name IN Game.away_team_id%TYPE,
    p_date_time IN game.date_time_gmt%TYPE,
    p_venue IN Game.venue%TYPE
) AS
    v_season Game.season%TYPE;
    v_game_id Game.game_id%TYPE;
BEGIN

    IF EXTRACT(MONTH FROM p_date_time) BETWEEN 1 AND 7 THEN
        v_season := TO_CHAR(p_date_time - INTERVAL '1' YEAR, 'YYYY') || TO_CHAR(p_date_time, 'YYYY');
    ELSE
        v_season := TO_CHAR(p_date_time, 'YYYY') || TO_CHAR(p_date_time + INTERVAL '1' YEAR, 'YYYY');
    END IF;   

    SELECT MAX(game_id) INTO v_game_id
    FROM Game
    WHERE 
    (
        (
            (home_team_id = p_home_short_name AND away_team_id = p_away_short_name)
            OR 
            (home_team_id = p_away_short_name AND away_team_id = p_home_short_name) 
        )
        AND type = 'R'
    )
    AND date_time_gmt = p_date_time;

    IF v_game_id IS NOT NULL THEN
        dbms_output.put_line('chyba tyto tymy proti sobe jiz hraji: ' || p_home_short_name || ' and ' || p_away_short_name);
        RETURN;
    END IF;

    SELECT NVL(MAX(game_id), 0) + 1 INTO v_game_id FROM Game;

    INSERT INTO Game (game_id, season, "TYPE", date_time_gmt, away_team_id, home_team_id, venue)
    VALUES (v_game_id, v_season, 'R', p_date_time, p_away_short_name, p_home_short_name, p_venue);

    dbms_output.put_line('ID nove hry: ' || v_game_id);
END P_Create_Game;
