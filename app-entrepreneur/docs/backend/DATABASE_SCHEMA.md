# VernonEdu Entrepreneurship — Database Schema & Migrations

**Version:** 1.0.0
**Database:** PostgreSQL 15+

---

## 📋 Migration Strategy

Use numbered SQL files in `internal/database/migrations/`:
- `001_create_users.sql`
- `002_create_businesses.sql`
- `003_create_worksheets.sql`
- `004_create_canvas_items.sql`

Each migration is idempotent. Rollback via `TRUNCATE` or `DROP TABLE`.

---

## 🗄️ Complete Schema

### Migration 001: Create Users Table

**File:** `internal/database/migrations/001_create_users.sql`

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  role VARCHAR(20) DEFAULT 'student',  -- student, teacher, admin
  status VARCHAR(20) DEFAULT 'active',  -- active, inactive, suspended
  email_verified BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMP,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- Trigger untuk updated_at
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_users_updated_at();

-- Seed data
INSERT INTO users (email, password_hash, name, role) VALUES
  ('student@vernonedu.local', '$2a$12$...', 'Demo Student', 'student'),
  ('teacher@vernonedu.local', '$2a$12$...', 'Demo Teacher', 'teacher')
ON CONFLICT (email) DO NOTHING;
```

**Go Migration Runner:**
```go
// internal/database/migration.go
func RunMigrations(db *sql.DB) error {
  migrations := []string{
    readFile("migrations/001_create_users.sql"),
    readFile("migrations/002_create_businesses.sql"),
    readFile("migrations/003_create_worksheets.sql"),
    readFile("migrations/004_create_canvas_items.sql"),
  }

  for _, migration := range migrations {
    if _, err := db.Exec(migration); err != nil {
      return fmt.Errorf("migration failed: %w", err)
    }
  }
  return nil
}
```

---

### Migration 002: Create Businesses Table

**File:** `internal/database/migrations/002_create_businesses.sql`

```sql
CREATE TABLE IF NOT EXISTS businesses (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "bus_" + 16 random chars
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'draft',
    -- draft: dalam proses
    -- submitted: sudah submit untuk review
    -- approved: sudah approved mentor
    -- rejected: ditolak
  mentor_notes TEXT,
  submitted_at TIMESTAMP,
  approved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_businesses_owner ON businesses(owner_id);
CREATE INDEX idx_businesses_status ON businesses(status);
CREATE INDEX idx_businesses_created_at ON businesses(created_at DESC);

-- Trigger untuk updated_at
CREATE TRIGGER trigger_businesses_updated_at
BEFORE UPDATE ON businesses
FOR EACH ROW
EXECUTE FUNCTION update_businesses_updated_at();

CREATE OR REPLACE FUNCTION update_businesses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

### Migration 003: Create Worksheets Table

**File:** `internal/database/migrations/003_create_worksheets.sql`

```sql
CREATE TABLE IF NOT EXISTS worksheets (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "ws_" + 16 random chars
  business_id VARCHAR(20) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
    -- business-model-canvas: 9 sections
    -- value-proposition: 6 sections
    -- design-thinking: 5 stages
    -- pestel: 6 categories
    -- flywheel-marketing: 5 sections
  title VARCHAR(200) NOT NULL,
  status VARCHAR(20) DEFAULT 'draft',
    -- draft: dalam proses
    -- submitted: sudah submit untuk review
    -- approved: sudah approved mentor
  mentor_feedback TEXT,
  submitted_at TIMESTAMP,
  approved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_worksheets_business ON worksheets(business_id);
CREATE INDEX idx_worksheets_type ON worksheets(type);
CREATE INDEX idx_worksheets_status ON worksheets(status);
CREATE INDEX idx_worksheets_created_at ON worksheets(created_at DESC);

-- Trigger untuk updated_at
CREATE TRIGGER trigger_worksheets_updated_at
BEFORE UPDATE ON worksheets
FOR EACH ROW
EXECUTE FUNCTION update_worksheets_updated_at();

CREATE OR REPLACE FUNCTION update_worksheets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

### Migration 004: Create Canvas Items Table

**File:** `internal/database/migrations/004_create_canvas_items.sql`

```sql
CREATE TABLE IF NOT EXISTS canvas_items (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "item_" + 16 random chars
  worksheet_id VARCHAR(20) NOT NULL REFERENCES worksheets(id) ON DELETE CASCADE,
  section_id VARCHAR(50) NOT NULL,
    -- BMC: customer-segments, value-propositions, channels,
    --      customer-relationships, revenue-streams, key-resources,
    --      key-activities, key-partnerships, cost-structure
    -- VPC: customer-jobs, pains, gains, products-services,
    --      pain-relievers, gain-creators
    -- DT: empathize, define, ideate, prototype, test
    -- PESTEL: political, economic, social, technological, environmental, legal
    -- Flywheel: attract, engage, delight, friction-points, force-accelerators
  text VARCHAR(500) NOT NULL,  -- Main content
  note TEXT,                    -- Additional notes
  is_expanded BOOLEAN DEFAULT FALSE,  -- UI state: note visible?
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_canvas_items_worksheet ON canvas_items(worksheet_id);
CREATE INDEX idx_canvas_items_section ON canvas_items(worksheet_id, section_id);
CREATE INDEX idx_canvas_items_created_at ON canvas_items(created_at DESC);

-- Trigger untuk updated_at
CREATE TRIGGER trigger_canvas_items_updated_at
BEFORE UPDATE ON canvas_items
FOR EACH ROW
EXECUTE FUNCTION update_canvas_items_updated_at();

CREATE OR REPLACE FUNCTION update_canvas_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📊 Database Diagram

```
┌─────────────────────┐
│     USERS           │
├─────────────────────┤
│ id (UUID) PK        │
│ email (UNIQUE)      │
│ password_hash       │
│ name                │
│ role                │
│ status              │
│ created_at          │
│ updated_at          │
└─────────────────────┘
         │
         │ owns (1:N)
         │
         ▼
┌─────────────────────┐
│   BUSINESSES        │
├─────────────────────┤
│ id (VARCHAR) PK     │
│ owner_id (FK)       │
│ name                │
│ description         │
│ status              │
│ submitted_at        │
│ approved_at         │
│ created_at          │
│ updated_at          │
└─────────────────────┘
         │
         │ contains (1:N)
         │
         ▼
┌─────────────────────┐
│   WORKSHEETS        │
├─────────────────────┤
│ id (VARCHAR) PK     │
│ business_id (FK)    │
│ type                │
│ title               │
│ status              │
│ submitted_at        │
│ approved_at         │
│ created_at          │
│ updated_at          │
└─────────────────────┘
         │
         │ has (1:N)
         │
         ▼
┌─────────────────────┐
│  CANVAS_ITEMS       │
├─────────────────────┤
│ id (VARCHAR) PK     │
│ worksheet_id (FK)   │
│ section_id          │
│ text                │
│ note                │
│ is_expanded         │
│ created_at          │
│ updated_at          │
└─────────────────────┘
```

---

## 💾 ID Generation Strategy

### Format Standards

#### Business ID
- Format: `"bus_" + base62(16 chars)`
- Example: `bus_j8f3k2n9x4m1q7b0`
- Implementation:
  ```go
  // internal/utils/id_generator.go
  func GenerateBusinessID() string {
    return "bus_" + generateRandomString(16)
  }
  ```

#### Worksheet ID
- Format: `"ws_" + base62(16 chars)`
- Example: `ws_a2b4c6d8e0f2g4h6`

#### Canvas Item ID
- Format: `"item_" + base62(16 chars)`
- Example: `item_z9y8x7w6v5u4t3s2`

#### User ID
- Format: UUID (PostgreSQL `gen_random_uuid()`)
- Example: `550e8400-e29b-41d4-a716-446655440000`

---

## 🔍 Query Performance

### Key Indexes
```sql
-- Frequently used queries
idx_businesses_owner        -- List user's businesses
idx_worksheets_business     -- Get all worksheets for business
idx_canvas_items_worksheet  -- Get all items for worksheet
idx_users_email             -- Lookup user by email (login)
idx_canvas_items_section    -- Filter by section (UI rendering)
```

### Query Examples

#### 1. List User's Businesses
```sql
SELECT * FROM businesses
WHERE owner_id = $1
ORDER BY created_at DESC
LIMIT 20 OFFSET $2;
```
**Index:** `idx_businesses_owner`

#### 2. Get Worksheet with Items
```sql
SELECT w.*,
       json_agg(json_build_object(
         'id', c.id,
         'section_id', c.section_id,
         'text', c.text,
         'note', c.note,
         'is_expanded', c.is_expanded
       )) as items
FROM worksheets w
LEFT JOIN canvas_items c ON w.id = c.worksheet_id
WHERE w.id = $1
GROUP BY w.id;
```

#### 3. Count Items per Section
```sql
SELECT section_id, COUNT(*) as count
FROM canvas_items
WHERE worksheet_id = $1
GROUP BY section_id;
```

---

## 🔐 Data Constraints

### Not Null Constraints
```
users:              email, password_hash
businesses:         owner_id, name, status
worksheets:         business_id, type, title, status
canvas_items:       worksheet_id, section_id, text
```

### Unique Constraints
```
users.email         -- No duplicate accounts
businesses.id       -- Unique ID (PK)
worksheets.id       -- Unique ID (PK)
canvas_items.id     -- Unique ID (PK)
```

### Foreign Key Constraints
```
businesses.owner_id         → users.id (CASCADE DELETE)
worksheets.business_id      → businesses.id (CASCADE DELETE)
canvas_items.worksheet_id   → worksheets.id (CASCADE DELETE)
```

---

## 📝 Seed Data

**File:** `internal/database/seeds/initial_data.sql`

```sql
-- Seed users
INSERT INTO users (email, password_hash, name, role) VALUES
  ('student1@vernonedu.local',
   '$2a$12$K1xVyH8x8q9n2p0r3s4t5u6v7w8x9y0z.Xp0p1p2p3p4p5p6p7p8p9q0',
   'Budi Santoso',
   'student'),
  ('student2@vernonedu.local',
   '$2a$12$L2yWzI9y9r0o3q1s2t3u4v5w6x7y8z9a.Yq1q2q3q4q5q6q7q8q9r1',
   'Siti Nurhaliza',
   'student');

-- Seed businesses (for student1)
INSERT INTO businesses (id, owner_id, name, description, status) VALUES
  ('bus_demo000001',
   (SELECT id FROM users WHERE email = 'student1@vernonedu.local'),
   'TechStartup Indonesia',
   'Platform e-learning interaktif',
   'draft');

-- Seed worksheets
INSERT INTO worksheets (id, business_id, type, title, status) VALUES
  ('ws_demo0000001',
   'bus_demo000001',
   'business-model-canvas',
   'BMC - TechStartup Indonesia',
   'draft');

-- Seed canvas items
INSERT INTO canvas_items (id, worksheet_id, section_id, text, note) VALUES
  ('item_demo00001',
   'ws_demo0000001',
   'customer-segments',
   'Startup founders aged 25-35',
   'Jakarta market, high growth potential'),
  ('item_demo00002',
   'ws_demo0000001',
   'value-propositions',
   'Interactive learning platform with AI',
   'Key differentiator vs competitors'),
  ('item_demo00003',
   'ws_demo0000001',
   'key-activities',
   'Course development & platform maintenance',
   NULL);
```

---

## 🛠️ Maintenance

### Backup Strategy
```bash
# Daily backup
pg_dump vernonedu_entrepreneurship > backup_$(date +%Y%m%d).sql

# Restore from backup
psql vernonedu_entrepreneurship < backup_20260317.sql
```

### Monitoring Queries
```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check slow queries (if slow_query_log enabled)
SELECT query, calls, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### Scaling Considerations
- For >1M rows: Add partitioning on `created_at`
- For >100M canvas_items: Consider data archival
- Add read replicas for analytics queries

---

## 🎯 Implementation Checklist

- [ ] Create migrations directory structure
- [ ] Write all 4 migrations
- [ ] Setup migration runner in Go
- [ ] Test migrations locally (up/down)
- [ ] Add seed data
- [ ] Verify indexes are created
- [ ] Test backup/restore
- [ ] Document connection pooling settings
- [ ] Setup monitoring alerts

---

**Ready for implementation! 🚀**
