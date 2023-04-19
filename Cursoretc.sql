DECLARE
  CURSOR c_emp IS
    SELECT empno, ename, sal FROM emp;
  v_empno NUMBER;
  v_ename VARCHAR2(50);
  v_sal NUMBER;
BEGIN
  OPEN c_emp;
  LOOP
    FETCH c_emp INTO v_empno, v_ename, v_sal;
    EXIT WHEN c_emp%NOTFOUND;
    --zde můžete zpracovávat jednotlivé řádky
  END LOOP;
  CLOSE c_emp;
END;
-------------------------------------------
BEGIN
  INSERT INTO employees (employee_id, first_name, last_name)
  VALUES (101, 'John', 'Doe');
  INSERT INTO employees (employee_id, first_name, last_name)
  VALUES (102, 'Jane', 'Doe');
  -- Pokud se vyskytne chyba při vkládání druhého zaměstnance, celá transakce bude vrácena pomocí ROLLBACK.
  -- Pokud jsou oba zaměstnanci úspěšně vloženi, změny budou potvrzeny pomocí COMMIT.
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
END;
--------------------------------------------
BEGIN
  -- zde se provádí operace, která může způsobit výjimku
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- v tomto případě se provede následující akce, pokud je zachycena výjimka NO_DATA_FOUND
  WHEN OTHERS THEN
    -- v tomto případě se provede následující akce, pokud je zachycena jakákoli jiná výjimka
END;
