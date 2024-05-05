------------------------------------------------------------------------------------------------
--
-- Consulta b) 
--
------------------------------------------------------------------------------------------------

SELECT pat_name AS patient_name_surname,
trim(substring(pat_name FROM position(',' IN pat_name)+1 FOR char_length(pat_name)-position(',' IN pat_name))) AS patient_name
FROM erp.tb_patient
WHERE trim(substring(pat_name FROM position(',' IN pat_name)+1 FOR char_length(pat_name)-position(',' IN pat_name))) LIKE 'J%'
ORDER BY patient_name ASC

