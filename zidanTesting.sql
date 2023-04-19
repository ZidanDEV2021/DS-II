CREATE OR REPLACE TRIGGER TDeleteGameEvent BEFORE DELETE ON GAME_PLAYS
FOR EACH ROW
DECLARE
    v_home_team_id INT;
BEGIN

    SELECT HOME_TEAM_ID INTO v_home_team_id FROM GAME WHERE GAME_ID = :OLD.GAME_ID;

    IF :OLD.EVENT = 'GOAL' THEN
        IF :OLD.TEAM_ID_FOR = v_home_team_id THEN
            UPDATE GAME 
            SET HOME_GOALS = HOME_GOALS - 1 
            WHERE GAME_ID = :OLD.GAME_ID;
            
            UPDATE GAME_TEAMS_STATS 
            SET GOALS = GOALS - 1
            WHERE GAME_ID = :OLD.GAME_ID AND TEAM_ID = :OLD.TEAM_ID_FOR;
        ELSE
            UPDATE GAME 
            SET AWAY_GOALS = AWAY_GOALS - 1
            WHERE GAME_ID = :OLD.GAME_ID;
           
            UPDATE GAME_TEAMS_STATS
            SET GOALS = GOALS - 1
            WHERE GAME_ID = :OLD.GAME_ID AND TEAM_ID = :OLD.TEAM_ID_FOR;
        END IF;
    
    ELSIF :OLD.EVENT = 'Shot' THEN
        UPDATE GAME_TEAMS_STATS 
        SET SHOTS = SHOTS - 1
        WHERE GAME_ID = :OLD.GAME_ID AND TEAM_ID = :OLD.TEAM_ID_FOR;
    END IF;
END;

-------

CREATE OR REPLACE PROCEDURE PCheckGame(p_gameID GAME_OFFICIALS.GAME_ID%TYPE, p_gameName GAME_OFFICIALS.OFFICIAL_NAME%TYPE, p_offType GAME_OFFICIALS.OFFICIAL_TYPE%TYPE) AS
    v_gameID INT;
    v_games_count INT;
BEGIN
    
    SELECT GAME_ID INTO v_gameID FROM GAME_OFFICIALS WHERE GAME_ID = p_gameID;
    
    IF p_gameID != v_gameID THEN
        dbms_output.put_line('Hra neexistuje');
        RETURN;
    END IF;
    
    IF p_offType != 'linesman' AND p_offType != 'referee' THEN
        dbms_output.put_line('Neexistující typ rozhodčího');
        RETURN;
    END IF;
    
    SELECT COUNT(*) INTO v_games_count
    FROM GAME JOIN GAME_OFFICIALS ON GAME.GAME_ID = GAME_OFFICIALS.GAME_ID
    WHERE GAME_OFFICIALS.OFFICIAL_NAME LIKE p_gameName AND GAME.DATE_TIME_GMT BETWEEN '10-MAR-15' AND '26-SEP-16'; 
    
    IF v_games_count > 100 THEN
        dbms_output.put_line('Neexistující typ rozhodčího');
        RETURN;
    ELSE
        INSERT INTO GAME_OFFICIALS(GAME_ID, OFFICIAL_NAME, OFFICIAL_TYPE)
        VALUES (p_gameID, p_gameName, p_offType);
    END IF;

END;
