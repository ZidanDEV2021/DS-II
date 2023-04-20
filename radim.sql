CREATE OR REPLACE TRIGGER T_Update_Skater_Stats
AFTER UPDATE OF goals ON Game_Skater_Stats
FOR EACH ROW
DECLARE
   v_team_id Game_Skater_Stats.team_id%TYPE;
   v_game_id Game_Skater_Stats.game_id%TYPE;
   v_old_goals Game_Skater_Stats.goals%TYPE;
   v_new_goals Game_Skater_Stats.goals%TYPE;
   v_goals_diff NUMBER;
BEGIN
   -- Get the team and game IDs of the updated Game_Skater_Stats entry
   SELECT team_id, game_id, :OLD.goals, :NEW.goals
   INTO v_team_id, v_game_id, v_old_goals, v_new_goals
   FROM Game_Skater_Stats
   WHERE player_id = :NEW.player_id AND game_id = :NEW.game_id;
   
   -- Check if goals statistics have changed
   IF v_old_goals <> v_new_goals THEN
      -- Determine whether it's the home or away team
      DECLARE
         v_home_team_id Game.home_team_id%TYPE;
         v_away_team_id Game.away_team_id%TYPE;
         v_home_goals Game.home_goals%TYPE;
         v_away_goals Game.away_goals%TYPE;
      BEGIN
         SELECT home_team_id, away_team_id, home_goals, away_goals
         INTO v_home_team_id, v_away_team_id, v_home_goals, v_away_goals
         FROM Game
         WHERE game_id = v_game_id;
         
         IF v_home_team_id = v_team_id THEN
            v_goals_diff := v_new_goals - v_old_goals;
            UPDATE Game SET home_goals = home_goals + v_goals_diff WHERE game_id = v_game_id;
         ELSIF v_away_team_id = v_team_id THEN
            v_goals_diff := v_new_goals - v_old_goals;
            UPDATE Game SET away_goals = away_goals + v_goals_diff WHERE game_id = v_game_id;
         END IF;
      END;
   END IF;
END;
/




DVOJKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa
CREATE OR REPLACE FUNCTION F_Export_Game_Stats(p_game_id IN Game.game_id%TYPE)
RETURN CLOB
IS
   v_xml XMLTYPE;
   v_output CLOB;
BEGIN
   -- Get the game info
   SELECT '<game id="' || game_id || '">' ||
          '<home_team id="' || home_team_id || '" abbrev="' || home_team_abbrev || '"/>' ||
          '<away_team id="' || away_team_id || '" abbrev="' || away_team_abbrev || '"/>' ||
          '<ice_time_leaders>' ||
          (
             -- Get the top three players with longest time on ice
             SELECT '<player><first_name>' || first_name || '</first_name>' ||
                    '<last_name>' || last_name || '</last_name>' ||
                    '<time_on_ice>' || time_on_ice || '</time_on_ice></player>'
             FROM (
                    SELECT player.first_name, player.last_name, game_skater_stats.time_on_ice
                    FROM game_skater_stats
                    INNER JOIN player ON game_skater_stats.player_id = player.player_id
                    WHERE game_skater_stats.game_id = p_game_id
                    ORDER BY game_skater_stats.time_on_ice DESC
                 )
             WHERE ROWNUM <= 3
             FOR XML PATH('')
          ) ||
          '</ice_time_leaders>' ||
          '</game>'
   INTO v_xml
   FROM Game
   WHERE game_id = p_game_id;
   
   v_output := v_xml.getClobVal();
   
   RETURN v_output;
END;
/


