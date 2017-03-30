-- Convert schema '/home/ddgc/DaxMailer2/bin/../sql/DaxMailer-Schema-1-PostgreSQL.sql' to '/home/ddgc/DaxMailer2/bin/../sql/DaxMailer-Schema-2-PostgreSQL.sql':;

BEGIN;

ALTER TABLE subscriber ADD COLUMN extra text DEFAULT '{}' NOT NULL;


COMMIT;

