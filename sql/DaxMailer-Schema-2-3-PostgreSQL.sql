-- Convert schema '/home/ddgc/DaxMailer3/bin/../sql/DaxMailer-Schema-2-PostgreSQL.sql' to '/home/ddgc/DaxMailer3/bin/../sql/DaxMailer-Schema-3-PostgreSQL.sql':;

BEGIN;

ALTER TABLE subscriber_bounce ADD COLUMN unsubscribed integer DEFAULT 0 NOT NULL;


COMMIT;

