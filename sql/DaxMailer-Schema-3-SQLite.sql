-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Apr 12 08:48:09 2017
-- 

BEGIN TRANSACTION;

--
-- Table: "bang_category"
--
DROP TABLE "bang_category";

CREATE TABLE "bang_category" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "live" int NOT NULL DEFAULT 1,
  "name" text NOT NULL,
  "parent" int,
  FOREIGN KEY ("parent") REFERENCES "bang_category"("id")
);

CREATE INDEX "bang_category_idx_parent" ON "bang_category" ("parent");

--
-- Table: "subscriber"
--
DROP TABLE "subscriber";

CREATE TABLE "subscriber" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "verified" int NOT NULL DEFAULT 0,
  "unsubscribed" int NOT NULL DEFAULT 0,
  "flow" text,
  "v_key" text NOT NULL,
  "u_key" text NOT NULL,
  "created" timestamptz NOT NULL,
  "extra" text NOT NULL DEFAULT '{}',
  PRIMARY KEY ("email_address", "campaign")
);

--
-- Table: "subscriber_bounce"
--
DROP TABLE "subscriber_bounce";

CREATE TABLE "subscriber_bounce" (
  "email_address" text NOT NULL,
  "bounced" int NOT NULL DEFAULT 0,
  "complaint" int NOT NULL DEFAULT 0,
  "unsubscribed" int NOT NULL DEFAULT 0,
  PRIMARY KEY ("email_address")
);

--
-- Table: "bang"
--
DROP TABLE "bang";

CREATE TABLE "bang" (
  "command" text NOT NULL,
  "url" text NOT NULL,
  "email_address" text,
  "comments" text,
  "site_name" text NOT NULL,
  "category_id" integer NOT NULL,
  "moderated" integer NOT NULL DEFAULT 0,
  PRIMARY KEY ("command", "url"),
  FOREIGN KEY ("category_id") REFERENCES "bang_category"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "bang_idx_category_id" ON "bang" ("category_id");

--
-- Table: "subscriber_maillog"
--
DROP TABLE "subscriber_maillog";

CREATE TABLE "subscriber_maillog" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "email_id" char(1) NOT NULL,
  "sent" timestamptz NOT NULL,
  PRIMARY KEY ("email_address", "campaign", "email_id"),
  FOREIGN KEY ("email_address", "campaign") REFERENCES "subscriber"("email_address", "campaign") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "subscriber_maillog_idx_email_address_campaign" ON "subscriber_maillog" ("email_address", "campaign");

COMMIT;
