--*************************
--****  Ejercicio 2.a  ****
--*************************
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication_plan_log
  --
  ------------------------------------------------------------------------------------------------
-- Crear una secuencia para el id de la tabla
CREATE SEQUENCE medication_plan_log_id START 1;

-- Crear la tabla  
CREATE TABLE erp.tb_medication_plan_log  (
    mpl_id                   INT NOT NULL DEFAULT nextval('medication_plan_log_id'),
    mpl_timestamp            TIMESTAMP NOT NULL DEFAULT current_timestamp,
    mpl_cause                CHAR(6) NOT NULL,
    mpl_medplan_id           INT,
    mpl_medplan_detail_id    INT,
    mpl_old_med_id           INT,
    mpl_new_med_id           INT,
    mpl_old_units            INT,
    mpl_new_units            INT,
    mpl_old_doctor           VARCHAR(20),
    mpl_new_doctor           VARCHAR(20),

    CONSTRAINT pk_medication_plan_log PRIMARY KEY (mpl_id)
  );

-- Crear un trigger sobre la tabla tb_medication_plan En esta tabla sólo hay que detectar el cambio de doctor, además de los inserts y deletes
CREATE OR REPLACE FUNCTION erp.fn_log_medication_plan() RETURNS trigger AS $$
DECLARE 
	medplan_id erp.tb_medication_plan_log.mpl_medplan_id%TYPE;
BEGIN
	-- Determinar el medplan_id
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		medplan_id := NEW.medplan_id;
	ELSEIF (TG_OP = 'DELETE') THEN
		medplan_id := OLD.medplan_id;	
	END IF;
	
	--Registrar la modificacion del plan de medicacion
	INSERT INTO erp.tb_medication_plan_log (mpl_medplan_id,mpl_cause,mpl_old_doctor, mpl_new_doctor)
	VALUES (medplan_id, TG_OP, OLD.medplan_doctor, NEW.medplan_doctor);
	
	-- Aunque en un TRIGGER AFTER se ignora el RETURN es necesario hacerlo
	RETURN NULL;
END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS tg_update_medication_plan ON erp.tb_medication_plan;
CREATE TRIGGER tg_update_medication_plan
  AFTER INSERT OR UPDATE of medplan_doctor OR DELETE ON erp.tb_medication_plan
  FOR EACH ROW
  EXECUTE PROCEDURE erp.fn_log_medication_plan();


-- Crear un trigger sobre la tabla tb_medication_plan_detail
-- En esta tabla hay que registrar todos los cambios
CREATE OR REPLACE FUNCTION erp.fn_log_medication_plan_detail() RETURNS trigger AS $$
DECLARE 
	medplan_id              erp.tb_medication_plan_log.mpl_medplan_id%TYPE;
	medplan_detail_id       erp.tb_medication_plan_log.mpl_medplan_detail_id%TYPE;

BEGIN
	-- Determinar el medplan_id y el medplan_detail_id
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		medplan_id := NEW.medplan_id;
		medplan_detail_id := NEW.medplan_detail_id;
	ELSEIF (TG_OP = 'DELETE') THEN
		medplan_id := OLD.medplan_id;	
		medplan_detail_id := OLD.medplan_detail_id;
	END IF;
	
	--Registrar la modificacion del plan de medicación
	INSERT INTO erp.tb_medication_plan_log (mpl_medplan_id,mpl_medplan_detail_id,mpl_cause,mpl_old_med_id, mpl_new_med_id, mpl_old_units, mpl_new_units)
	VALUES (medplan_id,medplan_detail_id, TG_OP, OLD.med_id, NEW.med_id, OLD.medplan_detail_units, NEW.medplan_detail_units);
	
	-- Aunque en un TRIGGER AFTER se ignora el RETURN es necesario hacerlo
	RETURN NULL;
END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS tg_update_medication_plan_detail ON erp.tb_medication_plan_detail;
CREATE TRIGGER tg_update_medication_plan_detail
  AFTER INSERT OR UPDATE OR DELETE ON erp.tb_medication_plan_detail
  FOR EACH ROW
  EXECUTE PROCEDURE erp.fn_log_medication_plan_detail();


--*************************
--****  Ejercicio 2.b  ****
--*************************
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication_stock_forecast
  --
  ------------------------------------------------------------------------------------------------
-- DROP TABLE erp.tb_medication_stock_forecast;
-- Crear la tabla  
CREATE TABLE erp.tb_medication_stock_forecast  (
    mfs_id                   INT,
    mfs_name		     VARCHAR(20),
    mfs_timestamp            TIMESTAMP NOT NULL DEFAULT current_timestamp,
    mfs_stock                INT NOT NULL,
    mfs_daily_consumption    INT,
    mfs_days_of_stock        DECIMAL (10,2),
    mfs_category	     VARCHAR(8),

    CONSTRAINT pk_medication_stock_forecast PRIMARY KEY (mfs_id)
  );

-- Crear la funcion
CREATE OR REPLACE FUNCTION erp.fn_recalculate_medication_stock_forecast( ) RETURNS VOID AS $$
DECLARE
	resultado RECORD;
BEGIN

	-- Borra los registros de la tabla tb_medication_stock_forecast
	DELETE FROM tb_medication_stock_forecast;

	FOR resultado IN 
	      SELECT T1.*,
		CASE WHEN stock_days < 2 THEN 'URGENT'
		  WHEN stock_days < 7 THEN 'PRIORITY'
		  WHEN stock_days < 14 THEN 'ORDINARY'
		  WHEN stock_days >=14 THEN 'EXCESS'
		END as category

		FROM (

			SELECT T2.*, 
			CASE WHEN daily_consumption IS NULL THEN 9999.99 ELSE cast(med_stock_units / cast(daily_consumption as decimal) as decimal(10,2)) END as stock_days

			FROM (

				SELECT m.med_id, m.med_name, m.med_stock_units, SUM(medplan_detail_units) as daily_consumption
				FROM erp.tb_medication m 
					left join (erp.tb_medication_plan_detail d 
								join erp.tb_medication_plan pla on pla.medplan_id = d.medplan_id 
								join erp.tb_patient pat on pat.pat_id = pla.pat_id and pat.pat_discharge_date IS NULL) 
						on m.med_id = d.med_id
				GROUP BY m.med_id
			) AS T2
		) AS T1

	LOOP
		INSERT INTO tb_medication_stock_forecast (mfs_id, mfs_name, mfs_stock, mfs_daily_consumption, mfs_days_of_stock, mfs_category)
		VALUES (resultado.med_id, resultado.med_name, resultado.med_stock_units, resultado.daily_consumption, resultado.stock_days, resultado.category);
	END LOOP;

END; 
$$ language plpgsql;