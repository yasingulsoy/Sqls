select id, u.clinic_id ,u.doctor_branch_code ,u.allowed_clinics ,CONCAT(u.first_name ,' ',u.last_name ) as DoktorAdi from users u
    where u.user_type = 1
        and u.isDeleted = 0
        and u.is_active =1
        and u.doctor_branch_code > 0
order by id ASC