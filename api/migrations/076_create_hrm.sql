-- 076: HRM Module — Employees, Staff Attendance, Leave Requests, Payroll

-- Employees (extends users with HR fields)
CREATE TABLE IF NOT EXISTS employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  employee_number VARCHAR(50) NOT NULL UNIQUE,
  department_id   UUID REFERENCES departments(id) ON DELETE SET NULL,
  position        VARCHAR(255) NOT NULL DEFAULT '',
  hire_date       DATE NOT NULL,
  status          VARCHAR(50) NOT NULL DEFAULT 'active',
  phone           VARCHAR(50) DEFAULT '',
  address         TEXT DEFAULT '',
  base_salary     DECIMAL(15,2) NOT NULL DEFAULT 0,
  bank_name       VARCHAR(255) DEFAULT '',
  bank_account    VARCHAR(100) DEFAULT '',
  contract_type   VARCHAR(50) DEFAULT '',
  contract_end    DATE,
  notes           TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_employees_user ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_dept ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);
CREATE INDEX IF NOT EXISTS idx_employees_number ON employees(employee_number);

-- Staff Attendance
CREATE TABLE IF NOT EXISTS staff_attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  status      VARCHAR(50) NOT NULL DEFAULT 'present',
  clock_in    TIMESTAMPTZ,
  clock_out   TIMESTAMPTZ,
  note        TEXT DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_staff_attendance_emp_date UNIQUE (employee_id, date)
);
CREATE INDEX IF NOT EXISTS idx_staff_att_emp ON staff_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_att_date ON staff_attendance(date);
CREATE INDEX IF NOT EXISTS idx_staff_att_status ON staff_attendance(status);

-- Leave Requests
CREATE TABLE IF NOT EXISTS leave_requests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  leave_type  VARCHAR(50) NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  reason      TEXT NOT NULL,
  status      VARCHAR(50) NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_leave_emp ON leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_dates ON leave_requests(start_date, end_date);

-- Payroll Periods
CREATE TABLE IF NOT EXISTS payroll_periods (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period          VARCHAR(10) NOT NULL UNIQUE,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          VARCHAR(50) NOT NULL DEFAULT 'draft',
  approved_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at     TIMESTAMPTZ,
  disbursed_at    TIMESTAMPTZ,
  notes           TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_payroll_periods_status ON payroll_periods(status);

-- Payroll Items
CREATE TABLE IF NOT EXISTS payroll_items (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_period_id   UUID NOT NULL REFERENCES payroll_periods(id) ON DELETE CASCADE,
  employee_id         UUID NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
  base_salary         DECIMAL(15,2) NOT NULL DEFAULT 0,
  facilitator_sessions INTEGER NOT NULL DEFAULT 0,
  facilitator_fee     DECIMAL(15,2) NOT NULL DEFAULT 0,
  attendance_deduction DECIMAL(15,2) NOT NULL DEFAULT 0,
  bonus               DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount        DECIMAL(15,2) NOT NULL DEFAULT 0,
  status              VARCHAR(50) NOT NULL DEFAULT 'pending',
  notes               TEXT DEFAULT '',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_payroll_item UNIQUE (payroll_period_id, employee_id)
);
CREATE INDEX IF NOT EXISTS idx_payroll_items_period ON payroll_items(payroll_period_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_emp ON payroll_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_status ON payroll_items(status);
