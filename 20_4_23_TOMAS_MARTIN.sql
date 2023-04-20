
CREATE OR REPLACE TRIGGER T_Update_Team_Stat
AFTER UPDATE OF goals ON Game_Teams_Stats
FOR EACH ROW
BEGIN
    IF :new.hoa like 'home' THEN
        UPDATE Game
        SET home_goals = (home_goals + (:new.goals - :old.goals))
        WHERE game_id = :new.game_id;
    ELSIF :new.hoa like 'away' THEN
        UPDATE Game
        SET away_goals = (away_goals + (:new.goals - :old.goals))
        WHERE game_id = :new.game_id;
    END IF;
END; vymaz si manualne stary trigger neslo to lvuli toho
