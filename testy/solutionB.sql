--1B

Napište proceduru, která bude mít na vstupu ID hry, jméno a typ rozhodčího. Procedura nejprve zkontroluje, zda hra s daným ID existuje a pokud 
neexistuje, vypíše "Hra neexistuje" a procedura se ukončí. Poté zkontroluje, zda typ rozhodčího je referee nebo linesman. Pokud neplatí ani jedno, 
procedura vypíše "Neexistující typ rozhodčího" a procedura se ukončí. Procedura následně zkontroluje, zda k dané hře už nejsou přiřazeni čtyři rozhodčí. 
Pokud ne, procedura přiřadí rozhodčího na danou hru. V opačném případě procedura vypíše 
"Maximální počet rozhodčích na hru" a procedura se ukončí. Procedura bude řešena jako transakce.


CREATE OR REPLACE PROCEDURE AddReferee(p_gid integer,p_of_name game_officials.official_name%type,p_of_type game_officials.official_type%type) 
AS
  v_ex EXCEPTION;
  v_game_count integer;
  v_officials_count integer;
BEGIN
  select count(*) INTO v_game_count from game where game.game_id = p_gid;
  IF (v_game_count=0) THEN
       dbms_output.put_line('Hra neexistuje');
       RAISE v_ex;
  END IF;
  IF (p_of_type NOT IN ('Referee','Linesman')) THEN
        dbms_output.put_line('Neexistujici typ rozhodciho');
       RAISE v_ex;
  END IF;
  
  SELECT COUNT(*) INTO v_officials_count FROM game_officials WHERE game_officials.game_id= p_gid;

  IF (v_officials_count>3) THEN
    dbms_output.put_line('Maximalni pocet rozhodcich na hru');
    RAISE v_ex;
  ELSE
    INSERT INTO game_officials(game_id,official_name,official_type)
    VALUES(p_gid,p_of_name,p_of_type);
  END IF;
  COMMIT;
EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
END;

--2B


Přidejte do tabulky "team_info" atribut "vulnerability" typu int s možnými hodnotami (0, 1, 2). Vytvořte funkci, která pro každý tým spočítá, 
kolik útoků na jejich hráče bylo spácháno (útokem se rozumí game_plays.event = 'Penalty' a současně game_plays.players.playertype = 'PenaltyOn'). 
Pokud je počet penalt menší než 750, nastaví atribut danému týmu na 0. Je-li v rozmezí 750-1250, nastaví atribut na 1. Je-li větší než 1250, nastaví atribut 
na 2. Nezapomeňte, že tým může být hostující nebo domácí (je tedy nutné spočítat penalty pro team_id_for a také team_id_against). 
Funkce bude řešena jako transakce a bude vracet počet zpracovaných týmů.

ALTER TABLE team_info
ADD  vulnerability integer check (vulnerability between 0 and 2);


CREATE OR REPLACE FUNCTION Fcount_vulnerability RETURN INT AS
v_team team_info%rowtype;
v_count INTEGER;
v_penalty_count INTEGER;
v_penalty_count_tmp INTEGER;
BEGIN
  v_count := 0;
  
  FOR v_team IN (SELECT * FROM team_info) LOOP
    v_count:=v_count+1;
  
    SELECT COUNT(*) INTO v_penalty_count from game_plays
    JOIN game_plays_players on game_plays_players.play_id=game_plays.play_id
    where game_plays.event='Penalty' AND TEAM_ID_FOR =v_team.team_id
    AND  game_plays_players.playertype = 'PenaltyOn';


    SELECT COUNT(*) INTO v_penalty_count_tmp from game_plays
    JOIN game_plays_players on game_plays_players.play_id=game_plays.play_id
    where game_plays.event='Penalty' AND TEAM_ID_Against=v_team.team_id 
	AND game_plays_players.playertype = 'PenaltyOn';


    v_penalty_count := v_penalty_count + v_penalty_count_tmp;
    if (v_penalty_count < 750) THEN
       UPDATE team_info
       SET vulnerability = 0
       where team_info.team_id = v_team.team_id;
    ELSIF (v_penalty_count > 1250) THEN
       UPDATE team_info
       SET vulnerability = 2
       where team_info.team_id = v_team.team_id;
    ELSE
       UPDATE team_info
       SET vulnerability = 1
       where team_info.team_id = v_team.team_id;
    END IF;

END LOOP;

     COMMIT;
     RETURN v_count;
     dbms_output.put_line(v_count);
EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         dbms_output.put_line('ROLLACK');

END;

--3B

Vytvořte trigger "T_DeleteGameEvent", který bude spuštěn před smazáním záznamu z tabulky "Game_plays". Trigger ověří, o jaký typ události šlo. 
Pokud šlo o gól (event = 'Goal'), odečte tento gól z atributu "home goals/away goals" (podle toho, který tým dal mazaný gól) a také tento gól odečte 
danému týmu z tabulky "game_teams_stats" (atribut goals). Pokud šlo pouze o střelu (event = 'Shot'), 
odečte tuto střelu danému týmu z tabulky "game_teams_stats" (atribut shots).

CREATE TABLE officials
(
  official_id int NOT NULL,
  official_name varchar(30) NOT NULL,
  official_type varchar(30) NOT NULL,
    CONSTRAINT PK_officials PRIMARY KEY(official_id)
);

CREATE OR REPLACE FUNCTION CopyOfficials
RETURN INTEGER
AS
    counter_id integer;
    ref_type varchar(30);
    isLinesman integer;
    isRef integer;
BEGIN
    counter_id := 0;
    DELETE FROM officials;
    FOR ref in (select distinct official_name from game_officials) LOOP
        select count(*) into isLinesman from game_officials where official_name = ref.official_name AND official_type = 'Linesman';
        select count(*) into isRef from game_officials where official_name = ref.official_name AND official_type = 'Referee';
        
        IF isLinesman > isRef THEN
            ref_type := 'Linesman';
        ELSIF isLinesman < isRef THEN
            ref_type := 'Referee';
        ELSE 
            ref_type := 'undefiend';
        END IF;
        counter_id := counter_id + 1;
        INSERT INTO officials(official_id, official_name, official_type) values (counter_id, ref.official_name, ref_type);
    END LOOP;
    COMMIT;
    
    RETURN counter_id;
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Nastala chyba');

END;

--4B

Vytvořte tabulku "officials" s atributy "official_id", "official_name" a "official_type" 
(stejného datového typu jako atribut "official_type" v tabulce "game_officials"). Následně vytvořte bezparametrickou funkci, která každého rozhodčího z 
tabulky "game_officials" zkopíruje do tabulky "officials", přičemž atribut "official_type" mu nastaví podle toho, jakého rozhodčího dělal častěji.
 V případě, že rozhodčí byl stejně často v roli čárového rozhodčího (linesman) jako hlavního rozhodčího (referee), nastaví se "official_type" na hodnotu "undefined". 
Nezapomeňte, že jednotliví rozhodčí se v tabulce "game_officials" nacházejí více než jednou. 
Funkce bude vracet počet zpracovaných rozhodčích a bude řešena jako transakce.

CREATE OR REPLACE TRIGGER TDeleteGameEvent
BEFORE DELETE ON game_plays
FOR EACH ROW
DECLARE
    isAwayTeam boolean;
    teamIdAway integer;
    teamIdHome integer;
BEGIN
    IF :OLD.event = 'Goal' THEN
        select away_team_id into teamIdAway from game where :OLD.game_id = game_id;
        select home_team_id into teamIdHome from game where :OLD.game_id = game_id;
        
            IF (:OLD.team_id_for = teamIdAway) THEN
                UPDATE Game SET away_goals = away_goals - 1 where :OLD.game_id = game_id;
                UPDATE Game_teams_stats SET goals = goals - 1 WHERE team_id = teamIdHome AND game_id = :OLD.game_id;
            ELSE 
                UPDATE Game SET home_goals = home_goals - 1 where :OLD.game_id = game_id;
                UPDATE Game_teams_stats SET goals = goals - 1 WHERE team_id = teamIdHome AND game_id = :OLD.game_id;
            END IF;  
    ELSIF :OLD.event = 'Shot' THEN
            select away_team_id into teamIdAway from game where :OLD.game_id = game_id;
            select home_team_id into teamIdHome from game where :OLD.game_id = game_id;

            IF (:OLD.team_id_for = teamIdAway) THEN
                UPDATE Game_teams_stats SET shots = shots - 1 WHERE team_id = teamIdAway AND game_id = :OLD.game_id;
            ELSE 
                UPDATE Game_teams_stats SET shots = shots - 1 WHERE team_id = teamIdHome AND game_id = :OLD.game_id;
            END IF;  
    END IF;
END;


--5B
CREATE OR REPLACE TRIGGER T_UPDATE_TEAM_STATS AFTER UPDATE ON Game_teams_stats FOR EACH ROW
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

--json ktery je stejny jako u A

--7b

Vytvořte trigger "T_UpdateGame", který před aktualizací zápasu v tabulce "Game" zkontroluje, zda došlo ke změně počtu vstřelených gólů domácího nebo hostujícího
 týmu (aktualizovány mohou být i obě hodnoty současně). Pokud ano, pak bude příslušnému týmu aktualizována statistika o počtu vstřelených gólů v tabulce
 "Game_teams_stats". Zároveň bude v záznamu hry aktualizován výsledek ("Game.outcome") 
na jednu z hodnot: "away win" (vítězství hostujícího týmu), "home win" (vítězství domácího týmu) nebo "draw" (remíza).

CREATE OR REPLACE PROCEDURE P_SET_GOALIE_STATS(p_game_id INT, p_player_id INT, p_home_or_away CHAR, p_shots INT, p_saves INT) AS
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
