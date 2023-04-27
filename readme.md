![image](https://user-images.githubusercontent.com/53978671/234581981-1e3b0f90-447b-4a64-a87f-056f6c9dc6bd.png)

Funkce
```rs
create table officials(official_id int primary key, official_name varchar(50), official_type varchar(50));

create or replace function copy_ff
return integer
as
        v_count1 integer;
        v_count2 integer;
        v_counter integer;
    begin
        v_counter:=0;
        DELETE FROM officials;
        for offi in (select distinct official_name from game_officials)
        loop
            select count(*) into v_count1 from GAME_OFFICIALS where OFFICIAL_NAME=offi.OFFICIAL_NAME and OFFICIAL_TYPE='Linesman';
            select count(*) into v_count2 from GAME_OFFICIALS where OFFICIAL_NAME=offi.OFFICIAL_NAME and OFFICIAL_TYPE='Referee';
            v_counter:= v_counter+1;
            if v_count1 = v_count2 then
                insert into officials(official_id, official_name, official_type) values(v_counter,offi.OFFICIAL_NAME,'Undefined');
            elsif v_count1 < v_count2 then
                insert into officials(official_id, official_name, official_type) values(v_counter,offi.OFFICIAL_NAME,'Referee');
            elsif v_count1 > v_count2 then
                insert into officials(official_id, official_name, official_type) values(v_counter,offi.OFFICIAL_NAME,'Linesman');
            end if;
        end loop;
        commit;
        return v_counter;
    exception
        when others then
            RAISE_APPLICATION_ERROR(-20001, 'Nastala chyba');
        rollback;
        return 0;
    end;
/

DECLARE
  v_result INTEGER;
BEGIN
  v_result := copy_ff();
  DBMS_OUTPUT.PUT_LINE('Number of rows processed: ' || v_result);
END;

SELECT * FROM OFFICIALS;
```
Syntax:
```sql
CREATE OR REPLACE FUNCTION funkce_název(parametry) RETURN návratový_typ IS
    deklarace proměnných;
BEGIN
    kód funkce;
    RETURN hodnota;
END;
```
Příklad funkce, která vrátí součet dvou čísel:
```sql
CREATE OR REPLACE FUNCTION secti(a NUMBER, b NUMBER) RETURN NUMBER IS
    vysledek NUMBER;
BEGIN
    vysledek := a + b;
    RETURN vysledek;
END;
```
Triggery

Syntax pro spouštění triggeru před nebo po vkládání, aktualizování nebo mazání záznamu:
```sql
CREATE OR REPLACE TRIGGER trigger_název
{BEFORE | AFTER} {INSERT | UPDATE | DELETE} ON tabulka_název
{FOR EACH ROW} 
DECLARE
    deklarace proměnných;
BEGIN
    kód triggeru;
END;
```
Příklad triggeru, který upraví sloupec v tabulce při vkládání nového záznamu:
```sql
CREATE OR REPLACE TRIGGER novy_zaznam
BEFORE INSERT ON zaznamy
FOR EACH ROW
BEGIN
    :NEW.datum := SYSDATE;
END;
```
Transakce

Syntax pro zahájení a ukončení transakce:
```sql
BEGIN
    -- kód pro transakci
    COMMIT; -- ukončení transakce
    -- nebo
    ROLLBACK; -- vrácení změn v transakci
END;
```
Příklad transakce, která vloží nový záznam a provede aktualizaci související tabulky:
```sql
BEGIN
    INSERT INTO zaznamy (id, popis) VALUES (1, 'nový záznam');
    UPDATE souvisejici_tabulka SET posledni_zaznam = 1;
    COMMIT;
END;
```
Procedury

Syntax:
```sql
CREATE OR REPLACE PROCEDURE procedura_název(parametry) IS
    deklarace proměnných;
BEGIN
    kód procedury;
END;
```
Příklad procedury, která vypíše seznam všech záznamů v tabulce:
```sql
CREATE OR REPLACE PROCEDURE vypis_zaznamy IS
BEGIN
    FOR zaznam IN (SELECT * FROM zaznamy) LOOP
        DBMS_OUTPUT.PUT_LINE(zaznam.id || ': ' || zaznam.popis);
    END LOOP;
END;
```
