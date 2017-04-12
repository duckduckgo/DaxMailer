-- Convert schema '/home/ddgc/DaxMailer3/bin/../sql/DaxMailer-Schema-2-SQLite.sql' to '/home/ddgc/DaxMailer3/bin/../sql/DaxMailer-Schema-3-SQLite.sql':;

BEGIN;

ALTER TABLE "subscriber_bounce" ADD COLUMN "unsubscribed" int NOT NULL DEFAULT 0;


COMMIT;

