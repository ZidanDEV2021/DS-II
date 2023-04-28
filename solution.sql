create or replace function GetStats(year_from integer, year_to integer, stats_type varchar)
return integer
as
    v_result integer;
    begin
        if year_from>year_to then
            return -1;
        else
            if stats_type ='games' then
                select count(*) into v_result from game
                where extract(year from date_time_gmt) between year_from and year_to;
            elsif stats_type ='goals' then
                select count(*) into v_result from GAME
                join GAME_PLAYS GP on GAME.GAME_ID = GP.GAME_ID
                where gp.EVENT='Goal' and extract(year from date_time_gmt) between year_from and year_to;
            elsif stats_type ='skaters' then
                select count(distinct pss.player_id) into v_result from GAME_SKATER_STATS pss
                join game g on pss.game_id = g.game_id
                where extract(year from date_time_gmt) between year_from and year_to;
            elsif stats_type ='goalies' then
                select count(distinct pss.player_id) into v_result from GAME_GOALIE_STATS pss
                join game g on pss.game_id = g.game_id
                where extract(year from date_time_gmt) between year_from and year_to;
            else
                return -1;
            end if;
        end if;

        return v_result;
    end;
    /
/*
select count(*) into v_result from game
where extract(year from date_time_gmt) between year_from and year_to;
*/
select count(*) from GAME
    join GAME_PLAYS GP on GAME.GAME_ID = GP.GAME_ID where gp.EVENT='Goal' and extract(year from date_time_gmt) between 2005 and 2006;


select count(distinct pss.player_id)  from GAME_SKATER_STATS pss
        join game g on pss.game_id = g.game_id
        where extract(year from date_time_gmt) between 2001 and 2004;
/
create or replace procedure PrintStats(year_from integer, year_to integer)
as
    v_games integer;
        v_goals integer;
        v_skaters integer;
        v_goalies integer;
    begin
        v_games := GetStats(year_from,year_to,'games');
        v_goals := GetStats(year_from,year_to,'goals');
        v_skaters := GetStats(year_from,year_to,'skaters');
        v_goalies := GetStats(year_from,year_to,'goalies');
        P_PRINT('Obdobi:'||year_from||'-'||year_to);
        P_PRINT('Pocet odehranych zapasu: '||v_games);
        P_PRINT('Pocet vstrelenych golu: '||v_goals);
        P_PRINT('Pocet hracu: '||v_skaters);
        P_PRINT('Pocet brankaru: '||v_goalies);
    end;
/
call PRINTSTATS(2001,2004);
call PRINTSTATS(2004,2010);

DECLARE
  v_result INTEGER;
BEGIN
  v_result := GetStats(2001,2004,'games');
  DBMS_OUTPUT.PUT_LINE('Result:'||v_result);
END;
DECLARE
  v_result INTEGER;
BEGIN
  v_result := GetStats(2001,2004,'goals');
  DBMS_OUTPUT.PUT_LINE('Result:'||v_result);
END;
DECLARE
  v_result INTEGER;
BEGIN
  v_result := GetStats(2001,2004,'skaters');
  DBMS_OUTPUT.PUT_LINE('Result:'||v_result);
END;
DECLARE
  v_result INTEGER;
BEGIN
  v_result := GetStats(2001,2004,'goalies');
  DBMS_OUTPUT.PUT_LINE('Result:'||v_result);
END;
