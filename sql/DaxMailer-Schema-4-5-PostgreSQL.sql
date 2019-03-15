-- Convert schema '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-4-PostgreSQL.sql' to '/mnt/ebs/usr/local/ddh/DaxMailer/bin/../sql/DaxMailer-Schema-5-PostgreSQL.sql':;

BEGIN;

ALTER TABLE bang DROP CONSTRAINT bang_pkey;

ALTER TABLE bang ADD COLUMN id serial NOT NULL;

ALTER TABLE bang ADD COLUMN example_search text DEFAULT 'hello';

ALTER TABLE bang ADD COLUMN note text;

ALTER TABLE bang ADD COLUMN created timestamp DEFAULT '2019-01-01' NOT NULL;

ALTER TABLE bang ADD PRIMARY KEY (id);


COMMIT;

