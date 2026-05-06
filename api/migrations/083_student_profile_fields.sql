-- +migrate Up

ALTER TABLE students
  ADD COLUMN IF NOT EXISTS address                VARCHAR(500) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS city                   VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS province               VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS postal_code            VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS birth_date             DATE,
  ADD COLUMN IF NOT EXISTS gender                 VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS nik                    VARCHAR(20)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS photo_url              TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS education_level        VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS school_name            VARCHAR(255) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS emergency_contact_name  VARCHAR(255) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50)  NOT NULL DEFAULT '';

-- +migrate Down

ALTER TABLE students DROP COLUMN IF EXISTS address;
ALTER TABLE students DROP COLUMN IF EXISTS city;
ALTER TABLE students DROP COLUMN IF EXISTS province;
ALTER TABLE students DROP COLUMN IF EXISTS postal_code;
ALTER TABLE students DROP COLUMN IF EXISTS birth_date;
ALTER TABLE students DROP COLUMN IF EXISTS gender;
ALTER TABLE students DROP COLUMN IF EXISTS nik;
ALTER TABLE students DROP COLUMN IF EXISTS photo_url;
ALTER TABLE students DROP COLUMN IF EXISTS education_level;
ALTER TABLE students DROP COLUMN IF EXISTS school_name;
ALTER TABLE students DROP COLUMN IF EXISTS emergency_contact_name;
ALTER TABLE students DROP COLUMN IF EXISTS emergency_contact_phone;
