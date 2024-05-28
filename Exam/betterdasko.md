## PREZENTACE 5 - Statické a Dynamické SQL

### Dynamické SQL v Pythonu
Dynamické SQL umožňuje vytváření dotazů za běhu programu, kde hodnoty jako `table_name`, `column_name` nebo `column_type` nejsou pevně zadané. Příklady:

```python
def create_table(table_name):
    query = f"CREATE TABLE {table_name} (id INT PRIMARY KEY, name TEXT);"
    return query

def add_column(table_name, column_name, column_type):
    query = f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type};"
    return query
```

V těchto funkcích se dotazy vytvářejí dynamicky pomocí f-stringů, což umožňuje flexibilitu při pojmenování tabulek a sloupců.

### Statické SQL
Na rozdíl od dynamického SQL, statické SQL má pevně dané hodnoty a nemění se za běhu programu. Příklad:

```sql
SELECT * FROM Employees WHERE EmployeeID = 1;
```

Tento dotaz má pevně zadané hodnoty a nemůže být změněn bez úpravy samotného kódu.

## PREZENTACE 6

### Vlastnosti ACID
- **A - Atomicity (Atomičnost)**: Transakce je nedělitelná, buď se provede celá, nebo vůbec. Například, pokud banka převádí peníze mezi účty, obě strany transakce (odepsání z jednoho účtu a připsání na druhý) se musí provést společně.
- **C - Consistency (Konzistence)**: Transakce převede databázi z jednoho konzistentního stavu do druhého. Například, po transakci by měly být zachovány všechny referenční integritní vazby.
- **I - Isolation (Izolace)**: Transakce probíhají izolovaně od sebe. To znamená, že změny prováděné jednou transakcí nejsou viditelné pro ostatní transakce, dokud nejsou potvrzeny.
- **D - Durability (Trvalost)**: Po potvrzení transakce jsou změny trvalé, a to i v případě pádu systému.

### Aktualizační strategie
#### Odložená aktualizace NO-UNDO / REDO
- Změny se zapisují do logu a po potvrzení transakce do databáze. Tím se zajistí, že pokud transakce selže před potvrzením, nebudou provedeny žádné změny.
- **Redo**: Pokud dojde k selhání po potvrzení, log se použije k opětovnému provedení změn.

#### Okamžitá aktualizace UNDO / NO-REDO
- Změny se zapisují ihned do logu i databáze. Pokud transakce selže před potvrzením, **undo** operace vrátí změny do původního stavu.
- **Undo**: Původní hodnoty jsou zaznamenány do logu, což umožňuje vrácení změn v případě chyby.

#### Kombinovaná aktualizace UNDO / REDO
- Změny se zapisují do logu po potvrzení transakce a do databáze v intervalech (checkpointy). To kombinuje výhody obou přístupů.
- **Undo/Redo**: Zajišťuje, že změny lze vrátit nebo opětovně provést podle potřeby.

## PREZENTACE 8

### Problémy souběžnosti
- **Špinavé čtení (Dirty read)**: Čtení neautorizovaných změn. Například, pokud transakce A změní záznam a transakce B jej přečte před potvrzením, může dojít k problému, pokud transakce A selže a vrátí změny zpět.
- **Špinavý zápis (Dirty write)**: Zápis do neautorizovaných změn. Například, pokud transakce A zapíše záznam, a transakce B jej změní před potvrzením transakce A, mohou být změny transakce A ztraceny.
- **Nekonzistentní analýza**: Opakované čtení stejného záznamu vrací různé hodnoty. Například, pokud transakce T1 přečte záznam, pak jej transakce T2 změní, a T1 jej znovu přečte, mohou být hodnoty rozdílné.
- **Ztráta aktualizace**: Dvě nebo více transakcí přepisují stejný záznam. Například, pokud transakce A a B aktualizují stejný záznam současně, jedna z nich může ztratit své změny.
- **Nepotvrzená závislost**: Práce s hodnotami, které byly změněny nepotvrzenou transakcí. Například, pokud transakce A změní záznam a transakce B jej přečte, ale A není potvrzena, může B pracovat s neplatnými údaji.

### Uzamykání
- **Výlučné zámky (X)**: Zámky pro zápis. Blokují všechny ostatní operace na záznamu.
- **Sdílené zámky (S)**: Zámky pro čtení. Blokují pouze zápis na záznamu.

### Zamykací protokol
- Pro čtení se používají sdílené zámky (S), které umožňují ostatním transakcím také číst.
- Pro zápis se používají výlučné zámky (X), které blokují všechny ostatní operace.
- Pokud transakce nemůže získat požadovaný zámek, přejde do stavu čekání.

## PREZENTACE 9 - ORM

### Vazby v ORM
- **1:1 Vztah**: Reprezentace v databázi pomocí cizího klíče, v Javě pomocí objektu.
    ```java
    // V SQL
    CREATE TABLE Uzivatel (
        id INT PRIMARY KEY,
        ucet INT NOT NULL REFERENCES Ucet
    );

    // V Javě
    public class Uzivatel {
        private Ucet ucet;
    }
    ```
- **1:N Vztah**: Reprezentace v databázi pomocí cizího klíče, v Javě pomocí seznamu objektů.
    ```java
    // V SQL
    CREATE TABLE Ucet (
        id INT PRIMARY KEY,
        uzivatel INT REFERENCES Uzivatel
    );

    // V Javě
    public class Uzivatel {
        private List<Ucet> ucty = new ArrayList<Ucet>();
    }
    ```

## PREZENTACE 10

### Plány transakcí a ACID
- Plány transakcí jsou ekvivalentní, pokud dávají stejné výsledky.
- Dvoufázové zamykání zaručuje serializovatelnost, což znamená, že transakce budou vždy prováděny v pořádku.

### Úrovně izolace
- **READ UNCOMMITTED**: Nejnižší úroveň izolace, může nastat špinavé čtení.
- **READ COMMITTED**: Vyšší úroveň izolace, může dojít k neopakovatelnému čtení a výskytu fantomů.
- **REPEATABLE READ**: Ještě vyšší úroveň izolace, může dojít pouze k výskytu fantomů.
- **SERIALIZABLE**: Nejvyšší úroveň izolace, žádné problémy nemohou nastat.

### Správa verzí a granularita zámků
- Správa verzí vytváří kopie dat při aktualizacích, což umožňuje vyšší propustnost systému.
- **Jemná granularita**: Zamykání malých objektů, vhodné pro transakce s malým počtem záznamů.
- **Hrubá granularita**: Zamykání velkých objektů, vhodné pro transakce s velkým počtem záznamů.

## PREZENTACE 11

### Indexy a vyhledávání
- **B-Tree Index**: Rychlé vyhledávání s časovou složitostí O(log n). Používá se pro rychlou kontrolu jedinečnosti, rychlé provedení dotazů a kontrolu referenční integrity.
- **ROWID**: Identifikátor záznamů v haldě, skládá se z čísla bloku a pozice záznamu v haldě.
- **Bodový dotaz**: Vyhledání záznamu pomocí B-Tree indexu, časová složitost je O(log n).

### Shlukovaná tabulka
- Data jsou uspořádána pomocí B-Stromu, což eliminuje potřebu operace TABLE ACCESS (BY INDEX ROWID).

### Explicitní zámky v SQL
- **ROW SHARE (RS)**: Povolení dotazování, blokování zápisů.
-

 **ROW EXCLUSIVE (RX)**: Povolení zápisů, blokování sdílených zámků.
- **SHARE (S)**: Povolení dotazování, blokování zápisů.
- **SHARE ROW EXCLUSIVE (SRX)**: Povolení dotazování, blokování sdílených zámků.
- **EXCLUSIVE (X)**: Blokování všech operací.

### Lock Table a SELECT FOR UPDATE
- **Lock Table**: Uzamykání tabulek s různými typy zámků.
    ```sql
    LOCK TABLE tabulka IN EXCLUSIVE MODE;
    ```
- **SELECT FOR UPDATE**: Zamyká záznamy pro výlučný zápis.
    ```sql
    SELECT * FROM tabulka WHERE podminka FOR UPDATE;
    ```

### Halda a časová složitost operací
- **SELECT**: Sekvenční vyhledávání O(n).
- **DELETE**: Často O(n) kvůli vyhledávání záznamu.
- **INSERT**: O(1) nebo O(n) podle toho, kam je záznam vkládán.

Tento přehled poskytuje detailní informace o klíčových konceptech v SQL, ORM a správě databází, včetně toho, jak jednotlivé komponenty fungují a jak je lze využít v praxi.
