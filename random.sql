create PROCEDURE SET_GOALIE_STATS(p_game_id INT, p_player_id INT, p_home_or_away CHAR, p_shots INT, p_saves INT) AS
    v_cnt INT;
    v_team_id INT;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM DUAL
    WHERE EXISTS (
        SELECT *
        FROM Game_goalie_stats
        WHERE game_id = p_game_id AND player_id = p_player_id
    );

    IF v_cnt > 0 THEN
        UPDATE Game_goalie_stats
        SET shots = p_shots, saves = p_saves
        WHERE game_id = p_game_id AND player_id = p_player_id;
    ELSE
        IF p_home_or_away = 'H' THEN
            SELECT home_team_id INTO v_team_id
            FROM Game
            WHERE game_id = p_game_id;
        ELSE 
            SELECT away_team_id INTO v_team_id
            FROM Game
            WHERE game_id = p_game_id;
        END IF;

        INSERT INTO Game_goalie_stats(game_id, player_id, team_id, shots, saves)
        VALUES (p_game_id, p_player_id, v_team_id, p_shots, p_saves);
    END IF;
END;

create procedure TopTenGoalies(p_minGames int)
as
  v_rank int := 1;
begin
  dbms_output.put_line('---- Top 10 goalies with the number of games >= ' || p_minGames || ' --------------------------');
  dbms_output.put_line('#rank' || chr(9) || 'player_id' || chr(9) || 'firstname' || chr(9) || 'lastname' || chr(9) || 'nationality' || chr(9) || 'savepercentage' || chr(9) || 'games');
  dbms_output.put_line('-------------------------------------------------------------------------------');

  for rec in (
    select * from (
      select ggs.player_id, player_info.firstname, player_info.lastname, player_info.nationality, avg(savepercentage) as avgsave, count(*) as games
      from game_goalie_stats ggs
      inner join player_info on ggs.player_id=player_info.player_id
      where player_info.primaryPosition='G'
      group by ggs.player_id, player_info.firstname, player_info.lastname, player_info.nationality
      having count(*) >= p_minGames
      order by avg(savepercentage) desc
    ) where rownum <= 10)
  loop
    dbms_output.put_line(v_rank || chr(9) || chr(9) || rec.player_id || chr(9) || chr(9) || rec.firstname || chr(9) || chr(9) || rec.lastname || chr(9) || chr(9) ||
      rec.nationality || chr(9) || chr(9) || round(rec.avgsave, 2) || chr(9) || chr(9) || rec.games);
    v_rank := v_rank + 1;
  end loop;
  dbms_output.put_line('-------------------------------------------------------------------------------');
end;
/

create PROCEDURE P_UPDATE_SKATER_GOALS(p_game_id INT, p_player_id INT, p_goals INT) AS
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
/

create procedure PrintBestPlayer(p_nationality char, p_primaryPosition char, p_rowCount int)
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
/

