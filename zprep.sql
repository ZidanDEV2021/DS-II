--zadani 1

create or replace FUNCTION GetStats(p_year_from int, p_year_to int, p_stats_type varchar)
RETURN int
AS
  v_cnt integer;
BEGIN
  if (p_stats_type = 'games') then
    select count(*) into v_cnt from game where extract(year from date_time_gmt) between p_year_from and p_year_to;

  elsif (p_stats_type = 'goals') then
    select count(*) into v_cnt from game 
    join game_plays on game_plays.game_id = game.game_id
    where extract(year from date_time_gmt) between p_year_from and p_year_to
    and event = 'Goal';

  elsif (p_stats_type = 'skaters') then
    select count(distinct pss.player_id) into v_cnt from game_skater_stats pss
    join game g on pss.game_id = g.game_id
    where extract(year from date_time_gmt) between p_year_from and p_year_to;

  elsif (p_stats_type = 'goalies') then
    select count(distinct pgs.player_id) into v_cnt from game_goalie_stats pgs
    join game g on pgs.game_id = g.game_id
    where extract(year from date_time_gmt) between p_year_from and p_year_to;
  else
    v_cnt := -1;
  end if;
   return v_cnt;
END;


--zadani2


create or replace PROCEDURE P_UPDATE_SKATER_GOALS(p_game_id INT, p_player_id INT, p_goals INT) AS
    v_team_id INT;
    v_home_team_id INT;
    v_away_team_id INT;
    v_cnt INT;
BEGIN
    SELECT team_id INTO v_team_id
    FROM Game_skater_stats
    WHERE
        game_id = p_game_id AND
        player_id = p_player_id;

    SELECT home_team_id, away_team_id INTO v_home_team_id, v_away_team_id
    FROM Game
    WHERE game_id = p_game_id;

    UPDATE Game_skater_stats
    SET goals = p_goals
    WHERE
        game_id = p_game_id AND
        player_id = p_player_id;

    IF v_team_id = v_home_team_id THEN
        UPDATE Game
        SET home_goals = 
            (
                SELECT SUM(goals)
                FROM Game_skater_stats
                WHERE Game.home_team_id = Game_skater_stats.team_id AND Game_skater_stats.game_id = p_game_id
            )
        WHERE game_id = p_game_id;
    ELSIF v_team_id = v_away_team_id THEN
        UPDATE Game
        SET away_goals = 
            (
                SELECT SUM(goals)
                FROM Game_skater_stats
                WHERE Game.away_team_id = Game_skater_stats.team_id AND Game_skater_stats.game_id = p_game_id
            )
        WHERE game_id = p_game_id;
    END IF;
END;
