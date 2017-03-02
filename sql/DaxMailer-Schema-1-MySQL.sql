-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Mar  2 17:00:56 2017
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS bang_category;

--
-- Table: bang_category
--
CREATE TABLE bang_category (
  id integer NOT NULL auto_increment,
  live integer NOT NULL DEFAULT 1,
  name text NOT NULL,
  parent integer NULL,
  INDEX bang_category_idx_parent (parent),
  PRIMARY KEY (id),
  CONSTRAINT bang_category_fk_parent FOREIGN KEY (parent) REFERENCES bang_category (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS subscriber_bounce;

--
-- Table: subscriber_bounce
--
CREATE TABLE subscriber_bounce (
  email_address text NOT NULL,
  bounced integer NOT NULL DEFAULT 0,
  complaint integer NOT NULL DEFAULT 0,
  PRIMARY KEY (email_address)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS bang;

--
-- Table: bang
--
CREATE TABLE bang (
  command text NOT NULL,
  url text NOT NULL,
  email_address text NULL,
  comments text NULL,
  site_name text NOT NULL,
  category_id integer NOT NULL,
  moderated integer NOT NULL DEFAULT 0,
  INDEX bang_idx_category_id (category_id),
  PRIMARY KEY (command, url),
  CONSTRAINT bang_fk_category_id FOREIGN KEY (category_id) REFERENCES bang_category (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS subscriber;

--
-- Table: subscriber
--
CREATE TABLE subscriber (
  email_address text NOT NULL,
  campaign text NOT NULL,
  verified integer NOT NULL DEFAULT 0,
  unsubscribed integer NOT NULL DEFAULT 0,
  flow text NULL,
  v_key text NOT NULL,
  u_key text NOT NULL,
  created timestamp with time zone NOT NULL,
  INDEX subscriber_idx_email_address (email_address),
  PRIMARY KEY (email_address, campaign),
  CONSTRAINT subscriber_fk_email_address FOREIGN KEY (email_address) REFERENCES subscriber_bounce (email_address) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS subscriber_maillog;

--
-- Table: subscriber_maillog
--
CREATE TABLE subscriber_maillog (
  email_address text NOT NULL,
  campaign text NOT NULL,
  email_id char(1) NOT NULL,
  sent timestamp with time zone NOT NULL,
  INDEX subscriber_maillog_idx_email_address_campaign (email_address, campaign),
  PRIMARY KEY (email_address, campaign, email_id),
  CONSTRAINT subscriber_maillog_fk_email_address_campaign FOREIGN KEY (email_address, campaign) REFERENCES subscriber (email_address, campaign) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

