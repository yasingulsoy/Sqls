SELECT 
    pay.id, 
    pay.patient_id, 
    pay.payment_date, 
    c.id AS clinicId, 
    c.clinic_name, 
    psc.id, 
    psc.pc_name, 
    psc.company_type,
    CASE
        WHEN psc.company_type = 1 THEN 'Yurtiçi Kurum'
        WHEN psc.company_type = 2 THEN 'Yurtdışı Kurum'
        WHEN psc.company_type IS NULL THEN 'Kurum Yok'
        ELSE NULL
    END AS company_type_text, 
    pay.is_payment, 
    pay.is_refund, 
    pay.is_account_closed, 
    pay.is_advance_payment, 
    pay.is_patient_payment, 
    pay.is_corporate_payment, 
    pay.corporate_id, 
    Truncate((pay.payment_amount * pay.rate), 2) AS payment_amount_tl, 
    pay.currency, 
    pay.rate, 
    pay.payment_amount,
    pay.payment_method, 
    pm.method_name AS payment_method_name, 
    pay.bank_id, 
    bnk.bank_name, 
    pay.pos_machine, 
    pos.pos_name,
    pay.is_distributed, 
    pay.is_refunded, 
    pay.invoice_id, 
    pay.invoice_amount, 
    pay.is_invoiced, 
    pay.payment_year
FROM payments pay 
LEFT JOIN clinics c ON pay.clinic_id = c.id
LEFT JOIN patients p ON pay.patient_id = p.id
LEFT JOIN partnership_companies psc ON p.partnership_companies = psc.id 
LEFT JOIN payment_methods pm ON pay.payment_method = pm.id
LEFT JOIN banks bnk ON pay.bank_id = bnk.id
LEFT JOIN pos_machines pos ON pay.pos_machine = pos.id
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