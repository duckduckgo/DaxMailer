-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-PostgreSQL.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-6-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "subscriber_mailtrain" (
  "email_address" text NOT NULL,
  "operation" text NOT NULL,
  "updated" timestamp NOT NULL,
  "created" timestamp NOT NULL,
  "processed" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("email_address", "operation")
);


COMMIT;

