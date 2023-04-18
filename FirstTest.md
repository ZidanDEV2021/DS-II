```sql 
create PROCEDURE TopTenGoalies (p_minGames IN INT)
AS
    CURSOR goalie_cur IS
        SELECT player_info.player_id, firstName, lastName, COUNT(*) AS games_played, AVG(savePercentage) AS avg_save_percentage
        FROM player_info JOIN game_goalie_stats ON player_info.player_id = game_goalie_stats.player_id
        WHERE primaryPosition = 'G'
        GROUP BY player_info.player_id, firstName, lastName
        HAVING COUNT(*) >= p_minGames
        ORDER BY AVG(savePercentage) DESC;

    v_rank NUMBER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('TOP 10 GOALIES:');
    FOR goalie_rec IN goalie_cur LOOP
        EXIT WHEN v_rank > 10;
        DBMS_OUTPUT.PUT_LINE(v_rank || '. ' || goalie_rec.firstName || ' ' || goalie_rec.lastName ||
            ' - ' || TO_CHAR(goalie_rec.avg_save_percentage, '999.99') || '% (' || goalie_rec.games_played || ' games played)');
        v_rank := v_rank + 1;
    END LOOP;
END;
```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
create PROCEDURE assign_referee(
    p_game_id IN NUMBER,
    p_referee_name IN VARCHAR2,
    p_referee_type IN VARCHAR2
)
IS
    l_referee_type VARCHAR2(20);
    l_referee_games NUMBER;
    l_game_exists NUMBER;
BEGIN
    -- Start transaction
    BEGIN
        -- Check if game exists
        SELECT COUNT(*) INTO l_game_exists FROM game WHERE game_id = p_game_id;
        IF l_game_exists = 0 THEN
            DBMS_OUTPUT.PUT_LINE('The game does not exist');
            ROLLBACK;
            RETURN;
        END IF;

        -- Check if referee type is valid
        IF p_referee_type NOT IN ('referee', 'linesman') THEN
            DBMS_OUTPUT.PUT_LINE('Non-existing referee type');
            ROLLBACK;
            RETURN;
        ELSE
            l_referee_type := p_referee_type;
        END IF;

        -- Check if referee is too busy
        SELECT COUNT(*) INTO l_referee_games FROM game_officials
        WHERE official_name = p_referee_name AND official_type = l_referee_type
        AND game_id IN (
            SELECT game_id FROM game WHERE season = (
                SELECT season FROM game WHERE game_id = p_game_id
            )
        );

        IF l_referee_games >= 100 THEN
            DBMS_OUTPUT.PUT_LINE('Referee too busy');
            ROLLBACK;
            RETURN;
        END IF;

        -- Assign referee to game
        INSERT INTO game_officials(game_id, official_name, official_type)
        VALUES(p_game_id, p_referee_name, l_referee_type);

        COMMIT; -- End transaction
        DBMS_OUTPUT.PUT_LINE('Referee assigned successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred. Transaction rolled back.');
            ROLLBACK;
    END;
END;
/

```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
create PROCEDURE assign_official_to_game
  (p_game_id IN game.game_id%TYPE, p_official_name IN game_officials.official_name%TYPE, p_official_type IN game_officials.official_type%TYPE)
AS
  v_season game.season%TYPE;
  v_count game_officials.official_name%TYPE;
BEGIN
  -- Kontrola, zda hra s daným id existuje
  SELECT season INTO v_season
  FROM game
  WHERE game_id = p_game_id;

  IF v_season IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Hra neexistuje');
    RETURN;
  END IF;

  -- Kontrola, zda typ rozhodčího existuje
  IF p_official_type NOT IN ('referee', 'linesman') THEN
    DBMS_OUTPUT.PUT_LINE('Neexistující typ rozhodčího');
    RETURN;
  END IF;

  -- Kontrola, zda rozhodčí nezúčastnil více než 100 her v sezóně
  SELECT COUNT(*) INTO v_count
  FROM game_officials
  JOIN game ON game.game_id = game_officials.game_id
  WHERE game.season = v_season AND game_officials.official_name = p_official_name;

  IF v_count >= 100 THEN
    DBMS_OUTPUT.PUT_LINE('Rozhodčí příliš zaneprázdněn');
    RETURN;
  END IF;

  -- Vložení rozhodčího do hry
  INSERT INTO game_officials(game_id, official_name, official_type)
  VALUES (p_game_id, p_official_name, p_official_type);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Rozhodčí úspěšně přidán do hry');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Chyba: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
create FUNCTION F_EXPORT_GAME_STATS(p_game_id INT) RETURN CLOB AS
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
/

```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
create PROCEDURE P_CREATE_GAME(p_home_short_name VARCHAR, p_away_short_name VARCHAR, p_date_time DATE, p_venue VARCHAR) AS
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
            home_team_id = v_home_team_id AND
            away_team_id = v_away_team_id AND
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
```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
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

```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
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

```
---------------------------------------------------------------------------------------------------------------------------------------
```sql 
create procedure NationalStarLine(p_nationality char)
as
begin
  dbms_output.put_line('--- NationalStarLine: ' || p_nationality || ' --------------------------------------------------');
  dbms_output.put_line('player_id' || chr(9) || chr(9) || 'firstname' ||  chr(9) || chr(9) || 'lastname' || chr(9) || chr(9) || 'primaryPosition' || chr(9) || chr(9) || 'points');
  dbms_output.put_line('----------------------------------------------------------------------------');
  PrintBestPlayer(p_nationality, 'C', 1);
  PrintBestPlayer(p_nationality, 'LW', 1);
  PrintBestPlayer(p_nationality, 'RW', 1);
  PrintBestPlayer(p_nationality, 'D', 2);
  dbms_output.put_line('----------------------------------------------------------------------------');
end;
/
```

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------



