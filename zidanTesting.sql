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
