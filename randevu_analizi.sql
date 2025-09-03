SELECT 
    a.id, 
    a.clinic_id as sube_id,
    c.clinic_name as sube_adi, 
    YEAR(a.start_date) AS yil, 
    MONTH(a.start_date) AS ay, 
    psc.id as ak_id,
    psc.pc_name as ak_adi, 
    psc.company_type as ak_tipi_id,
    CASE
        WHEN psc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN psc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN psc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
    END AS ak_tipi_adi,  
    a.appointment_status as randevu_durum_id,  
    ass.status_name as randevu_durum_adi, 
    u.id as kayit_yapan_id,
    CONCAT(u.first_name, ' ', u.last_name) AS kayit_yapan_adi, 
    a.doctor_id as randevu_hekim_id, 
    CONCAT(usr.first_name, ' ', usr.last_name) AS randevu_hekim_adi,  
    a.patient_id, 
    a.appointment_type as randevu_tip_id, 
    att.type_name as randevu_tipi_adi, 
    a.treatment_type as tedavi_tipi_id, 
    tt.treatment_type_name as tedavi_tipi_adi, 
    a.start_date as randevu_baslama_zamani, 
    a.end_date as randevu_bitis_zamani, 
    a.saved_on as kayit_tarihi,
    a.is_confirmed as onaylandi_mi, 
    a.status as durum,
    dbc.id as hekim_brans_id,
    dbc.branch_name AS hekim_brans,
    nt.id as vatandaslik_tipi_id,
    nt.type_name AS vatandaslik_tipi,
    h.id as gelis_sekli_id,
    h.hdyhau_name as gelis_sekli_adi
FROM appointments a
LEFT JOIN users u ON a.saved_by = u.id
LEFT JOIN clinics c ON a.clinic_id = c.id
LEFT JOIN appointment_types att ON a.appointment_type = att.id
LEFT JOIN appointment_status ass ON a.appointment_status = ass.id
LEFT JOIN treatment_types tt ON a.treatment_type = tt.id
LEFT JOIN patients p ON a.patient_id = p.id 
LEFT JOIN partnership_companies psc ON p.partnership_companies = psc.id
LEFT JOIN users usr ON a.doctor_id = usr.id
LEFT JOIN doctor_branch_codes dbc ON dbc.id = usr.doctor_branch_code
LEFT JOIN nationality_types nt ON nt.id = p.nationality_type
LEFT JOIN hdyhau h ON h.id = p.hdyhau
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
  AND (:has_doctor_branch_code     = 0 OR dbc.id IN (:doctor_branch_code))
  AND (:has_nationality_types_id   = 0 OR p.nationality_type IN (:nationality_types_id))
  AND (:has_hdyhau_id              = 0 OR h.id IN (:hdyhau_id))
  AND (:has_user_id = 0 OR u.id IN (:user_id))
