TEST :)
Ahoj tady je Tomas
Mam getstats xddddddddddddddddddddddddddddd

CREATE OR REPLACE FUNCTION Get_Stats(year_from IN NUMBER, year_to IN NUMBER, stats_type IN VARCHAR2) RETURN NUMBER AS
  num_stats NUMBER;
BEGIN
  IF year_from > year_to OR NOT(stats_type IN ('games', 'goals', 'skaters', 'goalies')) THEN
    num_stats := -1;
  ELSE
    IF stats_type = 'games' THEN
      SELECT COUNT(*) INTO num_stats FROM game WHERE season BETWEEN year_from AND year_to;
    ELSIF stats_type = 'goals' THEN
      SELECT SUM(away_goals + home_goals) INTO num_stats FROM game WHERE season BETWEEN year_from AND year_to;
    ELSIF stats_type = 'skaters' THEN
      SELECT COUNT(DISTINCT player_id) INTO num_stats FROM game_plays_players WHERE play_id IN (
        SELECT play_id FROM game_plays WHERE game_id IN (
          SELECT game_id FROM game WHERE season BETWEEN year_from AND year_to
        )
      ) AND playerType != 'Goalie';
    ELSE
      SELECT COUNT(DISTINCT player_id) INTO num_stats FROM game_goalie_stats WHERE game_id IN (
        SELECT game_id FROM game WHERE season BETWEEN year_from AND year_to
      );
    END IF;
  END IF;
  RETURN num_stats;
END;
/

CREATE OR REPLACE PROCEDURE Print_Stats(year_from IN NUMBER, year_to IN NUMBER) AS
BEGIN
  dbms_output.put_line('Období: ' || year_from || '-' || year_to);
  dbms_output.put_line('Počet odehraných zápasů: ' || Get_Stats(year_from, year_to, 'games'));
  dbms_output.put_line('Počet vstřelených gólů: ' || Get_Stats(year_from, year_to, 'goals'));
  dbms_output.put_line('Počet hráčů: ' || Get_Stats(year_from, year_to, 'skaters'));
  dbms_output.put_line('Počet brankářů: ' || Get_Stats(year_from, year_to, 'goalies'));
END;
/
