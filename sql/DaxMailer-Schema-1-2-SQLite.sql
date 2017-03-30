-- Convert schema '/home/ddgc/DaxMailer2/bin/../sql/DaxMailer-Schema-1-SQLite.sql' to '/home/ddgc/DaxMailer2/bin/../sql/DaxMailer-Schema-2-SQLite.sql':;

BEGIN;

ALTER TABLE "subscriber" ADD COLUMN "extra" text NOT NULL DEFAULT '{}';


COMMIT;

