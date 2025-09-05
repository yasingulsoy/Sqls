SELECT
  p.id AS patient_id,
  date(p.saved_on) as saved_on,
  REPLACE(c.clinic_name, 'Hospitadent ', '') AS clinic_name,
  
  /* Kimlik (TC) ve Pasaport var/yok */
  CASE
    WHEN TRIM(COALESCE(p.tc_no, '')) <> '' THEN 'Var'
    ELSE 'Yok'
  END AS tc_no,
  
  CASE
    WHEN TRIM(COALESCE(p.passport_no, '')) <> '' THEN 'Var'
    ELSE 'Yok'
  END AS pasaport_no,
  
  /* İkisinden herhangi biri varsa */
  CASE
    WHEN TRIM(COALESCE(p.tc_no, '')) <> ''
      OR TRIM(COALESCE(p.passport_no, '')) <> '' THEN 'Var'
    ELSE 'Yok'
  END AS kimlik_veya_pasaport_no,
  
  /* KVKK / Kampanya / Bilgilendirme onayları */
  CASE WHEN p.kvkk_status = 1 THEN 'Var' ELSE 'Yok' END AS kvkk_onayi,
  CASE WHEN p.campaigns = 1 THEN 'Var' ELSE 'Yok' END AS kampanya_onayi,
  CASE WHEN p.notifications = 1 THEN 'Var' ELSE 'Yok' END AS bilgilendirme_onayi,
  
  /* İkamet ülkesi (adres) */
  p.p_country AS address_country_id,
  COALESCE(c_addr.country_name, 'Bilinmiyor') AS adres_ulkesi,
  
  /* Uyruk (citizenship) */
  p.nationality AS nationality_country_id,
  COALESCE(c_nat.country_name, 'Bilinmiyor') AS uyruk_ulkesi,
  
  /* Vatandaşlık türü (Yurt içi/dışı × Türk/Yabancı) */
  p.nationality_type AS nationality_type_id,
  COALESCE(nt.type_name, 'Bilinmiyor') AS vatandaslik_turu,
  
  /* Anlaşmalı kurum (hastanın güncel kurumu) */
  p.partnership_companies AS corporate_id,
  COALESCE(pc.pc_name, '') AS kurum_adi,
  pc.company_type,
  CASE
    WHEN pc.company_type = 1 THEN 'Yurtiçi Kurum'
    WHEN pc.company_type = 2 THEN 'Yurtdışı Kurum'
    WHEN pc.company_type IS NULL THEN 'Kurum Yok'
    ELSE CONCAT('Diğer (', pc.company_type, ')')
  END AS kurum_tipi,
  
  /* Geliş şekli */
  p.hdyhau AS hdyhau_id,
  COALESCE(h.hdyhau_name, CONCAT('Kod ', p.hdyhau)) AS gelis_sekli,
  
  /* Demografi */
  p.gender AS gender_code,
  CASE
    WHEN p.gender = 1 THEN 'Erkek'
    WHEN p.gender = 2 THEN 'Kadın'
    ELSE 'Belirtilmemiş'
  END AS cinsiyet,
  CASE
    WHEN p.birthday IS NULL OR p.birthday = '0000-00-00' THEN 'Bilinmiyor'
    ELSE p.birthday
  END AS dogum_tarihi,
  
  /* Yaş (yıl) – asof_date verilmişse ona göre, yoksa bugüne göre */
  CASE
    WHEN p.birthday IS NULL OR p.birthday = '0000-00-00' THEN 'Bilinmiyor'
    ELSE TIMESTAMPDIFF(YEAR,p.birthday,CURDATE())
  END AS yas,
  
  /* Yaş aralıgı */
  CASE
    WHEN p.birthday IS NULL OR p.birthday = '0000-00-00' THEN 'Bilinmiyor'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) < 13 THEN '0–12'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 13 AND 17 THEN '13–17'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 18 AND 24 THEN '18–24'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 25 AND 34 THEN '25–34'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 35 AND 44 THEN '35–44'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 45 AND 54 THEN '45–54'
    WHEN TIMESTAMPDIFF(YEAR, p.birthday, CURDATE()) BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS yas_araligi
FROM patients p
LEFT JOIN clinics c ON c.id = p.clinic_id
LEFT JOIN partnership_companies pc ON pc.id = p.partnership_companies
LEFT JOIN hdyhau h ON h.id = p.hdyhau
LEFT JOIN countries c_addr ON c_addr.id = p.p_country       -- ikamet ülkesi
LEFT JOIN countries c_nat ON c_nat.id = p.nationality     -- uyruk ülkesi
LEFT JOIN nationality_types nt ON nt.id = p.nationality_type
WHERE p.isDeleted = 0
AND (:has_start_date = 0 OR DATE(p.saved_on) >= :start_date)
AND (:has_end_date   = 0 OR DATE(p.saved_on) <= :end_date)
AND (:has_clinic_id  = 0 OR p.clinic_id IN (:clinic_id))