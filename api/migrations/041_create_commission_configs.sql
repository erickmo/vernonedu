-- Singleton row: one company-level commission configuration
CREATE TABLE commission_configs (
    id            SERIAL PRIMARY KEY,
    op_leader_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
    op_leader_basis VARCHAR(20) NOT NULL DEFAULT 'profit'
        CHECK (op_leader_basis IN ('profit', 'revenue')),
    dept_leader_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
    dept_leader_basis VARCHAR(20) NOT NULL DEFAULT 'profit'
        CHECK (dept_leader_basis IN ('profit', 'revenue')),
    course_creator_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
    course_creator_basis VARCHAR(20) NOT NULL DEFAULT 'profit'
        CHECK (course_creator_basis IN ('profit', 'revenue')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed one default row so GET always returns data
INSERT INTO commission_configs
    (op_leader_pct, op_leader_basis, dept_leader_pct, dept_leader_basis,
     course_creator_pct, course_creator_basis)
VALUES (0, 'profit', 0, 'profit', 0, 'profit');
