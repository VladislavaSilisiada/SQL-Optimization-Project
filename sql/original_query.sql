SELECT
    account_session.operating_system,
    COUNT(DISTINCT id_message_sent) AS sent_msg,
    COUNT(DISTINCT id_message_open) AS open_msg,
    COUNT(DISTINCT id_message_visit) AS vist_msg,
    COUNT(DISTINCT id_message_open) / COUNT(DISTINCT id_message_sent) * 100 AS open_rate,
    COUNT(DISTINCT id_message_visit) / COUNT(DISTINCT id_message_sent) * 100 AS click_rate,
    COUNT(DISTINCT id_message_visit) / COUNT(DISTINCT id_message_open) * 100 AS ctor
FROM
    `DA.account` a
JOIN (
    SELECT
        es.id_account AS id_account_sent,
        es.id_message AS id_message_sent,
        es.letter_type AS letter_type_sent,
        es.sent_date,
        eo.id_account AS id_account_open,
        eo.id_message AS id_message_open,
        eo.letter_type AS letter_type_open,
        eo.open_date,
        ev.id_account AS id_account_visit,
        ev.id_message AS id_message_visit,
        ev.letter_type AS letter_type_visit,
        ev.visit_date
    FROM
        `DA.email_sent` es
    LEFT JOIN (
        SELECT
            *
        FROM
            `DA.email_open` eo )eo
    ON
        es.id_message = eo.id_message
    LEFT JOIN (
        SELECT
            *
        FROM
            `DA.email_visit` ev )ev
    ON
        es.id_message = ev.id_message ) email_sent
ON
    a.id = email_sent.id_account_sent
JOIN (
    SELECT
        acs.account_id,
        acs.ga_session_id,
        sp.operating_system
    FROM
        `DA.account_session` acs
    JOIN
        `DA.session_params` sp
    ON
        acs.ga_session_id = sp.ga_session_id )account_session
ON
    a.id = account_session.account_id
WHERE
    a.is_unsubscribed = 0
GROUP BY
    account_session.operating_system;
