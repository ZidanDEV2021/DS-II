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
