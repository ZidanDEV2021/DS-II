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


--changed

create or replace FUNCTION GetStats(p_year_from int, p_year_to int, p_stats_type varchar)
RETURN int
AS
  v_cnt integer;
BEGIN
  if (p_stats_type = 'games') then
    select count(game_id) into v_cnt from game where extract(year from date_time_gmt) between p_year_from and p_year_to;

  elsif (p_stats_type = 'goals') then
    select count(gp.play_id) into v_cnt from game g
    join game_plays gp on gp.game_id = g.game_id and gp.event = 'Goal'
    where extract(year from date_time_gmt) between p_year_from and p_year_to;

  elsif (p_stats_type = 'skaters') then
    select count(distinct gss.player_id) into v_cnt from game g
    join game_skater_stats gss on gss.game_id = g.game_id
    where extract(year from date_time_gmt) between p_year_from and p_year_to;

  elsif (p_stats_type = 'goalies') then
    select count(distinct ggs.player_id) into v_cnt from game g
    join game_goalie_stats ggs on ggs.game_id = g.game_id
    where extract(year from date_time_gmt) between p_year_from and p_year_to;
  else
    v_cnt := -1;
  end if;
   return v_cnt;
END;


SELECT GetStats(2000, 2005, 'skaters') as num_skaters FROM dual;

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


--zadani 3

create or replace PROCEDURE P_CREATE_GAME(p_home_short_name VARCHAR, p_away_short_name VARCHAR, p_date_time DATE, p_venue VARCHAR) AS
    v_home_team_id INT;
    v_away_team_id INT;
    v_cnt INT;
    v_now DATE;
    v_year INT;
    v_month INT;
    v_season VARCHAR(20);
    v_new_game_id INT;
BEGIN
    SELECT team_id INTO v_home_team_id 
    FROM Team_info
    WHERE shortName = p_home_short_name;

    SELECT team_id INTO v_away_team_id
    FROM Team_info
    WHERE shortName = p_away_short_name;

    v_year := EXTRACT(YEAR FROM p_date_time);
    v_month := EXTRACT(YEAR FROM p_date_time);

    IF v_month <= 7 THEN
        v_season := TO_CHAR(v_year - 1) || TO_CHAR(v_year);
    ELSE
        v_season := TO_CHAR(v_year) || TO_CHAR(v_year + 1);
    END IF;

    SELECT COUNT(*) INTO v_cnt
    FROM DUAL
    WHERE EXISTS (
        SELECT 1
        FROM GAME
        WHERE
            season = v_season AND
            (home_team_id = v_home_team_id AND away_team_id = v_away_team_id OR home_team_id = v_away_team_id AND away_team_id = v_home_team_id) AND
            type = 'R'
    );

    IF v_cnt > 0 THEN
        dbms_output.put_line('V sezone ' || v_season || ' jiz oba tymy proti sobe hrali.');
        RETURN;
    END IF;

    SELECT COALESCE(MAX(game_id), 0) + 1 INTO v_new_game_id
    FROM Game;

    INSERT INTO Game (game_id, season, type, date_time_GMT, away_team_id, home_team_id, home_goals, away_goals, venue)
    VALUES (v_new_game_id, v_season, 'R', p_date_time, v_away_team_id, v_home_team_id, 0, 0, p_venue);
END;

--zadani 4

create or replace procedure PrintBestPlayer(p_nationality char, p_primaryPosition char, p_rowCount int)
as
begin
  for rec in (
    select * from (
      select gss.player_id, player_info.firstname, player_info.lastname, player_info.primaryPosition, sum(assists + goals) as points from game_skater_stats gss
      inner join player_info on gss.player_id=player_info.player_id
      where player_info.nationality=p_nationality and player_info.primaryPosition=p_primaryPosition
      group by gss.player_id, player_info.firstname, player_info.lastname, player_info.primaryPosition
      order by sum(assists + goals) desc
    ) where rownum <= p_rowCount)
  loop
    dbms_output.put_line(rec.player_id || chr(9) || chr(9) || rec.firstname ||  chr(9) || chr(9) || rec.lastname || chr(9) || chr(9) || rec.primaryPosition || chr(9) || chr(9) || rec.points);
  end loop;
end;
--start the function
--order by points
declare
  p_nationality char(3) := 'CAN';
  p_primaryPosition char(2) := 'C';
  p_rowCount int := 5;
begin
  PrintBestPlayer(p_nationality, p_primaryPosition, p_rowCount);
end;

--5

create or replace procedure PrintSeasonStat(p_season char, p_playerPosition varchar)
as
  v_count int := 1;
  v_min int;
  v_sec int;
begin
  dbms_output.put_line('------------------------ Season: ' || p_season || ', Player Position: ' || p_playerPosition || ' ------------------------');
  dbms_output.put_line('#Rank' || chr(9) || 'Player       ' || chr(9) || chr(9) || 'Nat' || chr(9) || 'Points' || chr(9) ||
      'Goals' || chr(9) || 'Assists' || chr(9) || 'PlusMinus'|| chr(9) || 'Games' || chr(9) || 'TimeOnIce' );
  dbms_output.put_line('--------------------------------------------------------------------------------------');

  for rec in (
    select player_info.firstName, player_info.lastName, player_info.nationality,  
      sum(gss.goals) + sum(gss.assists) as Points,  sum(gss.goals) as Goals, sum(gss.assists) as Assists, sum(gss.plusMinus) as PlusMinus,
      count(*) as Games, avg(timeOnIce) as AvgTimeOnIce
    from game_skater_stats gss
    inner join player_info on gss.player_id = player_info.player_id
    inner join game on gss.game_id = game.game_id
    where player_info.primaryPosition=p_playerPosition and game.season = p_season
    group by gss.player_id, player_info.firstName, player_info.lastName, player_info.nationality
    having (sum(gss.goals) + sum(gss.assists)) > 0
    order by Points desc
    fetch next 10 rows only) --top10
  loop
    v_min := floor(rec.AvgTimeOnIce / 60);
    v_sec := rec.AvgTimeOnIce - (v_min * 60);
    dbms_output.put_line('#' || v_count || '.  ' || chr(9) || rec.firstName || ' ' || rec.lastName || ' ' || chr(9) || chr(9) || rec.nationality || chr(9) || rec.Points || chr(9) ||
      rec.Goals || chr(9) || rec.Assists || chr(9) || rec.PlusMinus|| chr(9) || rec.Games || chr(9) || v_min || ':' || v_sec);
    v_count := v_count + 1;
  end loop;
  dbms_output.put_line('--------------------------------------------------------------------------------------');
end; 


--6

create or replace procedure PrintStat(p_season char, p_playerPosition varchar)
as
  int count := 1;
begin

  for rec in (
    select player_info.firstName, player_info.lastName, player_info.nationality,  
      sum(gss.goals) + sum(gss.assists) as Points,  sum(gss.goals) as Goals, sum(gss.assists) as Assists, sum(gss.plusMinus) as PlusMinus,
      avg(timeOnIce) as AvgTimeOnIce
    from game_skater_stats gss
    inner join player_info on gss.player_id = player_info.player_id
    inner join game on gss.game_id = game.game_id
    where player_info.primaryPosition='RW' and game.season = '20192020'
    group by gss.player_id, player_info.firstName, player_info.lastName, player_info.nationality
    having (sum(gss.goals) + sum(gss.assists)) > 0
    order by Points desc
    fetch next 10 rows only)
  loop
    dbms_output.put_line('#' || count || '.  ' || chr(9) || rec.firstName || ' ' || rec.lastName || chr(9) || rec.nat || chr(9) || rec.Points || chr(9) ||
      rec.Goals || chr(9) || rec.Assists || chr(9) || rec.PlusMinus || chr(9) || rec.AvgTimeOnIce);
    count := count + 1;
  end loop;
end;

BEGIN
  PrintStat('20192020', 'RW');
END;
--json


CREATE OR REPLACE FUNCTION F_EXPORT_GAME_STATS_1(p_game_id INT) RETURN CLOB AS
    v_ret CLOB;
    v_home_team_id INT;
    v_away_team_id INT;
    v_home_team_name VARCHAR(50);
    v_away_team_name VARCHAR(50);
    v_first_name VARCHAR(50);
    v_last_name VARCHAR(50);
    v_team_id INT;
BEGIN
    SELECT
        home_team_id, away_team_id,
        (SELECT teamName FROM Team_info WHERE team_id = home_team_id),
        (SELECT teamName FROM Team_info WHERE team_id = away_team_id)
    INTO v_home_team_id, v_away_team_id, v_home_team_name, v_away_team_name
    FROM Game
    WHERE game_id = p_game_id;

    v_ret := '<game id="' || TO_CHAR(p_game_id) || '">
    <home_team id="' || TO_CHAR(v_home_team_id) || '" name="' || v_home_team_name || '" />
    <away_team id="' || TO_CHAR(v_away_team_id) || '" name="' || v_away_team_name || '" />
    <best_players>';

    FOR v_p IN (
        SELECT pi.firstName, pi.lastName, gss.team_id
        FROM
            Game_skater_stats gss
            JOIN Player_info pi ON gss.player_id = pi.player_id
        WHERE
            gss.game_id = p_game_id AND
            goals = 
            (
                SELECT MAX(goals)
                FROM Game_skater_stats gss
                WHERE game_id = p_game_id
            ) AND goals > 0
    ) LOOP  
        v_ret := v_ret || '
        <player>
            <first_name>' || v_p.firstName || '</first_name>
            <last_name>' || v_p.lastName || '</last_name>
            <team_id>' || v_p.team_id || '</team_id>
        </player>';
    END LOOP;

    v_ret := v_ret || '
    </best_players>
</game>';
    RETURN v_ret;
END;


CREATE OR REPLACE FUNCTION F_EXPORT_GAME_STATS_2(p_game_id INT) RETURN CLOB AS
    v_ret CLOB;
    v_home_team_id INT;
    v_away_team_id INT;
    v_home_team_abbrev VARCHAR(50);
    v_away_team_abbrev VARCHAR(50);
    v_first_name VARCHAR(50);
    v_last_name VARCHAR(50);
    v_team_id INT;
BEGIN
    SELECT
        home_team_id, away_team_id,
        (SELECT abbreviation FROM Team_info WHERE team_id = home_team_id),
        (SELECT abbreviation FROM Team_info WHERE team_id = away_team_id)
    INTO v_home_team_id, v_away_team_id, v_home_team_abbrev, v_away_team_abbrev
    FROM Game
    WHERE game_id = p_game_id;

    v_ret := '<game id="' || TO_CHAR(p_game_id) || '">
    <home_team id="' || TO_CHAR(v_home_team_id) || '" abbrev="' || v_home_team_abbrev || '" />
    <away_team id="' || TO_CHAR(v_away_team_id) || '" abbrev="' || v_away_team_abbrev || '" />
    <ice_time_leaders>';

    FOR v_p IN (
        SELECT pi.firstName, pi.lastName, gss.timeOnIce
        FROM
            Game_skater_stats gss
            JOIN Player_info pi ON gss.player_id = pi.player_id
        WHERE
            gss.game_id = p_game_id
        ORDER BY timeOnIce DESC            
        FETCH FIRST 3 ROWS ONLY
    ) LOOP  
        v_ret := v_ret || '
        <player>
            <first_name>' || v_p.firstName || '</first_name>
            <last_name>' || v_p.lastName || '</last_name>
            <time_on_ice>' || v_p.timeOnIce || '</time_on_ice>
        </player>';
    END LOOP;

    v_ret := v_ret || '
    </ice_time_leaders>
</game>';
    RETURN v_ret;
END;




CREATE OR REPLACE FUNCTION F_EXPORT_GAME_STATS_3(p_game_id INT) RETURN CLOB AS
    v_ret CLOB;
    v_first_name VARCHAR(50);
    v_last_name VARCHAR(50);
    v_team_id INT;
    v_prev_primaryPosition VARCHAR(10);
BEGIN
    v_ret := '<game id="' || TO_CHAR(p_game_id) || '">
    <players>';

    v_prev_primaryPosition := ' ';

    FOR v_p IN (
        SELECT pi.primaryPosition, pi.firstName, pi.lastName, gss.goals
        FROM
            Game_skater_stats gss
            JOIN Player_info pi ON gss.player_id = pi.player_id
        WHERE
            gss.game_id = p_game_id
        ORDER BY pi.primaryPosition
    ) LOOP  
        IF v_p.primaryPosition != v_prev_primaryPosition THEN
            IF v_prev_primaryPosition != ' ' THEN
                v_ret := v_ret || '
        </' || v_prev_primaryPosition || '>';
            END IF;

            v_ret := v_ret || '
        <' || v_p.primaryPosition || '>';
        END IF;

        v_ret := v_ret || '
            <player>
                <first_name>' || v_p.firstName || '</first_name>
                <last_name>' || v_p.lastName || '</last_name>
                <goals>' || v_p.goals || '</time_on_ice>
            </player>';
        v_prev_primaryPosition := v_p.primaryPosition;
    END LOOP;

    IF v_prev_primaryPosition != ' ' THEN
                v_ret := v_ret || '
        </' || v_prev_primaryPosition || '>';
    END IF;

    v_ret := v_ret || '
    </players>
</game>';
    RETURN v_ret;
END;
