DROP INDEX erp.idx_tb_patient_pat_id;
DROP INDEX erp.idx_tb_medication_plan_pat_id;

CREATE INDEX idx_tb_patient_pat_id ON erp.tb_patient(pat_id);
CREATE INDEX idx_tb_medication_plan_pat_id ON erp.tb_medication_plan(pat_id);

EXPLAIN ANALYZE
SELECT pt.pat_name
    , pt.pat_admission_date
    , mp.medplan_doctor
FROM erp.tb_patient AS pt
INNER JOIN erp.tb_medication_plan AS mp ON pt.pat_id = mp.pat_id
FORCE_INDEX (idx_tb_patient_pat_id)
WHERE pt.pat_admission_date >= TO_DATE('05/10/2023', 'DD/MM/YYYY')
    AND pt.pat_admission_date <= TO_DATE('08/10/2023', 'DD/MM/YYYY')
    AND (mp.medplan_doctor = 'Dra. Pérez' OR mp.medplan_doctor = 'Dr. Garrido')
    AND (pt.pat_name LIKE '%JE%' OR pt.pat_name LIKE '%AR%')
ORDER BY pt.pat_admission_date ASC;


