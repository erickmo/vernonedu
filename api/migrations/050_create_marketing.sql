CREATE TABLE IF NOT EXISTS social_media_posts (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platforms     TEXT[] NOT NULL DEFAULT '{}',
    scheduled_at  TIMESTAMPTZ NOT NULL,
    content_type  TEXT NOT NULL DEFAULT 'promo'
                  CHECK (content_type IN ('promo','dokumentasi','info','event')),
    caption       TEXT NOT NULL DEFAULT '',
    media_url     TEXT NOT NULL DEFAULT '',
    batch_id      UUID REFERENCES course_batches(id) ON DELETE SET NULL,
    status        TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('scheduled','posted','draft')),
    post_url      TEXT NOT NULL DEFAULT '',
    created_by    UUID NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_doc_posts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            UUID NOT NULL,
    session_id          UUID NOT NULL,
    module_name         TEXT NOT NULL DEFAULT '',
    batch_name          TEXT NOT NULL DEFAULT '',
    class_date          DATE NOT NULL,
    scheduled_post_date DATE NOT NULL,
    status              TEXT NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled','posted')),
    post_url            TEXT NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pr_schedules (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT NOT NULL,
    type         TEXT NOT NULL DEFAULT 'other'
                 CHECK (type IN ('press_release','event','sponsorship','interview','other')),
    scheduled_at TIMESTAMPTZ NOT NULL,
    media_venue  TEXT NOT NULL DEFAULT '',
    pic_id       UUID,
    pic_name     TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'scheduled'
                 CHECK (status IN ('scheduled','active','completed')),
    notes        TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referral_partners (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             TEXT NOT NULL,
    contact_email    TEXT NOT NULL DEFAULT '',
    referral_code    TEXT NOT NULL UNIQUE,
    commission_type  TEXT NOT NULL DEFAULT 'percentage'
                     CHECK (commission_type IN ('percentage','fixed')),
    commission_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS referrals (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_partner_id UUID NOT NULL REFERENCES referral_partners(id) ON DELETE CASCADE,
    lead_id             UUID,
    student_id          UUID,
    batch_id            UUID,
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','enrolled','paid')),
    commission          NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_social_media_posts_status      ON social_media_posts(status);
CREATE INDEX idx_social_media_posts_scheduled   ON social_media_posts(scheduled_at);
CREATE INDEX idx_class_doc_posts_status         ON class_doc_posts(status);
CREATE INDEX idx_class_doc_posts_batch          ON class_doc_posts(batch_id);
CREATE INDEX idx_pr_schedules_status            ON pr_schedules(status);
CREATE INDEX idx_referral_partners_code         ON referral_partners(referral_code);
CREATE INDEX idx_referrals_partner              ON referrals(referral_partner_id);
