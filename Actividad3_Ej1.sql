------------------------------------------------------------------------------------------------
-- Ejercicio 1 a)
------------------------------------------------------------------------------------------------

SELECT
  sign_id,
  employee_id,
  sign_term_in,
  sign_data_in,
  sign_term_out,
  LEAD(sign_id) OVER (PARTITION BY employee_id, sign_term_out ORDER BY sign_id) AS next_sign_id
FROM
  erp.tb_sign_employees;

------------------------------------------------------------------------------------------------
-- Ejercicio 1 b)
------------------------------------------------------------------------------------------------

WITH RECURSIVE sign_history AS (
  SELECT
    sign_id,
    employee_id,
    sign_term_in || '-' AS history,
    next_sign_id
  FROM erp.tb_sign_next
  WHERE employee_id = 15
    AND sign_id = 15
  UNION ALL
  SELECT
    t.sign_id,
    t.employee_id,
    sh.history || t.sign_term_in || '-' AS history,
    t.next_sign_id
  FROM erp.tb_sign_next AS t
  INNER JOIN sign_history AS sh ON t.sign_id = sh.next_sign_id
)
SELECT employee_id, rtrim(history, '-') AS history
FROM sign_history;

------------------------------------------------------------------------------------------------
-- Ejercicio 1 c)
------------------------------------------------------------------------------------------------
  
WITH RECURSIVE employee_history AS (
  SELECT
    sign_id,
	employee_id,
    sign_term_in,
    sign_term_out,
    1 AS level
  FROM
    erp.tb_sign_employees
  WHERE
    sign_term_in IS NOT NULL
  UNION ALL
  SELECT
    se.sign_id,
	se.employee_id,
    se.sign_term_in,
    se.sign_term_out,
    eh.level + 1
  FROM
    erp.tb_sign_employees se
    INNER JOIN employee_history eh ON se.employee_id = eh.employee_id
  WHERE
    eh.level = eh.level + 1
)
SELECT
  employee_id,
  STRING_AGG(sign_term_in, '-' ORDER BY sign_id) AS history
FROM
  employee_history
GROUP BY
  employee_id;




