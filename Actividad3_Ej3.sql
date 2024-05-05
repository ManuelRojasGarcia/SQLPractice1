------------------------------------------------------------------
-- 3. a) Creamos la función
------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE erp.calculo_tiempo(tamano INT, index_type VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    value INT;
BEGIN
    -- Eliminar la tabla si existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'erp' AND table_name = 'tiempos') THEN
        EXECUTE 'DROP TABLE erp.tiempos';
    END IF;
    -- Crear la tabla con las dos columnas
    EXECUTE 'CREATE TABLE erp.tiempos (id INT, num FLOAT)';
    -- Poblar la tabla con datos aleatorios
    FOR value IN 1..tamano LOOP
        EXECUTE 'INSERT INTO erp.tiempos (id, num) VALUES ($1, $2)' USING value, random();
    END LOOP;
    -- Eliminar el índice si existe
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'erp' AND tablename = 'tiempos' AND indexname = 'indice_t') THEN
        EXECUTE 'DROP INDEX erp.indice_t';
    END IF;
    -- Crear el índice según el tipo indicado sobre el valor int
    IF index_type = 'btree' THEN
        EXECUTE 'CREATE INDEX indice_t ON erp.tiempos (id)';
    ELSIF index_type = 'hash' THEN
        EXECUTE 'CREATE INDEX indice_t ON erp.tiempos USING hash (id)';
    END IF;
    -- Tomar el tiempo inicial
    start_time := clock_timestamp();
    -- Hacer 100 consultas sobre la tabla
    FOR value IN 1..100 LOOP
        EXECUTE 'SELECT * FROM erp.tiempos WHERE id = $1' USING floor(random() * tamano + 1);
    END LOOP;
    -- Tomar el tiempo final
    end_time := clock_timestamp();
    -- Mostrar el tiempo empleado
    RAISE NOTICE 'Tiempo empleado: %', end_time - start_time;
END;
$$;

------------------------------------------------------------------
-- 3.b) Calculamos el tiempo para nRows en cada tipo de índice
------------------------------------------------------------------

CALL erp.calculo_tiempo(10, 'sin índice');
CALL erp.calculo_tiempo(10, 'btree');
CALL erp.calculo_tiempo(10, 'hash');

CALL erp.calculo_tiempo(100, 'sin índice');
CALL erp.calculo_tiempo(100, 'btree');
CALL erp.calculo_tiempo(100, 'hash');

CALL erp.calculo_tiempo(1000, 'sin índice');
CALL erp.calculo_tiempo(1000, 'btree');
CALL erp.calculo_tiempo(1000, 'hash');

CALL erp.calculo_tiempo(10000, 'sin índice');
CALL erp.calculo_tiempo(10000, 'btree');
CALL erp.calculo_tiempo(10000, 'hash');

CALL erp.calculo_tiempo(100000, 'sin índice');
CALL erp.calculo_tiempo(100000, 'btree');
CALL erp.calculo_tiempo(100000, 'hash');


------------------------------------------------------------------
-- 3.c) Plan de ejecución
------------------------------------------------------------------

EXPLAIN SELECT * FROM erp.tiempos WHERE id= 15000;



