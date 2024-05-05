--*************************
--****  Ejercicio 1.a  ****
--*************************
CREATE OR REPLACE FUNCTION erp.fn_check_medication(
	patient_id integer,
	medication_id integer,
	units_to_be_given integer
	) 
	
	returns boolean as $$
DECLARE
	discharge_date erp.tb_patient.pat_discharge_date%TYPE;
	plan_id        erp.tb_medication_plan.medplan_id%TYPE;
	detail_id      erp.tb_medication_plan_detail.medplan_detail_id%TYPE;
	detail_units   erp.tb_medication_plan_detail.medplan_detail_units%TYPE;
	stock_units    erp.tb_medication.med_stock_units%TYPE;
	
BEGIN
	-- Verificar el paciente
	SELECT pat_discharge_date INTO discharge_date
	FROM erp.tb_patient
	WHERE pat_id = patient_id;

	-- CHECK:: discharge_date debería ser NULO o el paciente ya habrá sido dado de alta
	IF (discharge_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Patient was discharged on %' , discharge_date;
	END IF;

	-- Buscar un plan de medicacion del paciente que tenga el medicamento y su dosis
	SELECT pl.medplan_id, d.medplan_detail_id, d.medplan_detail_units INTO plan_id, detail_id, detail_units
	FROM erp.tb_medication_plan pl LEFT JOIN erp.tb_medication_plan_detail d ON pl.medplan_id = d.medplan_id
	WHERE pl.pat_id = patient_id AND d.med_id = medication_id;

	-- CHECK:: medplan_id no debería ser NULO. Si es así es que no se ha encontrado plan de medicación
	IF (plan_id IS NULL) THEN
		RAISE EXCEPTION 'Medication plan not found for this patient';
	END IF;

	-- CHECK:: medplan_detail_id no debería ser NULO. Si es así es que no se ha recetado la medicación 
	IF (detail_id IS NULL) THEN
		RAISE EXCEPTION 'Medicine prescription not found for this patient';
	END IF;

	-- CHECK:: detail_units debe ser mayor o igual que units_to_be_given. Si no es así hay peligro de sobredosis
	IF (detail_units < units_to_be_given) THEN
		RAISE EXCEPTION 'WARNING:: Too many units for this patient';
	END IF;

	-- Buscar el stock del producto
	SELECT med_stock_units INTO stock_units 
	FROM erp.tb_medication
	WHERE med_id = medication_id;

	-- CHECK:: stock_units debe ser mayor o igual que units_to_be_given. Si no es así no hay stock suficiente
	IF (stock_units < units_to_be_given) THEN
		RAISE EXCEPTION 'Insufficient stock for this request';
	END IF;	

	-- Final de control de las posibles situaciones de error. Si ha llegado aquí, está todo correcto

	RETURN true;
END;
$$ language plpgsql;


--*************************
--****  Ejercicio 1.b  ****
--*************************
CREATE OR REPLACE FUNCTION erp.fn_medication_inserted() RETURNS trigger AS $$
DECLARE 
	discharge_date erp.tb_patient.pat_discharge_date%TYPE;
	plan_id        erp.tb_medication_plan.medplan_id%TYPE;
	detail_id      erp.tb_medication_plan_detail.medplan_detail_id%TYPE;
	detail_units   erp.tb_medication_plan_detail.medplan_detail_units%TYPE;

	patient_id  	erp.tb_patient.pat_id%TYPE;
	medication_id   erp.tb_medication.med_id%TYPE;
	units  		erp.tb_medication_plan_detail.medplan_detail_units%TYPE;
	numRegistros    integer;
BEGIN
	--Recuperar valores
	patient_id := NEW.medgiv_pat_id;
	medication_id := NEW.medgiv_med_id;
	units := NEW.medgiv_units;

	-- Verifica que no se haya informado la fecha ni la hora
	IF (NEW.medgiv_date IS NOT NULL OR NEW.medgiv_time IS NOT NULL) then
		RAISE EXCEPTION 'Time and date can not be informed';
	END IF;
	-- Tambien se admite como válido ignorar la fecha y hora informadas y 
	-- sobreescribirlas con la fecha y hora actual
	NEW.medgiv_date := current_date;
	NEW.medgiv_time := current_time;
	
	-- Verifica que la medicación pueda ser suministrada al paciente
	IF NOT (erp.fn_check_medication(patient_id, medication_id, units)) THEN
		RETURN NULL;
	END IF;

	--Verifica si la cantidad es cero, si lo es, recupera el registro a eliminar
	IF (units = 0 ) THEN
		-- Busca si existe el registro con antigüedad inferior a 5 minutos
		SELECT COUNT(*) INTO numRegistros 
		FROM erp.tb_medication_given
		WHERE medgiv_pat_id = patient_id
			AND medgiv_med_id = medication_id
			AND medgiv_date = current_date
			AND medgiv_time >= current_time - '5 minutes'::interval;

		-- Si existe, lo borra
		IF (numRegistros > 0) THEN
			DELETE FROM erp.tb_medication_given
			WHERE medgiv_pat_id = patient_id
				AND medgiv_med_id = medication_id
				AND medgiv_date = current_date;
		ELSE
			-- Muestra un error
			RAISE EXCEPTION 'Records older than 5 minutes cannot be deleted ';
		END IF;
		-- Evita la inserción del registro con cantidad 0
		RETURN null;  
	ELSE
		-- Si la cantidad es diferente de cero, se inserta el registro
		RETURN NEW;
	END IF;

	-- Control de excepciones
	EXCEPTION
		WHEN raise_exception THEN
			RAISE NOTICE 'ERROR:: %', SQLERRM;

		RETURN NULL;
END;
$$ language plpgsql;


DROP TRIGGER IF EXISTS tg_insert_medication_given ON erp.tb_medication_given;
CREATE TRIGGER tg_insert_medication_given
  BEFORE INSERT ON erp.tb_medication_given
  FOR EACH ROW 
  EXECUTE PROCEDURE erp.fn_medication_inserted();

CREATE OR REPLACE FUNCTION erp.fn_medication_given_updated() RETURNS trigger AS $$
DECLARE 
BEGIN
	RAISE EXCEPTION 'Updates and deletes are not allowed over erp.tb_medication_given table' ;
END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS tg_update_medication_given ON erp.tb_medication_given;
CREATE TRIGGER tg_update_medication_given
  BEFORE UPDATE OR DELETE ON erp.tb_medication_given
  FOR EACH STATEMENT
  WHEN (pg_trigger_depth() = 0)      --- Se evita abortar la actualización del registro al hacer la salida
  EXECUTE PROCEDURE erp.fn_medication_given_updated();


--*************************
--****  Ejercicio 1.c  ****
--*************************
CREATE OR REPLACE FUNCTION erp.fn_modified_medication_given() RETURNS trigger AS $$
DECLARE 
	medication_id   erp.tb_medication.med_id%TYPE;
	units  		erp.tb_medication_plan_detail.medplan_detail_units%TYPE;
BEGIN

	-- Si es una inserción deberemos restar las unidades, pero si es un delete habrá que restaurar las unidades sustraídas
	IF (TG_OP = 'INSERT') THEN
		units := NEW.medgiv_units;
		medication_id := NEW.medgiv_med_id;
	ELSEIF (TG_OP = 'DELETE') THEN
		units := -1 * OLD.medgiv_units;
		medication_id := OLD.medgiv_med_id;
	END IF;

	-- Actualizar el stock
	UPDATE erp.tb_medication
	SET med_stock_units = med_stock_units - units
	WHERE med_id = medication_id;

	-- Aunque en un trigger AFTER se ignora el RETURN, es necesario hacerlo
	RETURN NULL;	
END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS tg_modified_medication_given ON erp.tb_medication_given;
CREATE TRIGGER tg_modified_medication_given
  AFTER INSERT OR DELETE ON erp.tb_medication_given
  FOR EACH ROW
  EXECUTE PROCEDURE erp.fn_modified_medication_given();
  
  

