SELECT
    t.id,
    t.plan_date,
    t.procedure_category_name,
    pgs.subcat_name AS procedure_subcat_name,    
    t.procedure_name,
    t.currency,
    ROUND(t.unit_price * t.rate, 2) AS treatment_amount_tl,
    ROUND(t.unit_price, 2) AS unit_price,
    ROUND(t.total_price, 2) AS total_price,
    ROUND(t.ins_discount_percentage, 2)  AS ins_discount_percentage,
    ROUND(t.cc_discount_percentage, 2)   AS cc_discount_percentage,
    ROUND(t.cash_discount_percentage, 2) AS cash_discount_percentage,
    t.payment_distribution,
    t.company_payment,
    date(t.saved_on) as saved_on,
    date(t.updated_on) as updated_on,
    c.id as clinicId,
    c.clinic_name,
    cur.exchange,
    TIMESTAMPDIFF(year, p.birthday, CURDATE()) AS patientAge,
    p.id as patientId,
    concat(p.first_name, ' ', p.last_name) as patientName,
    pd.id as planDoctorId,
    CONCAT(pd.first_name, ' ', pd.last_name) AS planDoctorFullname,
    u.id AS doctorId, 
    CONCAT(u.first_name,  ' ', u.last_name )  AS doctorFullname,
    p.partnership_companies,    
    pc.pc_name,
    pc.company_type,
      CASE
        WHEN pc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN pc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN pc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
      END AS company_type_text,    
    nt.id as patient_nationality_typeId,
    nt.type_name AS patient_nationality_type,
    dbc.id as doctorBranchId,
    dbc.branch_name AS doctorBranchname,
    h.id,
    h.hdyhau_name
FROM treatments t
JOIN patients p ON p.id = t.patient_id
JOIN users u ON u.id = t.doctor_id
LEFT JOIN users pd ON pd.id = t.plan_doctor
LEFT JOIN treatment_status ts ON ts.id = p.patient_treatment_status
LEFT JOIN price_group_category_treatments pgct ON pgct.id = t.procedure_id
LEFT JOIN price_group_subcategories pgs ON pgs.id = pgct.subcatid
LEFT JOIN clinics c ON c.id = t.clinic_id
LEFT JOIN currency cur ON cur.id = t.currency
LEFT JOIN partnership_companies pc ON pc.id = p.partnership_companies
LEFT JOIN nationality_types nt ON nt.id = p.nationality_type
LEFT JOIN doctor_branch_codes dbc ON dbc.id = u.doctor_branch_code
LEFT JOIN hdyhau h ON h.id = p.hdyhau
WHERE
    t.treatment_type = 3
    AND t.is_deleted = 0
    AND t.is_done = 1
    AND (:has_clinic_id = 0 OR t.clinic_id IN (:clinic_id))
    AND (:has_start_date = 0 OR t.updated_on >= :start_date)
    AND (:has_end_date   = 0 OR t.updated_on <= :end_date)
    AND (:has_doctor_id = 0 OR t.doctor_id IN (:doctor_id))
    AND (:has_partnership_company_id = 0 OR p.partnership_companies IN (:partnership_company_id))
    AND (:has_nationality_types_id   = 0 OR p.nationality_type IN (:nationality_types_id))
    AND (:has_doctor_branch_code     = 0 OR dbc.id IN (:doctor_branch_code))
    AND (:has_hdyhau_id              = 0 OR h.id IN (:hdyhau_id))
	AND (:has_company_type = 0 
  	OR pc.company_type IN (:company_type) 
  	OR (pc.company_type IS NULL AND 'null' IN (:company_type)))