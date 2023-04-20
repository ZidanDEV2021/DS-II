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
AFTER UPDATE ON GAME
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
            UPDATE GAME
            SET outcome = 'home win'
            WHERE GAME_ID = :NEW.GAME_ID;
        ELSIF :NEW.away_goals > :NEW.home_goals THEN
            UPDATE GAME
            SET outcome = 'away win'
            WHERE GAME_ID = :NEW.GAME_ID;
        ELSE
            UPDATE GAME
            SET outcome = 'draw'
            WHERE GAME_ID = :NEW.GAME_ID;
        END IF;
    END IF;
END;

-- Zkus mozna to jede - druha oprava 11:15
