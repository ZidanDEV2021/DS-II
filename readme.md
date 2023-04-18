Funkce

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
