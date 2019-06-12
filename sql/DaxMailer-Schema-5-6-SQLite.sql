-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-SQLite.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-6-SQLite.sql':;

BEGIN;

CREATE TABLE "subscriber_mailtrain" (
  "email_address" text NOT NULL,
  "operation" text NOT NULL,
  "updated" timestamptz NOT NULL,
  "created" timestamptz NOT NULL,
  "processed" int NOT NULL DEFAULT 0,
  PRIMARY KEY ("email_address", "operation")
);


COMMIT;

