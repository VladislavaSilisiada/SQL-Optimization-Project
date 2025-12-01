WITH email_data AS (
    SELECT
        es.id_account,
        es.id_message,
        eo.id_message AS open_msg,
        ev.id_message AS visit_msg
    FROM `DA.email_sent` es
    LEFT JOIN `DA.email_open` eo ON es.id_message = eo.id_message
    LEFT JOIN `DA.email_visit` ev ON es.id_message = ev.id_message
)
SELECT
    sp.operating_system,
    COUNT(DISTINCT ed.id_message) AS sent_msg,
    COUNT(DISTINCT ed.open_msg) AS open_msg,
    COUNT(DISTINCT ed.visit_msg) AS vist_msg,
    COUNT(DISTINCT ed.open_msg) * 100 / COUNT(DISTINCT ed.id_message) AS open_rate,
    COUNT(DISTINCT ed.visit_msg) * 100 / COUNT(DISTINCT ed.id_message) AS click_rate,
    COUNT(DISTINCT ed.visit_msg) * 100 / COUNT(DISTINCT ed.open_msg) AS ctor
FROM email_data ed
JOIN `DA.account` a ON ed.id_account = a.id
JOIN `DA.account_session` acs ON a.id = acs.account_id
JOIN `DA.session_params` sp ON acs.ga_session_id = sp.ga_session_id
WHERE a.is_unsubscribed = 0
GROUP BY sp.operating_system;
