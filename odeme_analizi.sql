SELECT 
    pay.id, 
    pay.patient_id, 
    pay.payment_date as odeme_tarihi, 
    c.id AS sube_id, 
    c.clinic_name as sube_adi, 
    psc.id as ak_id,
    psc.pc_name as ak_adi, 
    psc.company_type as ak_tipi_id,
    CASE
        WHEN psc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN psc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN psc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
    END AS ak_tipi_adi, 
    pay.is_payment, 
    pay.is_refund, 
    pay.is_account_closed, 
    pay.is_advance_payment, 
    pay.is_patient_payment, 
    pay.is_corporate_payment, 
    pay.corporate_id, 
    round((pay.payment_amount * pay.rate), 2) AS odeme_miktari_tl, 
    pay.currency as para_birim_id, 
    pay.rate as doviz_kuru,
    pay.payment_amount as odeme_miktari,
    pay.payment_method as odeme_tipi_id, 
    pm.method_name AS odeme_tipi_adi, 
    pay.bank_id as banka_id, 
    bnk.bank_name as banka_adi, 
    pay.pos_machine as pos_id, 
    pos.pos_name as pos_adi,
    pay.is_distributed, 
    pay.is_refunded, 
    pay.invoice_id, 
    pay.invoice_amount, 
    pay.is_invoiced, 
    pay.payment_year as odeme_yili,
    nt.id as vatandaslik_tipi_id,
    nt.type_name AS vatandaslik_tipi,    
    h.id as gelis_sekli_id,
    h.hdyhau_name as gelis_sekli_adi,
    usv.id as hastayi_kayit_eden_id,
    CONCAT(usv.first_name, ' ', usv.last_name) AS hastayi_kayit_eden_adi,
    upay.id as odeme_kayit_eden_id,
    CONCAT(upay.first_name, ' ', upay.last_name) AS odeme_kayit_eden_adi    
FROM payments pay 
LEFT JOIN clinics c ON pay.clinic_id = c.id
LEFT JOIN patients p ON pay.patient_id = p.id
LEFT JOIN partnership_companies psc ON p.partnership_companies = psc.id 
LEFT JOIN payment_methods pm ON pay.payment_method = pm.id
LEFT JOIN banks bnk ON pay.bank_id = bnk.id
LEFT JOIN pos_machines pos ON pay.pos_machine = pos.id
LEFT JOIN nationality_types nt ON nt.id = p.nationality_type
LEFT JOIN hdyhau h ON h.id = p.hdyhau
LEFT JOIN users usv ON usv.id = p.saved_by 
LEFT JOIN users upay ON upay.id = pay.saved_by 
WHERE 
    pay.is_deleted = 0
    AND pay.is_refund = 0
    AND pay.is_refunded = 0
    AND (:has_clinic_id = 0 OR pay.clinic_id IN (:clinic_id))
    AND (:has_payment_method_id = 0 OR pay.payment_method IN (:payment_method_id))
	AND (:has_partnership_company_id = 0 OR p.partnership_companies IN (:partnership_company_id))
    AND (:has_start_date = 0 OR pay.payment_date >= :start_date)
    AND (:has_end_date   = 0 OR pay.payment_date <= :end_date)
    AND (:has_company_type = 0 
         OR psc.company_type IN (:company_type) 
         OR (psc.company_type IS NULL AND 'null' IN (:company_type)));
   AND (:has_nationality_types_id   = 0 OR p.nationality_type IN (:nationality_types_id))
   AND (:has_hdyhau_id              = 0 OR h.id IN (:hdyhau_id))   
   AND (:has_payment_saved_by_id = 0 OR pay.saved_by IN (:payment_saved_by_id))  -- Ödemeyi Kayıt eden user
   AND (:has_patient_saved_by_id = 0 OR p.saved_by IN (:patient_saved_by_id))  -- Hastayı Kayıt eden user  
