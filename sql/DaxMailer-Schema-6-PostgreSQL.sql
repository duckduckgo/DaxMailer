-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed May  8 12:49:19 2019
-- 
--
-- Table: bang_category
--
DROP TABLE "bang_category" CASCADE;
CREATE TABLE "bang_category" (
  "id" serial NOT NULL,
  "live" integer DEFAULT 1 NOT NULL,
  "name" text NOT NULL,
  "parent" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "bang_category_idx_parent" on "bang_category" ("parent");

--
-- Table: subscriber
--
DROP TABLE "subscriber" CASCADE;
CREATE TABLE "subscriber" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "verified" integer DEFAULT 0 NOT NULL,
  "unsubscribed" integer DEFAULT 0 NOT NULL,
  "flow" text,
  "v_key" text NOT NULL,
  "u_key" text NOT NULL,
  "created" timestamptz NOT NULL,
  "extra" text DEFAULT '{}' NOT NULL,
  PRIMARY KEY ("email_address", "campaign")
);

--
-- Table: subscriber_bounce
--
DROP TABLE "subscriber_bounce" CASCADE;
CREATE TABLE "subscriber_bounce" (
  "email_address" text NOT NULL,
  "bounced" integer DEFAULT 0 NOT NULL,
  "complaint" integer DEFAULT 0 NOT NULL,
  "unsubscribed" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("email_address")
);

--
-- Table: subscriber_mailtrain
--
DROP TABLE "subscriber_mailtrain" CASCADE;
CREATE TABLE "subscriber_mailtrain" (
  "email_address" text NOT NULL,
  "operation" text NOT NULL,
  "updated" timestamptz NOT NULL,
  "created" timestamptz NOT NULL,
  "processed" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("email_address", "operation")
);

--
-- Table: bang
--
DROP TABLE "bang" CASCADE;
CREATE TABLE "bang" (
  "id" serial NOT NULL,
  "command" text NOT NULL,
  "url" text NOT NULL,
  "email_address" text,
  "comments" text,
  "example_search" text DEFAULT 'hello',
  "site_name" text NOT NULL,
  "category_id" integer NOT NULL,
  "note" text,
  "moderated" integer DEFAULT 0 NOT NULL,
  "created" timestamptz DEFAULT '2019-01-01' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "bang_idx_category_id" on "bang" ("category_id");

--
-- Table: subscriber_maillog
--
DROP TABLE "subscriber_maillog" CASCADE;
CREATE TABLE "subscriber_maillog" (
  "email_address" text NOT NULL,
  "campaign" text NOT NULL,
  "email_id" text NOT NULL,
  "sent" timestamptz NOT NULL,
  PRIMARY KEY ("email_address", "campaign", "email_id")
);
CREATE INDEX "subscriber_maillog_idx_email_address_campaign" on "subscriber_maillog" ("email_address", "campaign");

--
-- Foreign Key Definitions
--

ALTER TABLE "bang_category" ADD CONSTRAINT "bang_category_fk_parent" FOREIGN KEY ("parent")
  REFERENCES "bang_category" ("id") DEFERRABLE;

ALTER TABLE "bang" ADD CONSTRAINT "bang_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "bang_category" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "subscriber_maillog" ADD CONSTRAINT "subscriber_maillog_fk_email_address_campaign" FOREIGN KEY ("email_address", "campaign")
  REFERENCES "subscriber" ("email_address", "campaign") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

