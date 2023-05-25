# PREZENTACE 5 - Statické a Dynamické SQL

### Příklady dynamického SQL, které nejde použít jako statické SQL [V pythonu]

Tyto dynamické SQL nejde použít jako statické, protože nemáme pevně zadané proměnné jako `table_name`, `column_name` nebo `column_type`.
```sql
def create_table(table_name):
    query = f"CREATE TABLE {table_name} (id INT PRIMARY KEY, name TEXT);"

def add_column(table_name, column_name, column_type):
    query = f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type};"
```
# Příklad statického SQL s pevně danými proměnnými:
```sql
 SELECT * FROM Employees WHERE EmployeeID = 1;
```

# PREZENTACE 6

## Vlastnosti ACID [A - atomičnost, C - correctness, I - Isolation, D - Durability]
# (Více informací v PREZENTACI 10)

## Odložená aktualizace NO-UNDO / REDO
 - Provádí se až po potvrzení transakce, změny se nejprve uloží do log souboru a následně do databáze.
 - Do log souboru se ukládají nové hodnoty kvůli REDO.
 - Pokud transakce selže, neprovádí se žádné změny, protože změny se zapisují až po potvrzení transakce.
 - Může nastat situace, kdy se aktualizace zapíše do log souboru, ale ne do databáze. V takovém případě se použije REDO.
 - Tato metoda se využívá spíše pro menší transakce.

## Okamžitá aktualizace UNDO / NO-REDO
 - Provádí se po každé aktualizaci transakce. Nejprve se změna zapíše do log souboru a poté do databáze.
 - Do log souboru se ukládají původní hodnoty, aby bylo možné provést UNDO v případě chyby.
 - Pokud transakce selže před potvrzením, provede se UNDO (vrácení změn, které byly zapsány na disk).
 - Při této metodě dochází k většímu počtu změn a nedochází k čtení z vyrovnávací paměti.

## Kombinovaná aktualizace UNDO / REDO
 - Tato metoda se běžně využívá v praxi.
 - Aktualizace jsou zapisovány do log souboru až po COMMIT, jako u odložené aktualizace.
 - Aktualizace databáze však probíhá v různých časových intervalech (tzv. checkpointy).


# PREZENTACE 8

## Problém špinavého čtení (Dirty read)
 - U konfliktu Write-Read to znamená, že transakce A aktualizuje záznam a transakce B chce tento záznam číst, i když transakce A nebyla potvrzena (může nastat problém nepotvrzené závislosti).
 - Pokud transakce B přečte záznam, jde o špinavé čtení.
 - Tento problém lze vyřešit pomocí zamykání.

## Problém špinavého zápisu (Dirty write)
 - Nastává při konfliktu Write-Write, kdy transakce A zapíše záznam T a poté transakce B, ještě před potvrzením transakce A, chce zapsat tentýž záznam T.
 - Může nastat problém ztráty aktualizace pro transakci A a problém nepotvrzené závislosti pro transakci B.
 - Pokud transakce B zapíše T, jde o špinavý zápis.

## Problém nekonzistentní analýzy
 - Tento problém nastává, když transakce opakovaně čte stejný řádek, ale každým čtením získává jiná data.
 - Nastává v systémech, kde pracuje několik transakcí se stejnými daty ve stejný čas.
 - Například transakce T1 přečte řádek R1, poté transakce T2 tento řádek aktualizuje. Když transakce T1 znovu přečte řádek R1, dostane odlišnou hodnotu.

## Problém ztráty aktualizace
 - Tento problém nastává, když se v databázi objeví dvě nebo více transakcí, které pracují se stejným řádkem a aktualizují jej.
 - Žádná z transakcí neví o změnách provedených jinou transakcí, což znamená, že hodnota řádku může být založena na libovolné hodnotě z poslední aktualizace transakce.
 - Tento problém lze vyřešit pomocí zamykání.

## Problém nepotvrzené závislosti
 - Nastává, když jedna transakce čte nebo aktualizuje záznam, který byl aktualizován dosud nepotvrzenou (nedokončenou) transakcí.
 - Existuje možnost, že transakce nebudou potvrzeny a dojde k operaci ROLLBACK. V takovém případě první transakce pracuje s neplatnými hodnotami.
 - Tento problém lze vyřešit pomocí zamykání.

## !!! UZAMYKÁNÍ !!!
- Uzamykání je jedna z několika technik řízení souběhu, která se často používá.
- Princip spočívá v tom, že transakce A musí požádat o zámek na záznam/objekt, který chce číst nebo zapisovat.
- Zámek není možné získat jinou transakcí, dokud jej transakce A neuvolní.

# Rozdělují se na:
- Výlučné zámky (X), které slouží pro zápis.
- Sdílené zámky (S), které slouží pro čtení.

# Při uzamykání mohou nastat dva případy:
- Pokud transakce A drží výlučný zámek (X) na záznamu T, pak žádný požadavek transakce B na zámek (libovolného typu) na záznam T nebude proveden.
- Pokud transakce A drží sdílený zámek (S) na záznamu T, pak požadavek transakce B na výlučný zámek (X) na záznam T nebude proveden, ale požadavek na sdílený zámek (S) na záznam T bude proveden.
- Pokud transakce B získá sdílený zámek (S), obě transakce A i B drží sdílený zámek (S).

## ZAMYKACÍ PROTOKOL

- Transakce, která chce získat záznam z databáze, musí požádat o sdílený zámek (S) na tento záznam.
- Transakce, která chce aktualizovat záznam, musí požadovat výlučný zámek (X) na tento záznam.
- Pokud transakce B nemůže získat požadovaný zámek, přejde do stavu čekání (čeká, až transakce A uvolní zámek).
- Transakce B nesmí čekat v čekacím stavu donekonečna (to by znamenalo uváznutí nebo hladovění).
- Výlučné zámky (X) jsou automaticky uvolněny na konci transakce (COMMIT/ROLLBACK).

## ŘEŠENÍ ZTRÁTY AKTUALIZACE POMOCÍ ZÁMKŮ
- Pro operaci čtení (READ) získávají transakce A i B sdílený zámek (S).
- Pro operaci zápisu (WRITE) transakce A je blokována, protože jí byl odmítnut zámek, a transakce A nyní čeká.
- Pro operaci zápisu (WRITE) transakce B je také blokována a čeká.
- Tímto se problém ztráty aktualizace vyřeší, ale může vzniknout problém uváznutí (deadlock), kdy jsme uvězněni.

## ŘEŠENÍ PROBLÉMU NEPOTVRZENÉ ZÁVISLOSTI
- Prvním krokem WRITE operace transakce B je získání výlučného zámku (X) na záznamu T.
- Následně, když transakce A požaduje čtení (READ) záznamu T, požaduje sdílený zámek (S) na T, ale je převedena do stavu čekání kvůli nepotvrzené závislosti na transakci B.
- Po provedení WRITE operace dojde k ROLLBACK nebo COMMIT a výlučný zámek (X) se uvolní.
- Nyní může transakce A opět požadovat čtení (READ) a získat sdílený zámek (S) pro záznam T.

## ŘEŠENÍ PROBLÉMU NEKONZISTENTNÍ ANALÝZY

Viz popis v prezentaci 8, strana 38.

## ŘEŠENÍ UVÁZNUTÍ
- Uváznutí nastane, když dvě nebo více transakcí čekají na uvolnění zámků, které jsou drženy jinou transakcí.
- Problém uváznutí lze řešit pomocí nastavení časových limitů.
- Pokud trvání transakce překročí stanovený časový limit, víme, že se jedná o uváznutí.
- Problém uváznutí lze také řešit detekcí cyklu v grafu.
- Tímto se zaznamenávají transakce, které vzájemně čekají na sebe.
- Řešením je provedení ROLLBACK operace na jedné z uváznutých transakcí.

- Prevence uváznutí spočívá v tom, že je každé transakci přidělen TIMESTAMP
	- V případě varianty Wait-Die: když transakce A požaduje zámek na záznam, který je již uzamčen v transakci B
	potom pokud A je mladší než B, na transakci A je provedena operace ROLLBACK
	- V případě variatny Wound-Wait: když je A starší než B, transakce B je
	zrušena operací ROLLBACK a spuštěna znovu. Pokud je A mladší přejde do stavu čekání

# PREZENTACE 9 - ORM 
## VAZBY V ORM
- Vtahy mezi tabulkami jsou reprezentovány referencemi (ne cizími klíči)

## Vztah 1:1
	- V SŘBD by byl vztah napsán takto (Tabulka uzivatel)
		ucet INT NOT NULL REFERENCES Ucet;
	- V Javě je vazba 1:1 reprezentována takto (Taky tabulka Uzivatel)
		private Ucet ucet; - vytvorili jsme jednoduse objekt

## Vtah 1:N
	- V SŘBD by byl vztah napsán takto (nyní dáme referenci do účtu tabulky ucet místo uzivatele)
		uzivatel INT REFERENCES Uzivatel;
	- v Javě implementujeme takto: (Tabulka ucet)
		1. private Uzivatel uzivatel;
		2. Místo psaní do tabulky ucet napiseme private List<Ucet> ucet = new ArrayList<Ucet>(); do tabulky Uzivatel

# PREZENTACE 10
- Dva plány pro stejné transakce jsou ekvivaletní pokud dávají stejné výsledky; Plán vykonání dvou transakcí je korektní tehdy, pokud je serializovatelný
- Dvoufázové zamykání nám zaručuje že plán bude vždy serializovatelný (např. u protokolu řešící problém nepotvrzené závislosti)
- Transakce které dodržují tento protokol v první fázi zámky požadují a v druhé fázi je uvolňují (prováděno přes COMMIT a ROLLBACK).

## PODMÍNKA ACID 
- Izolovanost transakce nám bere výkon (počet vykonaných transakcí za určitou dobu), proto máme úrovně izolace
## READ UNCOMMITED (RU) [Nejnižší úroveň -> nižší izolace, vyšší propustnost]
- U této úrovně izolace může nastat Špinavé čtení, Neopakovatelné čtení i Výskyt fantomů
- V případě RU může nastat tedy i špinavé čtení, což znamená že transakce může načíst data, která ještě nebyla změněna a potvrzena jinou transakcí		

## READ COMMITED (RC)
- U této izolace může dojít k neopakovatelnému čtení a výskytu fantomů
- V tomto případě je umožněno Neopakovatelné čtení -> příkaz SELECT (READ) požaduje sdílený zámek na záznam, ale nedodrží dvoufázový zamykací protokol
a zámky mohou být uvolněny před ukončením transakce 
- Výlučné zámky (X) jsou uvolněny až na konci transakce 

## REPEATABLE READ (RR)
- U této izolace může dojít pouze k výskytu fantomů
- Výskyt fantomů znamená že SŘBD neprovádí zamykání rozsahu záznamů z tabulky a může nastat že dotaz transakce v jiných časech např. T1 a T4 vrátí různé výsledky.

## SERIALIZABLE (SR) [Nejvyšší úroveň -> vyšší izolace, nizší propustnost]
- U této izolace nemůže dojít k ničemu	

## START TRANSACTION
- Úroveň izolace se zadává ve tvaru ISOLATION LEVEL <izolace>, režim přístupu může být READ ONLY nebo READ WRITE a READ WRITE je defaultní. !!! Izolace nesmí být READ UNCOMMITED pokud zvolíme režim READ WRITE!!!
- DIAGNOSTIC SIZE number -> specifikuje kolik vyjímek bude systém ukládat na zásobníku
	
		příklad: 
  ```sql
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    ... selecty a updaty...
    COMMIT;	
  ```
	## SPRÁVA VERZÍ
	- je to optimističtější přístupež UZAMYKÁNÍ - předpokládáme, že pararelní transakce se nebudou ovlivňovat
	- při uzamkání systém spravuje jednu kopii dat a jednotlivým transakcím dá známky (timestamps)¨
	- při správě verzí systém vytváří při aktualizaci kopie dat a sleduje, která verze má být viditelná pro ostatní transakce [V závislosti na úrovni ISOLATION LEVEL]
	příklad v prezentaci slide 28

	## GRANULARITA ZÁMKŮ
	- Vyšší propustnost databázového systému
	- Znamená to zamykání větších objektů než je záznam (např. Tabulky, databáze atd...)
	- Jemná granularita = zamykání malých objektů |||| Hrubá granularita = zamykání velkých objektů
		např. když transakce přistupuje k pár záznamům je lepší použít jemnou granularitu -> zamknutí pro záznamy 
			v případě transakce co pracuje s mnoha záznamy tabulky -> hrubá granularita -> zamknutí celé tabulky

	## READ COMMITED 
	- Vhodná izolace pro prostředí s málo konflikty
	- Každý spuštěný dotaz vidí pouze data potvrzená před začátkem dotazu (ne transakce) -> dotaz nemůže přečíst data potvrzená během vykonávání dotazu
	- Může dojít k problémum zmíněným výše

	## SERIALIZABLE
	- Každý dotaz spuštěný transakcí vidí změny potvrzené před začátkem transakce a změny provedené samostatnou transakcí
	- Vhodná úroveň izolace pro velké databáze a krátké transakce, které pracují s málo záznamy
	- Největší problém jsou transakce, které provádí mnoho aktualizací pro stejné záznamy

	## READ ONLY úroveň [Pouze u ORACLE]
	- Je podobná SERIALIZABLE, akorát nesmí aktualizovat data
	- Vhodné pro generování sestav s konzistentním obsahem [Musí být stejný jako před začátkem transakce]

	## V SQL SERVER se nachází ještě SNAPSHOT 
	- stejné jako SERIALIZABLE z pohledu SQL, kde transakce vidí data potvrzená před začátkem transakce.
	- Nejsou použity zámky ale správa verzí
	- Aby bylo možné snapshot použít je třeba mít nastaveno SET ALLOW_SNAPSHOT_ISOLATION ON -> READ_COMMITED_SNAPSHOT pak dále nastavuje implicitní úroveň na READ COMMITED

	## EXPLICITNÍ ZÁMKY -> programátor o ně žádá manuálně
	- ROW SHARE (RS) - povoluje dalším transakcím dotazování, zamezuje získat na celou tabulku X zámek
	- ROW EXCLUSIVE (RX) - zamezuje ostatním transakcím získat S zámek; RX je auto. přidělen při aktualizaci záznamu
	- SHARE (S) - povoluje dalsim transakcim dotazovani, neaktualizuje tabulku
	- SHARE ROW EXCLUSIVE (SRX) - povoluje dalsim transakcim dotazovani, nepovoluje získání klíče S 
	- EXCLUSIVE (X) - nepovoluje zadne operace
		
  ##Příkaz LOCK TABLE <nazvy tabulek> IN <lock_type> MODE [NOWAIT]; 
  - lock_type muze byt vyse zminene zamky + SHARE UPDATE (stejne jako ROW SHARE)
  - NOWAIT znamená že systém nečeká s přidělením zámku pokud je tabulka zamčena jiným uživatlem
  - Systém uvolní všechny zámky na konci transakce 

  SELECT FOR UPDATE vybírá záznamy a zároveň je zamyká X (výlučným) zámkem -> Transakce požaduje X zámek na záznamy a ROW SHARE tabulkový zámek
  ORACLE používá při UPDATE UNDO segment, který obsahuje staré hodnoty, které byly přepsány nepotvrzenou transakcí


  # PREZENTACE 11
  - Základní úložiště pro tabulku relačního modelu je HEAP TABLE (Halda)
  - Vyhledávání v databázi (SELECT) je sekvenční O(n), ale pomocí indexace se může snížit na O(log n)
  - DELETE má časovou složitost teoreticky O(1) ale často dojde k vyhledávání takže je O(n), bloky v haldě se nemažou, počet zůstane stejný
  - INSERT nám zabírá O(1) pokud se záznam ukládá na konec pole nebo O(n) pokud se ukládá na první volnou pozici

  - [Pojmy v ORACLE] executions = počet provedení dotazů; buffer_gets = počet přístupů do haldy; cpu_time_ms = čas jak dlouho trvá provést dotaz, v DB je v mikrosekundách; elapsed_time_ms = cpu_time + wait times; rows_processed = počet záznamů výsledku
  - V oracle využijeme pohledu systemového katalogu pro indexy: user_indexes

  - [Pojmy v SQL SERVER] logical reads [buffer gets v Oracle]; physical reads [Physical reads v oracle]
  - V SQL Server využijeme pohledu systémového kataloguu sys.tables a sys.indexes

  ## INDEX PRO PRIMÁRNÍ KLÍČ
  - Je to datová struktura B-Strom, který poskytuje O(log n) časové složitosti základních operací
  - Je tedy výrazně rychlejší než Halda s lineární složitostí vyhledávání pro jednotné hodnoty 
  - Index je automaticky vytvářen pro rychlejší kontrolu jedinečností prim. klíče při INSERT, pro rychlejší provedení dotazů na prim. klíč a pro rychlejší kontrolu referenční integrity

  - Ke každé tabulce je vytvořena halda a index typu B-Tree pro primární klíč a unique atributy
  - Index obsahuje v položkách stránek dvojice [Hodnota primárního klíče, ROWID], kde ROWID je odkaz na záznam do haldy.

  ## ROWID
  - Pomocí ROWID identifikujeme záznamy v haldě
  - ROWID je nejčastěji INT skládající se z: ČÍSLA BLOKU, POZICE ZÁZNAMU V HALDĚ

  - Dotazy se selekcí na primární klíč, které se vykonávají pomocí INDEXU, pracují v těchto krocích:
  1. Pomocí bodového dotazu v indexu typu B-Tree je nalezena hodnota atributu a sním ROWID  [Oracle: INDEX (UNIQUE SCAN); SQL SERVER: Index Seek] -> IO Cost záleží na výšce stromu: IO Cost = h + 1
  2. Pomocí ROWID získá databáze přímo záznam z Haldy [Oracle: TABLE ACCESS (BY INDEX ROWID); SQL SERVER: RID Lookup] -> IO cost je přímy přístup k bloku: IO Cost = 1
  IO Cost dotazu se selekcí na primární klíč je tedy: IO Cost = h + 2

  ## INDEX TYPU B-TREE
  - V případě dotazů které vracejí relativně málo záznamů v poměru počtu záznamů tabulky je vhodné vytvořit index: CREATE INDEX <name> ON <table>(<list_of_atributes>)
  - Nejčastěji se používá varianta B+-strom, která obsahuje indexované položky pouze v listových uzlech
  
  ## VLASTNOSTI B+-Tree řádu C:
  - Snadno stránkovatelný (C nastavíme dle velikosti stránky např. 8kb)
  - Vyvážený: vzdálenost od všech listů ke kořenovému uzlu je stejná 
  - Výška stromu je log[c](n)
  - Mazání, vkládání a bodový dotaz mají časovou složitost O(log n)
  - IO cost = h + 1

  ## INDEX
  - Obsahuje klíč, ROWID [které odkazuje do haldy na záznam tabulky] -> Klíč a ROWID nazýváme položkou uzlu B-Strom

  ## BODOVÝ DOTAZ
  - Je proveden bodovým dotazem v indexu a získáním záznamu z bloku haldy: IO Cost = h + 2

  ## SLOŽENÝ KLÍČ INDEXU
  - Když klíč obsahuje více než jeden atribut je to složený klíč
  - Klíče jsou v uzlech B-Stromu setřízeny dle atributů tak jak byly uvedeny v definici CREATE INDEX

  ## BODOVÝ DOTAZ A SLOŽENÝ KLÍČ
  - Dotaz musí odpovídat lexikografickém uspořádání, např v select příkazu: SELECT .... WHERE idOrder = 12356 AND idProduct = 47506; V tabulce jsou tyto indexy serazeny vedle sebe
  - (idOrder, idProduct) je tedy primární klíč a bude proveden bodový dotaz v B-Stromu

  ## ROZSAHOVÝ DOTAZ A SLOŽENÝ KLÍČ	
  - K jedné hodnotě idOrder náleží 0 až více záznamů -> TABLE ACCES BY INDEX ROWID BATCHED.. INDEX RANGE SCAN

  ## Složený klíč bez použití indexu
  - Dotaz nám neodpovída lexikografickému uspořádání -> SELECT ... WHERE idProduct = 32342 -> chybí hodnoty atributu idOrder
  - V B-Stromu je tedy možné získat výsledek jeno sekvenčním průchodem -> DBS vyhodnotí, že výsledek by byl přes sekvenční průchod B-Stromem moc 
  vysoký tak radši zvolí průchod haldou -> v tomto případě to trvá taky déle než pomocí indexu


  ## SHLUKOVANÁ TABULKA - PREZENTACE Z JINÉHO PŘEDMĚTU
  - Záznamy v této tabulce jsou setříděny, nejčastěji se používá B-strom	
  - Snahou je využít vlastnosti indexu bez nutnosti přistupovat do tabulky (eliminovat operace TABLE ACCESS (BY INDEX ROWID))

  ## ROZDÍL MEZI SHLUKOVANOU TABULKOU POMOCÍ BSTROMU A INDEXEM TYPU B-TREE:
  - V případě shlukované tabulky je B-Strom použit k fyzickému uspořádání samotných dat; V případě Indexu je B-Strom použit k rychlému vyhledávání záznamů v databázi, ale samotná data mohou být uložena jinde 
  a jejich fyzické uspořádání nezávisí na struktuře indexu (můžou být ale taky shlukované indexy)
