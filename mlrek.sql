Funkce

-- Vytvoření funkce GetStats pro získání statistik z databáze
-- Parametry: year_from, year_to, stats_type
-- Výstup: Celková hodnota zvolené statistiky pro zadané období

CREATE OR REPLACE FUNCTION GetStats(year_from INT, year_to INT, stats_type VARCHAR2)
RETURN INT
IS
    result INT;
BEGIN
-- Kontrola zda jsou zadané roky validní

    IF year_from > year_to THEN
        RETURN -1;
    END IF;

-- Získání statistiky podle zvoleného typu
    IF stats_type = 'games' THEN
        SELECT COUNT(*) INTO result
        FROM game
        WHERE EXTRACT(YEAR FROM date_time_GMT) BETWEEN year_from AND year_to;
    ELSIF stats_type = 'goals' THEN
        SELECT SUM(home_goals + away_goals) INTO result
        FROM game
        WHERE EXTRACT(YEAR FROM date_time_GMT) BETWEEN year_from AND year_to;
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
    -- Pokud je zvolený typ neznámý, vrátíme -1
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


