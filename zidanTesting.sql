SELECT * FROM STUDENT
SELECT * FROM TEACHER

CREATE TRIGGER assign_referee_to_game
BEFORE INSERT ON games_referees
FOR EACH ROW
DECLARE
  num_referees INT;
BEGIN
  SELECT COUNT(*) INTO num_referees FROM games_referees WHERE game_id = :NEW.game_id;
  
  IF NOT EXISTS(SELECT * FROM games WHERE id = :NEW.game_id) THEN
    dbms_output.put_line('The game does not exist');
    RETURN;
  ELSIF :NEW.referee_type NOT IN ('referee', 'linesman') THEN
    dbms_output.put_line('Referee type does not exist');
    RETURN;
  ELSIF num_referees >= 4 THEN
    dbms_output.put_line('Maximum number of referees per game');
    RETURN;
  ELSE
    -- All checks pass, assign the referee to the game
    INSERT INTO games_referees (game_id, referee_name, referee_type) VALUES (:NEW.game_id, :NEW.name, :NEW.referee_type);
  END IF;
END;

RAISE_APPLICATION jsem změnil na RETURN ale nejsem si jisty jestli to je spravne


CREATE FUNCTION calculate_vulnerability()
RETURNS INTEGER
AS
DECLARE
  team_id INTEGER;
  num_penalties INTEGER;
  num_teams_processed INTEGER := 0;
BEGIN
  FOR team_id IN (SELECT DISTINCT team_id_for, team_id_against FROM game_plays_players)
  LOOP
    num_penalties := (
      SELECT COUNT(*)
      FROM game_plays_players
      JOIN game_plays ON game_plays.id = game_plays_players.game_play_id
      WHERE (team_id_for = team_id OR team_id_against = team_id)
        AND game_plays.event = 'Penalty'
        AND game_plays_players.playertype = 'Penalty'
    );
    
    IF num_penalties < 750 THEN
      UPDATE team_info SET vulnerability = 0 WHERE id = team_id;
    ELSIF num_penalties <= 1250 THEN
      UPDATE team_info SET vulnerability = 1 WHERE id = team_id;
    ELSE
      UPDATE team_info SET vulnerability = 2 WHERE id = team_id;
    END IF;
    
    num_teams_processed := num_teams_processed + 1;
  END LOOP;
  
  RETURN num_teams_processed;
END;
