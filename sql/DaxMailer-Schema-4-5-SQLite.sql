-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-4-SQLite.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-SQLite.sql':;

BEGIN;

ALTER TABLE "bang" ADD COLUMN "example_search" text DEFAULT 'hello';


COMMIT;

