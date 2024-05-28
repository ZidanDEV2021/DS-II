## PREZENTACE 5 - Statické a Dynamické SQL

### Dynamické SQL v Pythonu
Dynamické SQL umožňuje vytváření dotazů, které nemají pevně zadané hodnoty jako `table_name`, `column_name` nebo `column_type`. Příklady:

```python
def create_table(table_name):
    query = f"CREATE TABLE {table_name} (id INT PRIMARY KEY, name TEXT);"
    return query

def add_column(table_name, column_name, column_type):
    query = f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type};"
    return query
```

### Statické SQL
Na rozdíl od dynamického SQL, statické SQL má pevně dané hodnoty. Příklad:

```sql
SELECT * FROM Employees WHERE EmployeeID = 1;
```

## PREZENTACE 6

### Vlastnosti ACID
- **A - Atomicity (Atomičnost)**: Transakce je nedělitelná, buď se provede celá, nebo vůbec.
- **C - Consistency (Konzistence)**: Transakce převede databázi z jednoho konzistentního stavu do druhého.
- **I - Isolation (Izolace)**: Transakce probíhají izolovaně od sebe.
- **D - Durability (Trvalost)**: Po potvrzení transakce jsou změny trvalé.

### Aktualizační strategie
#### Odložená aktualizace NO-UNDO / REDO
- Změny se zapisují do logu a po potvrzení transakce do databáze.
- Používá se REDO v případě selhání.

#### Okamžitá aktualizace UNDO / NO-REDO
- Změny se zapisují ihned do logu i databáze.
- Používá se UNDO v případě selhání před potvrzením transakce.

#### Kombinovaná aktualizace UNDO / REDO
- Aktualizace do logu po potvrzení, do databáze v intervalech (checkpointy).
- Běžná v praxi.

## PREZENTACE 8

### Problémy souběžnosti
- **Špinavé čtení (Dirty read)**: Čtení neautorizovaných změn.
- **Špinavý zápis (Dirty write)**: Zápis do neautorizovaných změn.
- **Nekonzistentní analýza**: Opakované čtení stejného záznamu vrací různé hodnoty.
- **Ztráta aktualizace**: Dvě nebo více transakcí přepisují stejný záznam.
- **Nepotvrzená závislost**: Práce s hodnotami, které byly změněny nepotvrzenou transakcí.

### Uzamykání
- **Výlučné zámky (X)**: Pro zápis.
- **Sdílené zámky (S)**: Pro čtení.

### Zamykací protokol
- Pro čtení sdílený zámek (S), pro zápis výlučný zámek (X).
- Požadavky na zámky mohou vést k čekání, ale ne do nekonečna (prevence uváznutí).

## PREZENTACE 9 - ORM

### Vazby v ORM
- **1:1 Vztah**: Reprezentace v Javě pomocí objektu.
- **1:N Vztah**: Reprezentace v Javě pomocí seznamu objektů.

## PREZENTACE 10

### Plány transakcí a ACID
- Ekvivalentní plány dávají stejné výsledky.
- Dvoufázové zamykání zaručuje serializovatelnost.

### Úrovně izolace
- **READ UNCOMMITTED**: Nejnižší úroveň, může nastat špinavé čtení.
- **READ COMMITTED**: Neopakované čtení a výskyt fantomů.
- **REPEATABLE READ**: Výskyt fantomů.
- **SERIALIZABLE**: Nejvyšší úroveň, žádné problémy.

### Správa verzí a granularita zámků
- Správa verzí vytváří kopie dat při aktualizacích.
- Jemná granularita zamykání zámky malé objekty, hrubá větší objekty.

## PREZENTACE 11

### Indexy a vyhledávání
- **B-Tree Index**: Rychlé vyhledávání s časovou složitostí O(log n).
- **ROWID**: Identifikátor záznamů v haldě.
- **Bodový dotaz**: Vyhledání záznamu pomocí B-Tree indexu.
- **Shlukovaná tabulka**: Data uspořádána pomocí B-Stromu.

### Explicitní zámky v SQL
- **ROW SHARE (RS)**: Dotazy povoleny, zápisy blokovány.
- **ROW EXCLUSIVE (RX)**: Zápisy povoleny, sdílené zámky blokovány.
- **SHARE (S)**: Dotazy povoleny, zápisy blokovány.
- **SHARE ROW EXCLUSIVE (SRX)**: Dotazy povoleny, klíče S blokovány.
- **EXCLUSIVE (X)**: Všechny operace blokovány.

### Lock Table a SELECT FOR UPDATE
- Lock Table: Uzamykání tabulek s různými typy zámků.
- SELECT FOR UPDATE: Zamyká záznamy pro výlučný zápis.

### Halda a časová složitost operací
- **SELECT**: Sekvenční vyhledávání O(n).
- **DELETE**: Často O(n) kvůli vyhledávání.
- **INSERT**: O(1) nebo O(n) dle pozice vkládání.

Tento zjednodušený přehled by měl usnadnit studium a pochopení klíčových konceptů v SQL, ORM a správě databází.
