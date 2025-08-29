SELECT
    t.id,
    t.plan_date as plan_tarihi,
    pgct.id as tedavi_kategori_id,
    t.procedure_category_name as tedavi_kategori,
    pgs.id as tedavi_alt_kategori_id,
    pgs.subcat_name AS tedavi_alt_kategori,    
    t.procedure_name as tedavi,
    t.plan_teeth as dis_no,
    t.currency as para_birim_id,
	cur.exchange as para_birimi,
	t.rate as doviz_kuru,
    ROUND(t.unit_price * t.rate, 2) AS tedavi_toplam_tl,
    ROUND(t.unit_price, 2) AS tedavi_birim_fiyati,
    ROUND(t.total_price, 2) AS tedavi_toplam,
    ROUND(t.ins_discount_percentage, 2)  AS taksit_indirim_yuzde,
    ROUND(t.cc_discount_percentage, 2)   AS tekcekim_indirim_yuzde,
    ROUND(t.cash_discount_percentage, 2) AS nakit_indirim_yuzde,
    t.payment_distribution as odeme_dagitim,
    t.company_payment as kurum_odemesi_mi,
    date(t.saved_on) as kayit_tarihi,
    date(t.updated_on) as guncelleme_tarihi,
    t.is_refunded,
    t.is_rpt, 
    t.is_examination as muayene_mi,
    c.id as sube_id,
    c.clinic_name as sube_adi,
    TIMESTAMPDIFF(year, p.birthday, CURDATE()) AS hasta_yasi,
    p.id as hasta_id,
    concat(p.first_name, ' ', p.last_name)  as hasta_adi,
    pd.id as plani_yapan_hekim_id,
    CONCAT(pd.first_name, ' ', pd.last_name) AS plani_yapan_hekim,
    u.id AS tedavi_yapan_hekim_id, 
    CONCAT(u.first_name,  ' ', u.last_name )  AS tedavi_yapan_hekim,
    p.partnership_companies as ak_id,    
    pc.pc_name as ak_adi,
    pc.company_type as ak_tipi_id,
      CASE
        WHEN pc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN pc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN pc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
      END AS ak_tipi_adi,    
    nt.id as vatandaslik_tipi_id,
    nt.type_name AS vatandaslik_tipi,
    dbc.id as hekim_brans_id,
    dbc.branch_name AS hekim_brans,
    h.id as gelis_sekli_id,
    h.hdyhau_name as gelis_sekli_adi
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