-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-4-PostgreSQL.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-PostgreSQL.sql':;

BEGIN;

ALTER TABLE bang ADD COLUMN example_search text;


COMMIT;

