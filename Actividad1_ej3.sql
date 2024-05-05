------------------------------------------------------------------------------------------------
--
-- a)
--
------------------------------------------------------------------------------------------------

insert into erp.tb_medication_category(medcat_id,medcat_name) VALUES ('M09','Antihistamínicos');

insert into erp.tb_medication (med_id,med_name,medcat_id,med_box_units,med_box_price,med_form) VALUES (117,'Zyrtec','M09',12,4.25,'Cápsula');

---Validamos
--- SELECT * FROM erp.tb_medication_category WHERE medcat_id in ('M09');
--- SELECT * FROM erp.tb_medication WHERE med_id=117;

------------------------------------------------------------------------------------------------
--
-- b)
--
------------------------------------------------------------------------------------------------

---Añadimos el campo
ALTER TABLE erp.tb_medication_category 
ADD COLUMN  medcat_discount NUMERIC(4,2) DEFAULT 0;

---Actualizamos
UPDATE erp.tb_medication_category 
SET medcat_discount=2
WHERE medcat_id IN ('M01','M05','M06','M09');

UPDATE erp.tb_medication_category 
SET medcat_discount=1.5
WHERE medcat_id IN ('M02','M03','M04','M07','M08');

---Validamos
--- SELECT * FROM erp.tb_medication_category

------------------------------------------------------------------------------------------------
--
-- c)
--
------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW erp.med_box_price AS
SELECT med_name,med_box_price,medcat_discount,ROUND(med_box_price-(med_box_price*medcat_discount)/100,2) AS medbox_price_discount
FROM erp.tb_medication AS me, erp.tb_medication_category AS mc
WHERE me.medcat_id=mc.medcat_id;
	
--Validamos
-- SELECT * FROM erp.med_box_price


------------------------------------------------------------------------------------------------
--
-- d)
--
------------------------------------------------------------------------------------------------

ALTER TABLE erp.tb_patient 
ADD CONSTRAINT check_discharge_date CHECK (pat_discharge_date IS NULL OR  pat_discharge_date >= pat_admission_date);


--Podemos verificar la condición con este test
-- UPDATE erp.tb_patient SET pat_discharge_date=pat_admission_date-1
-- WHERE pat_id=2
-- UPDATE erp.tb_patient SET pat_discharge_date=pat_admission_date
-- WHERE pat_id=2
-- UPDATE erp.tb_patient SET pat_discharge_date=pat_admission_date+1
-- WHERE pat_id=2
-- UPDATE erp.tb_patient SET pat_discharge_date=null
-- WHERE pat_id=2



------------------------------------------------------------------------------------------------
--
-- e)
--
------------------------------------------------------------------------------------------------
CREATE ROLE users_purchasing;                           -- Creamos el rol users_purchasing
GRANT USAGE ON SCHEMA erp TO users_purchasing;          -- Damos permiso de uso al esquema erp al rol creado
GRANT SELECT,INSERT,UPDATE,DELETE ON erp.tb_medication TO purchasing; -- Damos permiso de SELECT,INSERT,UPDATE,DELETE solamente sobre la tabla tb_medication
GRANT SELECT,INSERT,UPDATE ON erp.tb_medication_category TO purchasing;  -- Damos permiso de SELECT,INSERT,UPDATE solamente sobre la tabla tb_medication_category

CREATE USER mariona WITH LOGIN PASSWORD '1234';         -- Creamos el usuario con la contraseña indicada
ALTER USER mariona SET ROLE users_purchasing;           -- Asignamos al usuario al role users_purchasing
