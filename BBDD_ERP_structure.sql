  ------------------------------------------------------------------------------------------------
  --
  -- Create database
  --
  ------------------------------------------------------------------------------------------------
  
  -- CREATE DATABASE pec2;
 
  ------------------------------------------------------------------------------------------------
  --
  -- Drop tables
  --
  ------------------------------------------------------------------------------------------------
  DROP TABLE IF EXISTS erp.tb_sign_employees;
  DROP TABLE IF EXISTS erp.tb_terminals;
  DROP TABLE IF EXISTS erp.tb_employee;
  DROP TABLE IF EXISTS erp.tb_category;
  DROP TABLE IF EXISTS erp.tb_production_lin;  
  DROP TABLE IF EXISTS erp.tb_production_cab;
  DROP TABLE IF EXISTS erp.tb_products;

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
  -- Create table tb_category
  --
  ------------------------------------------------------------------------------------------------
  
  CREATE TABLE erp.tb_category  (
    category_id				INT NOT NULL,
    category_name          		CHARACTER(30) NOT NULL,
    category_extra_price      		INT NOT NULL,
    CONSTRAINT pk_category PRIMARY KEY (category_id),
    CONSTRAINT u_category_name  UNIQUE (category_name)  
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_employee
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_employee  (
    employee_id				INT NOT NULL,
    employee_name          		CHARACTER(20) NOT NULL,
    employee_surname       		CHARACTER VARYING(50) NOT NULL,
    category_id  			INT NOT NULL,
    employee_hiredate			DATE NOT NULL DEFAULT current_date,
    employee_birthdate			DATE NOT NULL,
    employee_gender			CHARACTER(10) NOT NULL,
    employee_boss			INT,
    employee_shift			CHARACTER(1),	
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_employee FOREIGN KEY (employee_boss) REFERENCES erp.tb_employee (employee_id),
    CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES erp.tb_category (category_id)    
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_terminals
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_terminals  (
	terminal_id				CHARACTER(3) NOT NULL,
	terminal_name				CHARACTER VARYING(20) NOT NULL,
	CONSTRAINT pk_terminals PRIMARY KEY (terminal_id)
  );


  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_sign_employees
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_sign_employees  (
	sign_id					INT NOT NULL,
	employee_id				INT NOT NULL,
	sign_term_in				CHARACTER(3) NOT NULL,
	sign_data_in				TIMESTAMP NOT NULL,
	sign_term_out				CHARACTER(3),
	sign_data_out				TIMESTAMP,
    	sign_time_minutes			INT,
	CONSTRAINT pk_sign_employees PRIMARY KEY (sign_id),
	CONSTRAINT fk_employees FOREIGN KEY (employee_id) REFERENCES erp.tb_employee (employee_id),
	CONSTRAINT fk_terminals_in FOREIGN KEY (sign_term_in) REFERENCES erp.tb_terminals (terminal_id),
	CONSTRAINT fk_terminals_out FOREIGN KEY (sign_term_out) REFERENCES erp.tb_terminals (terminal_id)
   );		


  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_products
  --
  ------------------------------------------------------------------------------------------------

  CREATE TABLE erp.tb_products  (
	products_id				CHARACTER(5) NOT NULL,
	products_name				CHARACTER VARYING(50) NOT NULL,
	products_size				INT NOT NULL,
     products_cost				NUMERIC(12,2),
     CONSTRAINT pk_products PRIMARY KEY (products_id)
   );		

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_production_cab
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_production_cab  (
	production_cab_id			INT NOT NULL,
	production_date				date,
	production_shift			CHARACTER(1) NOT NULL,
     CONSTRAINT pk_production_cab PRIMARY KEY (production_cab_id)
   );	

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_production_lin
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_production_lin  (
	production_lin_id			INT NOT NULL,
	production_cab_id			INT NOT NULL,
	products_id				CHARACTER(5) NOT NULL,
	production_lin_quantity 		INT NOT NULL,
     CONSTRAINT pk_production_lin PRIMARY KEY (production_lin_id),
	CONSTRAINT fk_production_cab FOREIGN KEY (production_cab_id) REFERENCES erp.tb_production_cab (production_cab_id),
	CONSTRAINT fk_products FOREIGN KEY (products_id) REFERENCES erp.tb_products (products_id)
   );		
	 