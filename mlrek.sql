Funkce


---Opravene!!!

CREATE OR REPLACE FUNCTION GetStats(year_from INT, year_to INT, stats_type VARCHAR2)
RETURN Number
IS
    result NUMBER;
BEGIN
    IF year_from > year_to THEN
        RETURN -1;
    END IF;

    IF stats_type = 'games' THEN
        SELECT COUNT(*) INTO result
        FROM game
        WHERE EXTRACT(YEAR FROM date_time_GMT) BETWEEN year_from AND year_to;
    ELSIF stats_type = 'goals' THEN
         select count(gp.play_id) into result
         from game g
         join game_plays gp on gp.game_id = g.game_id and gp.event = 'Goal'
         where extract(year from date_time_gmt) between year_from and year_to;
    ELSIF stats_type = 'skaters' THEN
        SELECT COUNT(DISTINCT player_id) INTO result
        FROM game_skater_stats gs
        JOIN game g ON gs.game_id = g.game_id
        WHERE EXTRACT(YEAR FROM g.date_time_GMT) BETWEEN year_from AND year_to;
    ELSIF stats_type = 'goalies' THEN
        SELECT COUNT(DISTINCT player_id) INTO result
        FROM game_goalie_stats gg
        JOIN game g ON gg.game_id = g.game_id
        WHERE EXTRACT(YEAR FROM g.date_time_GMT) BETWEEN year_from AND year_to;
    ELSE
        RETURN -1;
    END IF;

    RETURN result;
END GetStats;


Procedura
-- Vytvoření procedury PrintStats, která využije funkci GetStats a vypíše zadané statistiky
-- Parametry: year_from, year_to


CREATE OR REPLACE PROCEDURE PrintStats(year_from INT, year_to INT)
IS
    games_played INT;
    goals_scored INT;
    players INT;
    goalkeepers INT;
BEGIN
-- Získání statistik pomocí funkce GetStats
    games_played := GetStats(year_from, year_to, 'games');
    goals_scored := GetStats(year_from, year_to, 'goals');
    players := GetStats(year_from, year_to, 'skaters');
    goalkeepers := GetStats(year_from, year_to, 'goalies');

-- Výpis statistik
    DBMS_OUTPUT.PUT_LINE('Období: ' || year_from || ' - ' || year_to);
    DBMS_OUTPUT.PUT_LINE('Počet odehraných zápasů: ' || games_played);
    DBMS_OUTPUT.PUT_LINE('Počet vstřelených gólů: ' || goals_scored);
    DBMS_OUTPUT.PUT_LINE('NPočet hráčů: ' || players);
    DBMS_OUTPUT.PUT_LINE('Počet brankářů: ' || goalkeepers);
END PrintStats;


Zapnutí
-- Použití procedury PrintStats pro získání statistik mezi roky 2000 a 2005
-- Nejprve je třeba povolit DBMS_OUTPUT

SET SERVEROUTPUT ON;
BEGIN
    PrintStats(2000, 2005);
END;


