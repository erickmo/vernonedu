-- Migration: add title, status, and document_url columns to mous table
ALTER TABLE mous
    ADD COLUMN IF NOT EXISTS title        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS status       TEXT NOT NULL DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS document_url TEXT NOT NULL DEFAULT '';
