
zadani na dc
nefacha more
tak to uprav more
nejde MORE
jdeme na tom makat
je to vpiči more
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

-- dvojkaaaaaa
CREATE OR REPLACE FUNCTION F_Export_Game_Stats(p_game_id IN NUMBER)
RETURN VARCHAR2
IS
  -- Declare a cursor to retrieve the game stats
  CURSOR game_stats_cur IS
    SELECT gss.goals, pi.first_name, pi.last_name, pi.primary_position
    FROM game_skater_stats gss
    JOIN player_info pi ON gss.player_id = pi.player_id
    WHERE gss.game_id = p_game_id;

  -- Declare a variable to hold the JSON string
  v_json_string VARCHAR2(4000) := '';

  -- Declare a dictionary to store the players by position
  v_players_by_position DBMS_JSON.KEY_VALUE_LIST;
BEGIN
  -- Loop through the game stats and group the players by position
  FOR gs_rec IN game_stats_cur LOOP
    -- Check if the position is already in the dictionary
    IF DBMS_JSON.EXISTS(v_players_by_position, gs_rec.primary_position) THEN
      -- Add the player's info to the existing position
      DBMS_JSON.APPEND(v_players_by_position(gs_rec.primary_position),
                       DBMS_JSON.OBJECT('first_name', gs_rec.first_name,
                                        'last_name', gs_rec.last_name,
                                        'goals_scored', gs_rec.goals));
    ELSE
      -- Create a new position in the dictionary and add the player's info
      v_players_by_position(gs_rec.primary_position) := DBMS_JSON.ARRAY(DBMS_JSON.OBJECT('first_name', gs_rec.first_name,
                                                                                            'last_name', gs_rec.last_name,
                                                                                            'goals_scored', gs_rec.goals));
    END IF;
  END LOOP;

  -- Convert the dictionary to a JSON string
  v_json_string := DBMS_JSON.TO_JSON(v_players_by_position);

  -- Return the JSON string
  RETURN v_json_string;
END;
/

-- kamo tady jsem dizzy af, to bude asi spatne dost idk kamo sorac puseno
