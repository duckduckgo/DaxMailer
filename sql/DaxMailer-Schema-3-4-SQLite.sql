-- Convert schema '/home/ddgc/DaxMailer4/bin/../sql/DaxMailer-Schema-3-SQLite.sql' to '/home/ddgc/DaxMailer4/bin/../sql/DaxMailer-Schema-4-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE "subscriber_maillog_temp_alter" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "email_id" text NOT NULL,
  "sent" timestamptz NOT NULL,
  PRIMARY KEY ("email_address", "campaign", "email_id"),
  FOREIGN KEY ("email_address", "campaign") REFERENCES "subscriber"("email_address", "campaign") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "subscriber_maillog_temp_alter"( "email_address", "campaign", "email_id", "sent") SELECT "email_address", "campaign", "email_id", "sent" FROM "subscriber_maillog";

DROP TABLE "subscriber_maillog";

CREATE TABLE "subscriber_maillog" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "email_id" text NOT NULL,
  "sent" timestamptz NOT NULL,
  PRIMARY KEY ("email_address", "campaign", "email_id"),
  FOREIGN KEY ("email_address", "campaign") REFERENCES "subscriber"("email_address", "campaign") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "subscriber_maillog_idx_emai00" ON "subscriber_maillog" ("email_address", "campaign");

INSERT INTO "subscriber_maillog" SELECT "email_address", "campaign", "email_id", "sent" FROM "subscriber_maillog_temp_alter";

DROP TABLE "subscriber_maillog_temp_alter";


COMMIT;

