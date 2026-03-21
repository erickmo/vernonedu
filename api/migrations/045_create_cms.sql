-- CMS Pages
CREATE TABLE IF NOT EXISTS cms_pages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug        VARCHAR(100) NOT NULL UNIQUE,
    title       VARCHAR(255) NOT NULL DEFAULT '',
    subtitle    VARCHAR(500) NOT NULL DEFAULT '',
    content     JSONB        NOT NULL DEFAULT '{}',
    hero_image_url TEXT      NOT NULL DEFAULT '',
    seo         JSONB        NOT NULL DEFAULT '{"metaTitle":"","metaDescription":"","ogImage":""}',
    updated_by  UUID         REFERENCES users(id),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- CMS Articles
CREATE TABLE IF NOT EXISTS cms_articles (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug              VARCHAR(150) NOT NULL UNIQUE,
    title             VARCHAR(255) NOT NULL,
    category          VARCHAR(50)  NOT NULL DEFAULT 'berita',
    content           TEXT         NOT NULL DEFAULT '',
    featured_image_url TEXT        NOT NULL DEFAULT '',
    status            VARCHAR(20)  NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft','published','archived')),
    author_id         UUID         REFERENCES users(id),
    published_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- CMS Testimonials
CREATE TABLE IF NOT EXISTS cms_testimonials (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_name VARCHAR(150) NOT NULL,
    course_id    UUID         REFERENCES master_courses(id) ON DELETE SET NULL,
    quote        TEXT         NOT NULL,
    rating       INT          NOT NULL DEFAULT 5 CHECK (rating BETWEEN 1 AND 5),
    photo_url    TEXT         NOT NULL DEFAULT '',
    is_featured  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- CMS FAQ
CREATE TABLE IF NOT EXISTS cms_faq (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question   TEXT        NOT NULL,
    answer     TEXT        NOT NULL,
    category   VARCHAR(50) NOT NULL DEFAULT 'umum',
    page_slugs TEXT[]      NOT NULL DEFAULT '{}',
    sort_order INT         NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- CMS Media
CREATE TABLE IF NOT EXISTS cms_media (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url          TEXT         NOT NULL,
    file_name    VARCHAR(255) NOT NULL,
    file_type    VARCHAR(100) NOT NULL DEFAULT '',
    file_size    BIGINT       NOT NULL DEFAULT 0,
    uploaded_by  UUID         REFERENCES users(id),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cms_articles_status       ON cms_articles(status);
CREATE INDEX IF NOT EXISTS idx_cms_articles_category     ON cms_articles(category);
CREATE INDEX IF NOT EXISTS idx_cms_testimonials_featured ON cms_testimonials(is_featured);
CREATE INDEX IF NOT EXISTS idx_cms_faq_category          ON cms_faq(category);
CREATE INDEX IF NOT EXISTS idx_cms_faq_sort              ON cms_faq(sort_order);
