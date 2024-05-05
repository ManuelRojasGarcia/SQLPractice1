---- Select de las tablas para comprobar datos.

--select * from erp.tb_medication_plan
--select * from erp.tb_patient_room
--select * from erp.tb_patient
--select * from erp.tb_medication_plan_detail
--select * from erp.tb_medication


--------------------------------------------------------------------------------------------
-- Ejercicio A
-- Se pide, mediante el uso de CTE, obtener dos métricas: el número de pacientes ingresados en la cama A,
-- y el número de pacientes ingresados en la cama B. Ambas métricas únicamente deben tener en cuenta las camas del piso 3.
--------------------------------------------------------------------------------------------

--- Realizo un esquema para ver los niveles, es decir, nivel 1 la clinica, 2 plantas, 3 habitaciones y 4 camas

WITH RECURSIVE esquema AS (
  SELECT patr_id, patr_name, patr_parent_id, 1 as level
  FROM erp.tb_patient_room
  WHERE patr_parent_id IS NULL -- 

  UNION

  SELECT pr.patr_id, pr.patr_name, pr.patr_parent_id, ph.level + 1
  FROM erp.tb_patient_room pr
  JOIN Esquema ph ON pr.patr_parent_id = ph.patr_id
)
SELECT * FROM Esquema;

--- Métricas de pacientes en Cama A y cama B de la planta 3.

WITH RECURSIVE Metricas AS (
    SELECT patr_id, patr_name, patr_parent_id
    FROM erp.tb_patient_room
    WHERE patr_parent_id = 3 
    
    UNION
    
    SELECT pr.patr_id, pr.patr_name, pr.patr_parent_id
    FROM erp.tb_patient_room pr
    JOIN Metricas c ON pr.patr_parent_id = c.patr_id
)

SELECT
    (SELECT COUNT(*) FROM Metricas WHERE CAST(patr_name AS VARCHAR) = 'Bed A') AS NumeroCamas_A,
    (SELECT COUNT(*) FROM Metricas WHERE CAST(patr_name AS VARCHAR) = 'Bed B') AS NumeroCamas_B;


--------------------------------------------------------------------------------------------
-- Ejercicio B
--------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
-- 1 Nombre del médico asignado al plan.
-------------------------------------------------------------------------------------------------------------------------------

WITH MedicoPacientes AS (
  SELECT
    medplan_doctor AS nombre_medico,
    COUNT(DISTINCT medplan_id) AS num_pacientes,
    RANK() OVER (ORDER BY COUNT(DISTINCT medplan_id) DESC) AS ranking
  FROM
    erp.tb_medication_plan
  GROUP BY
    medplan_doctor
)

SELECT
  nombre_medico,
  medplan_id
FROM
  erp.tb_medication_plan
JOIN
  MedicoPacientes ON erp.tb_medication_plan.medplan_doctor = MedicoPacientes.nombre_medico
ORDER BY
  MedicoPacientes.num_pacientes DESC, MedicoPacientes.ranking, medplan_id;

-------------------------------------------------------------------------------------------------------------------------------
-- 2 El número de pacientes diferentes que cada médico trata.
-------------------------------------------------------------------------------------------------------------------------------

WITH MedicoPacientes AS (
  SELECT
    medplan_doctor AS nombre_medico,
    COUNT(DISTINCT medplan_id) AS num_pacientes,
    RANK() OVER (ORDER BY COUNT(DISTINCT medplan_id) DESC) AS ranking
  FROM
    erp.tb_medication_plan
  GROUP BY
    medplan_doctor
)

SELECT
  nombre_medico,
  num_pacientes
FROM
  MedicoPacientes
ORDER BY
  ranking;

-------------------------------------------------------------------------------------------------------------------------------
-- 3 El ranking de los médicos en base al número de pacientes que trata.
-------------------------------------------------------------------------------------------------------------------------------

WITH MedicoPacientes AS (
  SELECT
    medplan_doctor AS nombre_medico,
    pat_id,
    ROW_NUMBER() OVER (PARTITION BY medplan_doctor, pat_id ORDER BY medplan_id) AS row_num
  FROM
    erp.tb_medication_plan
)

SELECT
  nombre_medico,
  RANK() OVER (ORDER BY COUNT(DISTINCT pat_id) DESC) AS ranking
FROM
  MedicoPacientes
WHERE
  row_num = 1
GROUP BY
  nombre_medico
ORDER BY
  ranking;


-------------------------------------------------------------------------------------------------------------------------------
-- 4 La diferencia (en positivo) entre el número de pacientes del médico que se muestra en la fila y el médico que se encuentra(...)
-------------------------------------------------------------------------------------------------------------------------------

WITH MedicoPacientes AS (
  SELECT
    medplan_doctor AS nombre_medico,
    COUNT(DISTINCT pat_id) AS num_pacientes,
    LAG(COUNT(DISTINCT pat_id)) OVER (ORDER BY COUNT(DISTINCT pat_id) DESC) AS pacientes_anterior,
    RANK() OVER (ORDER BY COUNT(DISTINCT pat_id) DESC) AS ranking
  FROM
    erp.tb_medication_plan
  GROUP BY
    medplan_doctor
)

SELECT
  nombre_medico,
  num_pacientes,
  CASE
    WHEN pacientes_anterior IS NOT NULL
    THEN pacientes_anterior
    ELSE 0
  END AS pacientes_anterior,
  ABS(num_pacientes - CASE WHEN pacientes_anterior IS NOT NULL THEN pacientes_anterior ELSE 0 END) AS diferencia_pacientes_abs
FROM
  MedicoPacientes
ORDER BY
  ranking;

-------------------------------------------------------------------------------------------------------------------------------
-- 5 La media de las unidades prescritas de entre los planes de medicación que ha diseñado el médico (redondeada a tres dígitos decimales).
-------------------------------------------------------------------------------------------------------------------------------

WITH PlanesMedicacion AS (
  SELECT
    medplan_doctor AS nombre_medico,
    medplan_id
  FROM
    erp.tb_medication_plan
),

DetalleMedicacion AS (
  SELECT
    p.nombre_medico,
    p.medplan_id,
    mpd.med_id,
    mpd.medplan_detail_units
  FROM
    PlanesMedicacion p
    JOIN erp.tb_medication_plan_detail mpd ON p.medplan_id = mpd.medplan_id
)

SELECT
  nombre_medico,
  ROUND(AVG(medplan_detail_units)::numeric, 3) AS media_unidades_prescritas
FROM
  DetalleMedicacion
GROUP BY
  nombre_medico
ORDER BY
  COUNT(DISTINCT medplan_id) DESC;


-------------------------------------------------------------------------------------------------------------------------------
-- 6 La diferencia entre la media de las unidades prescritas (punto 5) del médico y la media máxima de las unidades prescritas de entre todos los médicos del resultado.
-------------------------------------------------------------------------------------------------------------------------------
-- No indicar valor absoluto y se deja la diferencia con positivo o negativo, sino con ABS lo solucionariamos como en el apartado 4

WITH PlanesMedicacion AS (
  SELECT
    medplan_doctor AS nombre_medico,
    medplan_id
  FROM
    erp.tb_medication_plan
),

DetalleMedicacion AS (
  SELECT
    p.nombre_medico,
    p.medplan_id,
    mpd.med_id,
    mpd.medplan_detail_units
  FROM
    PlanesMedicacion p
    JOIN erp.tb_medication_plan_detail mpd ON p.medplan_id = mpd.medplan_id
)

SELECT
  m.nombre_medico,
  m.media_unidades_prescritas,
  MAX(m.media_unidades_prescritas) OVER () AS max_media_unidades_prescritas,
  ROUND(m.media_unidades_prescritas - MAX(m.media_unidades_prescritas) OVER (), 3) AS diferencia
FROM (
  SELECT
    nombre_medico,
    ROUND(AVG(medplan_detail_units)::numeric, 3) AS media_unidades_prescritas,
    COUNT(DISTINCT medplan_id) AS num_pacientes
  FROM
    DetalleMedicacion
  GROUP BY
    nombre_medico
) m
ORDER BY
  m.num_pacientes DESC, m.nombre_medico;