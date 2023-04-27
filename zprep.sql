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

create or replace TRIGGER T_UPDATE_GAME BEFORE UPDATE ON Game FOR EACH ROW
BEGIN
    IF :new.away_goals != :old.away_goals THEN
        UPDATE Game_teams_stats
        SET goals = :new.away_goals
        WHERE game_id = :new.game_id AND team_id = :new.away_team_id;
    END IF;

    IF :new.home_goals != :old.home_goals THEN
        UPDATE Game_teams_stats
        SET goals = :new.home_goals
        WHERE game_id = :new.game_id AND team_id = :new.home_team_id;
    END IF;

    IF :new.away_goals != :old.away_goals OR :new.home_goals != :old.home_goals THEN
        IF :new.away_goals > :new.home_goals THEN
            :new.outcome := 'away win';
        ELSIF :new.away_goals < :new.home_goals THEN
            :new.outcome := 'home win';
        ELSE
            :new.outcome := 'draw';
        END IF;
    END IF;
END;

