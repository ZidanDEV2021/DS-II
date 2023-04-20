CREATE TRIGGER T_Update_Team_Stats
AFTER UPDATE ON Game_Team_Stats
FOR EACH ROW
BEGIN
  DECLARE home_goals INT;
  DECLARE away_goals INT;
  
  SELECT SUM(CASE WHEN team_id = NEW.home_team_id THEN goals ELSE 0 END) INTO home_goals
  FROM Game_Team_Stats
  WHERE game_id = NEW.game_id;
  
  SELECT SUM(CASE WHEN team_id = NEW.away_team_id THEN goals ELSE 0 END) INTO away_goals
  FROM Game_Team_Stats
  WHERE game_id = NEW.game_id;
  
  IF NEW.goals <> OLD.goals THEN
    UPDATE Game SET
      home_team_goals = home_team_goals + (CASE WHEN NEW.team_id = NEW.home_team_id THEN NEW.goals - OLD.goals ELSE 0 END),
      away_team_goals = away_team_goals + (CASE WHEN NEW.team_id = NEW.away_team_id THEN NEW.goals - OLD.goals ELSE 0 END)
    WHERE id = NEW.game_id;
  END IF;
END;

Nedava to moc smysl  je to 1B ?
To SELECT SUM(CASE WHEN team_id = NEW.home_team_id THEN goals ELSE 0 END) INTO home_goals nejak nesedí 
je to 1b chat gpt je mimo trosku
