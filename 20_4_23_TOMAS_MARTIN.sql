
CREATE OR REPLACE TRIGGER T_Update_Team_Stat
AFTER UPDATE OF goals ON Game_Teams_Stats
FOR EACH ROW
BEGIN
    IF :new.hoa like 'home' AND :new.goals <> :old.goals THEN
        UPDATE Game
        SET home_goals = home_goals + (:new.goals - :old.goals)
        WHERE game_id = :new.game_id;
    ELSIF :new.hoa like 'away' AND :new.goals <> :old.goals THEN
        UPDATE Game
        SET away_goals = away_goals + (:new.goals - :old.goals)
        WHERE game_id = :new.game_id;
    END IF;
END; vymaz si manualne stary trigger neslo to lvuli toho, mel jsem porad ulozeny ten stary trigger a neslo to pres drop vis co
