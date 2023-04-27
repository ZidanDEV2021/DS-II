--1A
Napište proceduru, která bude mít na vstupu id hry, jméno a typ rozhodčího. Procedura nejprve zkontroluje, zda hra s daným id existuje, a pokud neexistuje,
 vypíše "Hra neexistuje" a procedura se ukončí. Poté zkontroluje, zda typ rozhodčího je "referee" nebo "linesman". Pokud ani jedno, procedura vypíše 
"Neexistující typ rozhodčího" a procedura se ukončí. Procedura následně zkontroluje, zda se daný rozhodčí v dané sezóně účastnil více než 100 her. 
Pokud ne, přiřadí daného rozhodčího k dané hře. 
V opačném případě procedura vypíše "Rozhodčí příliš zaneprázdněn" a procedura se ukončí. Procedura bude řešena jako transakce.

CREATE OR REPLACE Procedure GameExists(p_game_id INT, p_referee_name VARCHAR2, p_referee_type VARCHAR2)
AS
    game_played INT;
    referee_games INT;
BEGIN
    SELECT COUNT(*) INTO game_played /* kontroluju jestli hra existuje nebo ne*/
    FROM Game_officials
    WHERE game_id = p_game_id;
    
    IF game_played = 0 THEN
        dbms_output.put_line('Hra neexistuje');
    END IF;
    
    IF p_referee_type <> 'linesman' OR p_referee_type <> 'referee' THEN /*<> not equal to*/
        dbms_output.put_line('Neexistujici typ rozhodciho');
    END IF;
        
    SELECT COUNT(*) INTO referee_games
    FROM Game_officials
    JOIN Game ON game_officials.game_id = Game.game_id
    WHERE Game_officials.official_name = p_referee_name AND game.season = (SELECT Season FROM
Game WHERE game_id = p_game_id);

    IF referee_games > 100 THEN
        dbms_output.put_line('Rozhodci je zaneprazdnen');
    ELSE
        dbms_output.put_line('Rozhodci je volny');
        INSERT INTO Game_Officials (game_id, official_name, official_type)
        VALUES (p_game_id, p_referee_name, p_referee_type);
    END IF;
        
    COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        PPrint('Rollback');
/* EXTRACT(YEAR FROM date_time_GMT) -- vezme rok */
/* SYSDATE returnuje momentalni cas */

END;

--2A

Přidejte do tabulky "team info" atribut "aggressivity" typu int s možnými hodnotami (0, 1, 2). 
Vytvořte funkci, která pro každý tým spočítá, kolik útoků na jiné hráče mají na svědomí 
(útokem se rozumí "game plays.event = 'Penalty'" a současně "game plays players.playertype = 'DrewBy'"). 
Pokud je počet penalt menší než 750, nastaví atribut danému týmu na 0. Je-li v rozmezí 750-1250, nastaví atribut na 1. Je-li větší než 1250, 
nastaví atribut na 2. Nezapomeňte, že tým může být hostující nebo domácí (je nutné tedy spočítat penalty pro "team id for" a také "team id against"). 
Funkce bude řešena jako transakce a bude vracet počet zpracovaných týmů.

ALTER TABLE team_info ADD aggressivity INT check (aggressivity between 0 and 2);

CREATE OR REPLACE FUNCTION FSetAgresivity
RETURN INTEGER
AS
   CURSOR cTeams IS SELECT * FROM Team_Info;
   vReturnCount INTEGER;
   vAttackCount INTEGER;
BEGIN
     FOR lTeam IN cTeams
     LOOP
       SELECT COUNT(event) INTO vAttackCount FROM Game_plays gp
       JOIN  Game_plays_players gpp ON gpp.play_id = gp.play_id
       WHERE (team_id_for = lTeam.team_id OR team_id_against = lTeam.team_id) AND gp.event = 'Penalty' AND gpp.playertype = 'DrewBy';

       IF vAttackCount < 750 THEN
         UPDATE Team_Info
         SET aggressivity = 0
         WHERE team_id = lTeam.team_id; --hodi se kdyz potrebuju delat neco individualne s radkem loop+cursor
       END IF;

       IF  vAttackCount > 750 AND vAttackCount < 1250 THEN
         UPDATE Team_Info
         SET aggressivity = 1
         WHERE team_id = lTeam.team_id;
       END IF;

       IF  vAttackCount >1250 THEN
         UPDATE Team_Info
         SET aggressivity = 2
         WHERE team_id = lTeam.team_id;
       END IF;

       vReturnCount := vReturnCount + 1; -- musim iterovat
     END LOOP;

     COMMIT;
     RETURN vReturnCount;
EXCEPTION
     WHEN OTHERS THEN
       ROLLBACK;
       RETURN -1;
END;

--3A

Vytvořte tabulku "officials" s atributy "official id", "official name" a "location" (stejného datového typu jako atribut "venue" v tabulce "game").
Následně vytvořte bezparametrickou funkci, která zkopíruje každého rozhodčího z tabulky "game officials" do tabulky "officials" a nastaví jeho "location"
podle toho, kde nejčastěji působil jako rozhodčí. Pokud existuje více takových míst, vyberte některé z nich. Všimněte si, že
jednotliví rozhodčí se mohou v tabulce "game officials" nacházet více než jednou. Funkce bude vracet počet zpracovaných rozhodčích a bude řešena jako transakce.

CREATE OR REPLACE FUNCTION CopyOfficials
RETURN INTEGER
AS
    counter_id integer;
    ref_type varchar(30);
    isLinesman integer;
    isRef integer;
	v_location game.venue%type;
BEGIN
    counter_id := 0;
    DELETE FROM officials;
    FOR ref in (select distinct official_name from game_officials) LOOP
        
		select venue into v_location from (
			select venue from GAME g
			join game_officials  gof on g.game_id = gof.game_id
			where official_name = ref.official_name
			group by venue
			order by count(gof.game_id))
		where rownum = 1;   
		
        counter_id := counter_id + 1;
        INSERT INTO officials(official_id, official_name, location) values (counter_id, ref.official_name, v_location);
    END LOOP;
    COMMIT;
    
    RETURN counter_id;
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Nastala chyba');

END;

--4A

Vytvořte trigger "TAddGameEvent", který bude spuštěn po přidání záznamu do tabulky "Game plays". 
Trigger zkontroluje, o jaký typ události se jedná. Pokud se jedná o gól (event = 'Goal'), 
přičte tento gól do atributu "home goals/away goals" (podle toho, který tým dal gól) a také přičte tento gól danému týmu do tabulky "game teams stats" 
(atribut "goals"). Pokud se jedná pouze o střelu (event = 'Shot'), přičte tuto střelu danému týmu do tabulky "game teams stats" (atribut "shots").

CREATE OR REPLACE TRIGGER TAddGameEvent
AFTER INSERT ON Game_plays
FOR EACH ROW
DECLARE
    teamIdAway integer;
    teamIdHome integer;
BEGIN
  IF :NEW.event = 'Goal' THEN
        select away_team_id into teamIdAway from game where :NEW.game_id = game_id;
        select home_team_id into teamIdHome from game where :NEW.game_id = game_id;
        
        IF (:OLD.team_id_for = teamIdAway) THEN
                UPDATE Game SET away_goals = away_goals + 1 where :NEW.game_id = game_id;
                UPDATE Game_teams_stats SET goals = goals + 1 WHERE team_id = teamIdHome AND game_id = :NEW.game_id;
            ELSE 
                UPDATE Game SET home_goals = home_goals + 1 where :NEW.game_id = game_id;
                UPDATE Game_teams_stats SET goals = goals + 1 WHERE team_id = teamIdHome AND game_id = :NEW.game_id;
            END IF;  
    ELSIF :NEW.event = 'Shot' THEN
            select away_team_id into teamIdAway from game where :NEW.game_id = game_id;
            select home_team_id into teamIdHome from game where :NEW.game_id = game_id;

            IF (:NEW.team_id_for = teamIdAway) THEN
                UPDATE Game_teams_stats SET shots = shots + 1 WHERE team_id = teamIdAway AND game_id = :NEW.game_id;
            ELSE 
                UPDATE Game_teams_stats SET shots = shots + 1 WHERE team_id = teamIdHome AND game_id = :NEW.game_id;
            END IF;  
    END IF;
END;


--5a
Vytvořte trigger "T Update Skater Stats", který po aktualizaci záznamu v tabulce "Game Skater Stats" zkontroluje, zda došlo ke změně statistiky "goals". 
Pokud ano, pak dojde k přepočtu celkového počtu gólů domácího nebo hostujícího týmu v tabulce "Game". 
Zda půjde o domácí nebo hostující tým, bude určeno týmem, za který tým hráč v daném zápase hraje ("Game Skater Stats.team id"). 
Při přepočtu vycházejte z rozdílu nového a původního údaje o počtu vstřelených gólů. 
Změnu týmu (tj. aktualizaci atributu "Game Skater Stats.team id") ignorujte.

CREATE OR REPLACE TRIGGER T_UPDATE_SKATER_STATS AFTER UPDATE ON GAME_SKATER_STATS FOR EACH ROW 
DECLARE
    v_home_team_id INT;
    v_away_team_id INT;
BEGIN
    IF :new.goals != :old.goals THEN
        SELECT home_team_id, away_team_id INTO v_home_team_id, v_away_team_id
        FROM Game
        WHERE game_id = :new.game_id;
        
        IF :new.team_id = v_home_team_id THEN
            UPDATE Game
            SET home_goals = home_goals + :new.goals - :old.goals
            WHERE game_id = :new.game_id;
        ELSIF :new.team_id = v_away_team_id THEN
            UPDATE Game
            SET away_goals = away_goals + :new.goals - :old.goals
            WHERE game_id = :new.game_id;
        END IF;
    END IF;
END;


--6A
Vytvořte funkci "F Export Game Stats" s parametrem "p game id". Funkce bude vracet textový řetězec obsahující XML se statistikami daného zápasu. 
Statistiky budou zahrnovat ID a zkratku (abbreviation) obou týmů a seznam všech hráčů s nejdelším časem na ledě (timeOnIce). 
U každého hráče uvidíme jeho jméno, příjmení a čas na ledě.

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


--7A

Vytvořte trigger "T Update Game", který před aktualizací zápasu v tabulce "Game" zkontroluje, zda došlo ke změně počtu vstřelených gólů domácího nebo 
hostujícího týmu (aktualizovány mohou být i obě hodnoty současně). Pokud ano, pak bude příslušnému týmu aktualizována statistika o počtu vstřelených gólů 
v tabulce "Game Team Stats". Zároveň bude v záznamu hry aktualizován výsledek ("Game.outcome") na jednu z hodnot: 'away win' (vítězství hostujícího týmu), 
'home win' (vítězství domácího týmu), nebo 'draw' (remíza).


CREATE OR REPLACE TRIGGER T_UPDATE_GAME BEFORE UPDATE ON Game FOR EACH ROW
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

--8A

Vytvořte funkci "F Export Game Stats" s parametrem "p game id". Funkce bude vracet textový řetězec obsahující XML se seznamem hráčů v daném zápase. 
Hráči budou seskupeni dle jejich primární pozice (Player Info.primary position). U každého hráče bude uvedeno jeho jméno, příjmení a počet vstřelených gólů.

<game id="2000020075">
<players>
<C>
<player>
<first_name>Steve</first_name>
<last_name>Kelly</last_name>
<goals>0</goals>
</player>
<player>
<first_name>Jarrod</first_name>
<last_name>Skalde</last_name>
<goals>0</goals>
</player>
</C>
<D>
<player>
<first_name>Frantisek</first_name>
<last_name>Kaberle</last_name>
<goals>0</goals>
</player>
<player>
<first_name>Chris</first_name>
<last_name>Tamer</last_name>
<goals>0</goals>
</player>
</D>
</players>
</game>

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
