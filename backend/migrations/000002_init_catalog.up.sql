-- ============================================================
-- Migration 000002: catalog schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS catalog;

CREATE TYPE catalog.course_format AS ENUM (
  'regular', 'private', 'inhouse_training', 'inschool_program'
);
CREATE TYPE catalog.delivery_mode AS ENUM ('online', 'offline');
CREATE TYPE catalog.batch_status AS ENUM ('draft', 'open', 'ongoing', 'closed');
CREATE TYPE catalog.cost_type AS ENUM ('fixed', 'percentage_of_revenue');
CREATE TYPE catalog.instructor_type AS ENUM ('course_creator', 'facilitator');
CREATE TYPE catalog.assigned_by_type AS ENUM ('course_creator_self', 'dept_leader');
CREATE TYPE catalog.module_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE catalog.asset_type AS ENUM ('video', 'pdf', 'document', 'link', 'image', 'other');
CREATE TYPE catalog.version_policy AS ENUM ('auto_latest', 'locked');

CREATE TABLE catalog.courses (
  id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT           NOT NULL,
  department_id         UUID           NOT NULL REFERENCES identity.departments(id) ON DELETE RESTRICT,
  course_creator_id     UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  base_price            NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  min_price             NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  description           TEXT           NULL,
  is_active             BOOLEAN        NOT NULL DEFAULT TRUE,
  profit_split_override JSONB          NULL,
  created_by            UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','courses');
CREATE INDEX idx_courses_department ON catalog.courses(department_id);
CREATE INDEX idx_courses_creator    ON catalog.courses(course_creator_id);

CREATE TABLE catalog.course_format_configs (
  id           UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id    UUID               NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  format       catalog.course_format NOT NULL,
  is_enabled   BOOLEAN            NOT NULL DEFAULT TRUE,
  min_students INTEGER            NULL CHECK (min_students > 0),
  max_students INTEGER            NULL CHECK (max_students > 0),
  mode_online  BOOLEAN            NOT NULL DEFAULT FALSE,
  mode_offline BOOLEAN            NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
  CONSTRAINT uq_course_format UNIQUE (course_id, format)
);
SELECT attach_updated_at_trigger('catalog','course_format_configs');

CREATE TABLE catalog.course_cost_templates (
  id         UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id  UUID               NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  label      TEXT               NOT NULL,
  amount     NUMERIC(12,2)      NOT NULL DEFAULT 0.00,
  cost_type  catalog.cost_type  NOT NULL DEFAULT 'fixed',
  created_at TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ        NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','course_cost_templates');
CREATE INDEX idx_cost_templates_course ON catalog.course_cost_templates(course_id);

CREATE TABLE catalog.course_batches (
  id                    UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id             UUID                  NOT NULL REFERENCES catalog.courses(id) ON DELETE RESTRICT,
  label                 TEXT                  NOT NULL,
  start_date            DATE                  NOT NULL,
  end_date              DATE                  NOT NULL,
  price                 NUMERIC(12,2)         NOT NULL DEFAULT 0.00,
  batch_bulk_price      NUMERIC(12,2)         NULL,
  status                catalog.batch_status  NOT NULL DEFAULT 'draft',
  web_registration_open BOOLEAN               NOT NULL DEFAULT FALSE,
  registration_open_at  TIMESTAMPTZ           NULL,
  registration_close_at TIMESTAMPTZ           NULL,
  created_by            UUID                  NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at            TIMESTAMPTZ           NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ           NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','course_batches');
CREATE INDEX idx_batches_course ON catalog.course_batches(course_id);
CREATE INDEX idx_batches_status ON catalog.course_batches(status);

CREATE TABLE catalog.classes (
  id              UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id UUID                      NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  title           TEXT                      NULL,
  session_date    DATE                      NOT NULL,
  start_time      TIME                      NOT NULL,
  end_time        TIME                      NOT NULL,
  mode            catalog.delivery_mode     NOT NULL,
  location        TEXT                      NULL,
  online_link     TEXT                      NULL,
  instructor_id   UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  instructor_type catalog.instructor_type   NOT NULL,
  assigned_by     catalog.assigned_by_type  NOT NULL,
  created_at      TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ               NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','classes');
CREATE INDEX idx_classes_batch        ON catalog.classes(course_batch_id);
CREATE INDEX idx_classes_session_date ON catalog.classes(session_date);
CREATE INDEX idx_classes_instructor   ON catalog.classes(instructor_id);

CREATE TABLE catalog.modules (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id  UUID        NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  title      TEXT        NOT NULL,
  "order"    INTEGER     NOT NULL,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
  created_by UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','modules');
CREATE INDEX idx_modules_course ON catalog.modules(course_id);
CREATE UNIQUE INDEX uq_module_order ON catalog.modules(course_id, "order");

CREATE TABLE catalog.module_versions (
  id             UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id      UUID                  NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  version_number INTEGER               NOT NULL,
  title          TEXT                  NOT NULL,
  description    TEXT                  NULL,
  status         catalog.module_status NOT NULL DEFAULT 'draft',
  published_at   TIMESTAMPTZ           NULL,
  published_by   UUID                  NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  created_by     UUID                  NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at     TIMESTAMPTZ           NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ           NOT NULL DEFAULT now(),
  CONSTRAINT uq_module_version UNIQUE (module_id, version_number)
);
SELECT attach_updated_at_trigger('catalog','module_versions');

CREATE TABLE catalog.module_assets (
  id                UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  module_version_id UUID               NOT NULL REFERENCES catalog.module_versions(id) ON DELETE CASCADE,
  title             TEXT               NOT NULL,
  asset_type        catalog.asset_type NOT NULL,
  url               TEXT               NOT NULL,
  size_bytes        BIGINT             NULL,
  "order"           INTEGER            NOT NULL,
  is_downloadable   BOOLEAN            NOT NULL DEFAULT FALSE,
  created_by        UUID               NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at        TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ        NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','module_assets');
CREATE INDEX idx_assets_version ON catalog.module_assets(module_version_id);

CREATE TABLE catalog.batch_module_configs (
  id                UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id   UUID                   NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  module_id         UUID                   NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  version_policy    catalog.version_policy NOT NULL DEFAULT 'auto_latest',
  locked_version_id UUID                   NULL REFERENCES catalog.module_versions(id) ON DELETE SET NULL,
  set_by            UUID                   NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at        TIMESTAMPTZ            NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ            NOT NULL DEFAULT now(),
  CONSTRAINT uq_batch_module UNIQUE (course_batch_id, module_id)
);
SELECT attach_updated_at_trigger('catalog','batch_module_configs');

CREATE TABLE catalog.course_budget_template_items (
  id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id      UUID           NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  label          TEXT           NOT NULL,
  category       TEXT           NULL,
  preset_amount  NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  overridable    BOOLEAN        NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('catalog','course_budget_template_items');
CREATE INDEX idx_budget_tmpl_course ON catalog.course_budget_template_items(course_id);

-- Wire deferred FK from identity
ALTER TABLE identity.facilitator_proposals
  ADD CONSTRAINT fk_proposal_course
  FOREIGN KEY (course_id) REFERENCES catalog.courses(id) ON DELETE RESTRICT;
