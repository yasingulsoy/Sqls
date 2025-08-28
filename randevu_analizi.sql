SELECT 
    a.id, 
    a.clinic_id,
    c.clinic_name, 
    YEAR(a.start_date) AS yil, 
    MONTH(a.start_date) AS ay, 
    psc.id AS partnership_companies,
    psc.pc_name, 
    psc.company_type,
    CASE
        WHEN psc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN psc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN psc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
    END AS company_type_text,  
    a.appointment_status,  
    ass.status_name, 
    CONCAT(u.first_name, ' ', u.last_name) AS savedByFullName, 
    a.doctor_id, 
    CONCAT(usr.first_name, ' ', usr.last_name) AS DoctorName,  
    a.patient_id, 
    a.appointment_type, 
    att.type_name, 
    a.treatment_type, 
    tt.treatment_type_name, 
    a.start_date, 
    a.end_date, 
    a.saved_on,
    a.is_confirmed, 
    a.status
FROM appointments a
LEFT JOIN users u ON a.saved_by = u.id
LEFT JOIN clinics c ON a.clinic_id = c.id
LEFT JOIN appointment_types att ON a.appointment_type = att.id
LEFT JOIN appointment_status ass ON a.appointment_status = ass.id
LEFT JOIN treatment_types tt ON a.treatment_type = tt.id
LEFT JOIN patients p ON a.patient_id = p.id 
LEFT JOIN partnership_companies psc ON p.partnership_companies = psc.id
LEFT JOIN users usr ON a.doctor_id = usr.id
WHERE a.deleted_by = 0
  AND (att.id = 1 OR att.id = 2)  -- new patient, clinic patient
  AND (:has_start_date = 0 OR DATE(a.start_date) >= :start_date)
  AND (:has_end_date   = 0 OR DATE(a.start_date) <= :end_date)
  AND (:has_clinic_id  = 0 OR a.clinic_id IN (:clinic_id))
  AND (:has_partnership_company_id = 0 OR p.partnership_companies IN (:partnership_company_id))
  AND (:has_company_type = 0 
  OR psc.company_type IN (:company_type) 
  OR (psc.company_type IS NULL AND 'null' IN (:company_type)))
  AND (:has_appointment_status = 0 OR a.appointment_status IN (:appointment_status))
  AND (:has_doctor_id = 0 OR a.doctor_id IN (:doctor_id))
  AND (:has_appointment_type = 0 OR a.appointment_type IN (:appointment_type))
  AND (:has_treatment_type = 0 OR a.treatment_type IN (:treatment_type))
  AND (:has_is_confirmed = 0 OR a.is_confirmed IN (:is_confirmed));
