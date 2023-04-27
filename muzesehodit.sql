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
