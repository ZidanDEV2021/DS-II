CREATE OR REPLACE TRIGGER T_Update_Team_Stat
AFTER UPDATE OF goals ON Game_Teams_Stats
FOR EACH ROW
DECLARE
    home_goals NUMBER;
    away_goals NUMBER;
BEGIN
    SELECT home_team_id, away_team_id INTO home_goals, away_goals
    FROM Game join Game_Teams_Stats on game.game_id = Game_Teams_Stats.game_id
    WHERE Game_Teams_Stats.game_id = :new.game_id;

    IF :new.team_id = home_goals THEN
        UPDATE Game
        SET home_goals = home_goals + (:new.goals - :old.goals)
        WHERE game_id = :new.game_id;
    ELSIF :new.team_id = away_goals THEN
        UPDATE Game
        SET away_goals = away_goals + (:new.goals - :old.goals)
        WHERE game_id = :new.game_id;
    END IF;
END; tohle se spousti
