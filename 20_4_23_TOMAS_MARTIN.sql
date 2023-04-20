-- 1B

CREATE PROCEDURE P_Set_Goalie_Stats (p_game_id INT, p_player_id INT, p_home_or_away CHAR(1), p_shots INT, p_saves INT)
BEGIN
  DECLARE v_team_id INT;
  DECLARE v_stat_id INT;
  
  -- Check if record exists
  SELECT team_id, stat_id
  INTO v_team_id, v_stat_id
  FROM Game_Goalie_Stats
  WHERE game_id = p_game_id
    AND player_id = p_player_id;
    
  IF v_stat_id IS NULL THEN
    -- Record does not exist, create new record
    INSERT INTO Game_Goalie_Stats (game_id, player_id, team_id, shots, saves)
    VALUES (p_game_id, p_player_id, CASE WHEN p_home_or_away = 'H' THEN home_team_id ELSE away_team_id END, p_shots, p_saves);
  ELSE
    -- Record exists, update stats
    UPDATE Game_Goalie_Stats
    SET shots = p_shots, saves = p_saves
    WHERE stat_id = v_stat_id;
  END IF;
END;

--Pis co nejde kdyztak 
--Plus nebudou sedet nazvy nekterych atributu 

-- dominik jednicku ti dela tomas uz a na dvojku se zkus podivat na moje XML
-- melo by to byt podobne: martin.sql


-- 1A PRO DOMINIKA

CREATE OR REPLACE TRIGGER T_Update_Game
BEFORE UPDATE ON GAME
FOR EACH ROW
BEGIN
    IF :OLD.home_goals <> :NEW.home_goals OR :OLD.away_goals <> :NEW.away_goals THEN
        UPDATE Game_Teams_Stats
        SET GOALS = 
            CASE 
                WHEN team_id = :NEW.home_team_id THEN :NEW.home_goals
                WHEN team_id = :NEW.away_team_id THEN :NEW.away_goals
            END
        WHERE game_id = :NEW.game_id;

        IF :NEW.home_goals > :NEW.away_goals THEN
            :NEW.outcome := 'home win';
        ELSIF :NEW.away_goals > :NEW.home_goals THEN
            :NEW.outcome := 'away win';
        ELSE
            :NEW.outcome := 'draw';
        END IF;
    END IF;
END;

Error starting at line : 33 in command -
UPDATE GAME
SET away_goals = 6
where game_id = 2000020062
Error report -
ORA-04091: tabulka MLC0044.GAME je měněna, trigger/funkce ji nemusí vidět
ORA-06512: na "MLC0044.T_UPDATE_TEAM_STAT", line 7
ORA-04088: chyba během provádění triggeru 'MLC0044.T_UPDATE_TEAM_STAT'
ORA-06512: na "MLC0044.T_UPDATE_GAME", line 3
ORA-04088: chyba během provádění triggeru 'MLC0044.T_UPDATE_GAME'
-- FUNKCNI TRIGGER - 11:22 
