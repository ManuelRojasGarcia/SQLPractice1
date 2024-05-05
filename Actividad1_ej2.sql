------------------------------------------------------------------------------------------------
--
-- Consulta a) 
--
------------------------------------------------------------------------------------------------

SELECT med_name,med_form,med_stock_units
FROM erp.tb_medication
WHERE med_box_units >= 20 AND
med_form = 'Cápsula'
ORDER BY med_stock_units DESC


------------------------------------------------------------------------------------------------
--
-- Consulta b) 
--
------------------------------------------------------------------------------------------------

SELECT pt.pat_name,pt.pat_admission_date,mp.medplan_doctor
FROM erp.tb_patient AS pt, erp.tb_medication_plan AS mp
WHERE pt.pat_id=mp.pat_id AND
pt.pat_admission_date >= TO_DATE('05/10/2023','DD/MM/YYYY') AND
mp.medplan_doctor in ('Dra. Pérez','Dr. Garrido') and
pt.pat_name LIKE ('%JESUS%')
ORDER BY pt.pat_admission_date ASC

------------------------------------------------------------------------------------------------
--
-- Consulta c) 
--
------------------------------------------------------------------------------------------------

SELECT md.medplan_id,mc.medcat_name,me.med_name,md.medplan_detail_units
FROM erp.tb_medication_category AS mc,erp.tb_medication AS me,erp.tb_medication_plan_detail  AS md
WHERE mc.medcat_id = me.medcat_id AND
md.med_id=me.med_id AND
md.medplan_detail_units >= 2
ORDER BY mc.medcat_name ASC,me.med_name ASC

------------------------------------------------------------------------------------------------
--
-- Consulta d) 
--
------------------------------------------------------------------------------------------------

SELECT mc.medcat_name,SUM(md.med_stock_units) AS sum_stock_units,COUNT(*) AS number_medication, ROUND(AVG(md.med_box_price),2) AS average_box_price
FROM erp.tb_medication_category AS mc, erp.tb_medication AS md
WHERE md.medcat_id = mc.medcat_id AND
mc.medcat_id <> 'M99'
GROUP BY mc.medcat_name
HAVING SUM(md.med_stock_units) > 50
ORDER BY sum_stock_units DESC

------------------------------------------------------------------------------------------------
--
-- Consulta e) 
--
------------------------------------------------------------------------------------------------
SELECT pt.pat_name,pt.pat_mutuality,ROUND(SUM(md.medplan_detail_units*(me.med_box_price/me.med_box_units)),2) AS day_price
FROM erp.tb_patient AS pt, erp.tb_medication_plan_detail AS md, erp.tb_medication_plan AS mp, erp.tb_medication AS me
WHERE pt.pat_mutuality IS NOT NULL AND
mp.pat_id=pt.pat_id AND
mp.medplan_id=md.medplan_id AND
me.med_id = md.med_id
GROUP BY  pt.pat_name,pt.pat_mutuality
ORDER BY  day_price ASC
