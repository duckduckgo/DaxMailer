-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-4-SQLite.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE "bang_temp_alter" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "command" text NOT NULL,
  "url" text NOT NULL,
  "email_address" text,
  "comments" text,
  "example_search" text DEFAULT 'hello',
  "site_name" text NOT NULL,
  "category_id" integer NOT NULL,
  "note" text,
  "moderated" integer NOT NULL DEFAULT 0,
  "created" timestamptz NOT NULL DEFAULT '2019-01-01',
  FOREIGN KEY ("category_id") REFERENCES "bang_category"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "bang_temp_alter"( "command", "url", "email_address", "comments", "site_name", "category_id", "moderated") SELECT "command", "url", "email_address", "comments", "site_name", "category_id", "moderated" FROM "bang";

DROP TABLE "bang";

CREATE TABLE "bang" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "command" text NOT NULL,
  "url" text NOT NULL,
  "email_address" text,
  "comments" text,
  "example_search" text DEFAULT 'hello',
  "site_name" text NOT NULL,
  "category_id" integer NOT NULL,
  "note" text,
  "moderated" integer NOT NULL DEFAULT 0,
  "created" timestamptz NOT NULL DEFAULT '2019-01-01',
  FOREIGN KEY ("category_id") REFERENCES "bang_category"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "bang_idx_category_id03" ON "bang" ("category_id");

INSERT INTO "bang" SELECT "id", "command", "url", "email_address", "comments", "example_search", "site_name", "category_id", "note", "moderated", "created" FROM "bang_temp_alter";

DROP TABLE "bang_temp_alter";


COMMIT;

