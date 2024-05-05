  ------------------------------------------------------------------------------------------------
  --
  -- Create database
  --
  ------------------------------------------------------------------------------------------------
  
  -- CREATE DATABASE dbdw_pec2;
 
  ------------------------------------------------------------------------------------------------
  --
  -- Drop tables
  --
  ------------------------------------------------------------------------------------------------
  DROP TABLE IF EXISTS erp.tb_medication_plan_detail;
  DROP TABLE IF EXISTS erp.tb_medication_plan;
  DROP TABLE IF EXISTS erp.tb_medication;  
  DROP TABLE IF EXISTS erp.tb_medication_category;
  DROP TABLE IF EXISTS erp.tb_patient;
  DROP TABLE IF EXISTS erp.tb_patient_room;

  ------------------------------------------------------------------------------------------------
  --
  -- Drop schema
  --
  ------------------------------------------------------------------------------------------------
  DROP SCHEMA IF EXISTS erp;

  ------------------------------------------------------------------------------------------------
  --
  -- Create schema
  --
  ------------------------------------------------------------------------------------------------
  
  CREATE SCHEMA erp;

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_patient_room
  --
  ------------------------------------------------------------------------------------------------
  
  CREATE TABLE erp.tb_patient_room  (
    patr_id				    INT NOT NULL,
    patr_name          		CHARACTER VARYING(50) NOT NULL,
    patr_parent_id			INT,
    CONSTRAINT pk_patient_room PRIMARY KEY (patr_id),
    CONSTRAINT fk_patient_room_parent FOREIGN KEY (patr_parent_id) REFERENCES erp.tb_patient_room (patr_id)  
  );
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_patient
  --
  ------------------------------------------------------------------------------------------------
  
  CREATE TABLE erp.tb_patient  (
    pat_id				    INT NOT NULL,
    pat_name          		CHARACTER VARYING(50) NOT NULL,
    pat_gender      		CHARACTER(1) NOT NULL,
    pat_date_birth			DATE NOT NULL,
    pat_admission_date		DATE NOT NULL DEFAULT current_date,
    pat_discharge_date		DATE,
    patr_id				    INT NOT NULL,
    pat_mutuality			CHARACTER VARYING(20),
    CONSTRAINT valid_gender CHECK (pat_gender IN ('H','M')),
    CONSTRAINT pk_patient PRIMARY KEY (pat_id),
    CONSTRAINT fk_patient_room FOREIGN KEY (patr_id) REFERENCES erp.tb_patient_room (patr_id)    
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication_category
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_medication_category  (
    medcat_id				CHARACTER(3) NOT NULL,
    medcat_name          	CHARACTER VARYING(20) NOT NULL,	
    CONSTRAINT pk_medication_category PRIMARY KEY (medcat_id),
    CONSTRAINT u_medcat_name  UNIQUE (medcat_name)    
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_medication  (
	med_id				    INT NOT NULL,
	med_name			    CHARACTER VARYING(20) NOT NULL,
	medcat_id			    CHARACTER(3) NOT NULL,
	med_box_units			INT NOT NULL,
	med_box_price			NUMERIC(10,2),    
	med_form			    CHARACTER(10) NOT NULL,
    med_stock_units			INT NOT NULL DEFAULT 0,
    med_stock_min			INT NOT NULL DEFAULT 10,
    CONSTRAINT valid_stock_min CHECK (med_stock_min > 0),
    CONSTRAINT pk_medication PRIMARY KEY (med_id),
	CONSTRAINT fk_medication_category FOREIGN KEY (medcat_id) REFERENCES erp.tb_medication_category (medcat_id)
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication_plan
  --
  ------------------------------------------------------------------------------------------------
 
  CREATE TABLE erp.tb_medication_plan  (
	medplan_id			    INT NOT NULL,
	pat_id				    INT NOT NULL,
	medplan_creation_date	DATE NOT NULL DEFAULT current_date,
	medplan_update_date		TIMESTAMP,
	medplan_doctor			CHARACTER VARYING(20) NOT NULL,
	CONSTRAINT pk_medication_plan PRIMARY KEY (medplan_id),
	CONSTRAINT fk_medication_plan_patient FOREIGN KEY (pat_id) REFERENCES erp.tb_patient (pat_id)
  );


  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_medication_plan_detail
  --
  ------------------------------------------------------------------------------------------------
 
  CREATE TABLE erp.tb_medication_plan_detail  (
    medplan_detail_id       INT NOT NULL,
	medplan_id			    INT NOT NULL,
    med_id				    INT NOT NULL,
 	medplan_detail_units	INT NOT NULL DEFAULT 0,
 	CONSTRAINT pk_medication_plan_detail PRIMARY KEY (medplan_detail_id),
	CONSTRAINT fk_medication_plan FOREIGN KEY (medplan_id) REFERENCES erp.tb_medication_plan (medplan_id),
        CONSTRAINT fk_medication      FOREIGN KEY (med_id) REFERENCES erp.tb_medication (med_id)
  );
