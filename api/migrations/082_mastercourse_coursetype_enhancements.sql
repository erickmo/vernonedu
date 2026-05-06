-- +migrate Up

-- master_courses: add department and owner assignment
ALTER TABLE master_courses
  ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS owner_id      UUID REFERENCES users(id) ON DELETE SET NULL;

-- course_types: add session range constraints
ALTER TABLE course_types
  ADD COLUMN IF NOT EXISTS min_sessions INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS max_sessions INT NOT NULL DEFAULT 1;

-- extend price_type check constraint to include new enum values
ALTER TABLE course_types DROP CONSTRAINT IF EXISTS course_types_price_type_check;
ALTER TABLE course_types ADD CONSTRAINT course_types_price_type_check
  CHECK (price_type IN ('fixed', 'range', 'by_request', 'per_batch', 'per_student'));

-- Validate no unexpected price_type values before migrating
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM course_types
    WHERE price_type NOT IN ('fixed', 'range', 'by_request')
  ) THEN
    RAISE EXCEPTION 'Unexpected price_type values found in course_types. Manual review required before migration.';
  END IF;
END $$;

-- migrate existing price_type values to new enum
UPDATE course_types SET price_type = 'per_batch'   WHERE price_type = 'fixed';
UPDATE course_types SET price_type = 'per_student'  WHERE price_type = 'range';

-- course_batches: add actual values (validated against CourseType bounds)
ALTER TABLE course_batches
  ADD COLUMN IF NOT EXISTS course_type_id    UUID REFERENCES course_types(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS price_type_batch  VARCHAR(50),
  ADD COLUMN IF NOT EXISTS actual_price      BIGINT CHECK (actual_price >= 0),
  ADD COLUMN IF NOT EXISTS discounted_price  BIGINT CHECK (discounted_price >= 0),
  ADD COLUMN IF NOT EXISTS num_sessions      INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS num_students      INT NOT NULL DEFAULT 0;

-- +migrate Down
ALTER TABLE course_types DROP CONSTRAINT IF EXISTS course_types_price_type_check;
ALTER TABLE course_types ADD CONSTRAINT course_types_price_type_check
  CHECK (price_type IN ('fixed', 'range', 'by_request'));
UPDATE course_types SET price_type = 'fixed' WHERE price_type = 'per_batch';
UPDATE course_types SET price_type = 'range' WHERE price_type = 'per_student';
ALTER TABLE master_courses DROP COLUMN IF EXISTS department_id, DROP COLUMN IF EXISTS owner_id;
ALTER TABLE course_types DROP COLUMN IF EXISTS min_sessions, DROP COLUMN IF EXISTS max_sessions;
ALTER TABLE course_batches DROP COLUMN IF EXISTS course_type_id, DROP COLUMN IF EXISTS price_type_batch, DROP COLUMN IF EXISTS actual_price, DROP COLUMN IF EXISTS discounted_price, DROP COLUMN IF EXISTS num_sessions, DROP COLUMN IF EXISTS num_students;
