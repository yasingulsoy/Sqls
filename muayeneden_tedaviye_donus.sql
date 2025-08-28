WITH t_norm AS (
  SELECT
    t.*,
    COALESCE(NULLIF(t.updated_on,'0000-00-00 00:00:00'), t.saved_on) AS service_ts
  FROM treatments t
  WHERE t.is_deleted = 0
),
exams AS (
  SELECT 
      e.id          AS exam_id,
      e.patient_id,
      e.clinic_id,
      e.doctor_id   AS exam_doctor_id,
      e.service_ts  AS exam_ts
  FROM t_norm e
  WHERE e.is_examination = 1
    AND e.is_done        = 1
    AND e.treatment_type = 3
    AND (:has_start_date = 0 OR e.service_ts >= :start_date)
    AND (:has_end_date   = 0 OR e.service_ts <  :end_date)
    AND (:has_clinic_id  = 0 OR e.clinic_id IN (:clinic_id))
),
followups AS (
  SELECT
      ex.exam_id,
      ex.exam_doctor_id,
      ex.clinic_id,
      t.id           AS treatment_id,
      t.service_ts   AS treat_ts,
      (t.unit_price * t.rate) AS tutar_tl
  FROM exams ex
  JOIN t_norm t
    ON t.is_examination = 0
   AND t.is_done        = 1
   AND t.treatment_type = 3
   AND t.patient_id     = ex.patient_id
   AND t.service_ts     > ex.exam_ts
   AND t.service_ts    <= ex.exam_ts + INTERVAL 30 DAY
),
exam_flags AS (
  SELECT
      ex.exam_id,
      ex.exam_doctor_id,
      ex.clinic_id,
      CASE WHEN COUNT(fu.treatment_id) > 0 THEN 1 ELSE 0 END AS converted_flag,
      COALESCE(SUM(fu.tutar_tl), 0) AS revenue_tl_30d,
      COUNT(fu.treatment_id) AS followup_treatments_count
  FROM exams ex
  LEFT JOIN followups fu ON fu.exam_id = ex.exam_id
  GROUP BY ex.exam_id, ex.exam_doctor_id, ex.clinic_id
)
SELECT
  u.id AS doctor_id,
  CONCAT(u.first_name, ' ', u.last_name) AS doctor_name,
  c.clinic_name,
  COUNT(*)                                            AS exam_count,
  SUM(converted_flag)                                 AS converted_exam_count,
  ROUND(100.0 * SUM(converted_flag) / NULLIF(COUNT(*),0), 2) AS conversion_rate_pct,
  SUM(followup_treatments_count)                      AS followup_treatments_30d,
  ROUND(SUM(revenue_tl_30d), 2)                       AS revenue_tl_30d_total,
  ROUND(SUM(revenue_tl_30d) / NULLIF(COUNT(*),0), 2)  AS revenue_tl_per_exam,
  ROUND(SUM(revenue_tl_30d) / NULLIF(SUM(converted_flag),0), 2) AS revenue_tl_per_converted_exam
FROM exam_flags ef
LEFT JOIN users   u ON u.id = ef.exam_doctor_id
LEFT JOIN clinics c ON c.id = ef.clinic_id
GROUP BY u.id, doctor_name, c.clinic_name
ORDER BY exam_count DESC, conversion_rate_pct DESC, revenue_tl_30d_total DESC;