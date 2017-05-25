-- Convert schema '/home/ddgc/DaxMailer4/bin/../sql/DaxMailer-Schema-3-PostgreSQL.sql' to '/home/ddgc/DaxMailer4/bin/../sql/DaxMailer-Schema-4-PostgreSQL.sql':;

BEGIN;

ALTER TABLE subscriber_maillog ALTER COLUMN email_id TYPE text;


COMMIT;

