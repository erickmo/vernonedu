package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type CmsRepository struct {
	db *sqlx.DB
}

func NewCmsRepository(db *sqlx.DB) *CmsRepository {
	return &CmsRepository{db: db}
}

// ─── PAGE ─────────────────────────────────────────────────────────────────────

func (r *CmsRepository) SavePage(ctx context.Context, p *cms.CmsPage) error {
	contentJSON, _ := json.Marshal(p.Content)
	seoJSON, _ := json.Marshal(p.Seo)

	q := `
		INSERT INTO cms_pages (id, slug, title, subtitle, content, hero_image_url, seo, updated_by, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (slug) DO UPDATE SET
			title = EXCLUDED.title,
			subtitle = EXCLUDED.subtitle,
			content = EXCLUDED.content,
			hero_image_url = EXCLUDED.hero_image_url,
			seo = EXCLUDED.seo,
			updated_by = EXCLUDED.updated_by,
			updated_at = EXCLUDED.updated_at
	`
	_, err := r.db.ExecContext(ctx, q,
		p.ID, p.Slug, p.Title, p.Subtitle,
		contentJSON, p.HeroImageURL, seoJSON,
		p.UpdatedBy, p.UpdatedAt,
	)
	return err
}

func (r *CmsRepository) ListPages(ctx context.Context) ([]*cms.CmsPage, error) {
	type rec struct {
		ID           uuid.UUID `db:"id"`
		Slug         string    `db:"slug"`
		Title        string    `db:"title"`
		Subtitle     string    `db:"subtitle"`
		Content      []byte    `db:"content"`
		HeroImageURL string    `db:"hero_image_url"`
		Seo          []byte    `db:"seo"`
		UpdatedBy    uuid.UUID `db:"updated_by"`
		UpdatedAt    time.Time `db:"updated_at"`
	}
	var rows []rec
	err := r.db.SelectContext(ctx, &rows, `SELECT id, slug, title, subtitle, content, hero_image_url, seo, updated_by, updated_at FROM cms_pages ORDER BY slug`)
	if err != nil {
		return nil, fmt.Errorf("list cms pages: %w", err)
	}
	pages := make([]*cms.CmsPage, len(rows))
	for i, rr := range rows {
		var content, seo map[string]interface{}
		_ = json.Unmarshal(rr.Content, &content)
		_ = json.Unmarshal(rr.Seo, &seo)
		pages[i] = &cms.CmsPage{
			ID: rr.ID, Slug: rr.Slug, Title: rr.Title, Subtitle: rr.Subtitle,
			Content: content, HeroImageURL: rr.HeroImageURL, Seo: seo,
			UpdatedBy: rr.UpdatedBy, UpdatedAt: rr.UpdatedAt,
		}
	}
	return pages, nil
}

func (r *CmsRepository) GetPageBySlug(ctx context.Context, slug string) (*cms.CmsPage, error) {
	type rec struct {
		ID           uuid.UUID `db:"id"`
		Slug         string    `db:"slug"`
		Title        string    `db:"title"`
		Subtitle     string    `db:"subtitle"`
		Content      []byte    `db:"content"`
		HeroImageURL string    `db:"hero_image_url"`
		Seo          []byte    `db:"seo"`
		UpdatedBy    uuid.UUID `db:"updated_by"`
		UpdatedAt    time.Time `db:"updated_at"`
	}
	var rr rec
	err := r.db.GetContext(ctx, &rr, `SELECT id, slug, title, subtitle, content, hero_image_url, seo, updated_by, updated_at FROM cms_pages WHERE slug = $1`, slug)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, cms.ErrPageNotFound
		}
		return nil, fmt.Errorf("get cms page: %w", err)
	}
	var content, seo map[string]interface{}
	_ = json.Unmarshal(rr.Content, &content)
	_ = json.Unmarshal(rr.Seo, &seo)
	return &cms.CmsPage{
		ID: rr.ID, Slug: rr.Slug, Title: rr.Title, Subtitle: rr.Subtitle,
		Content: content, HeroImageURL: rr.HeroImageURL, Seo: seo,
		UpdatedBy: rr.UpdatedBy, UpdatedAt: rr.UpdatedAt,
	}, nil
}

// ─── ARTICLE ──────────────────────────────────────────────────────────────────

func (r *CmsRepository) SaveArticle(ctx context.Context, a *cms.CmsArticle) error {
	q := `
		INSERT INTO cms_articles (id, slug, title, category, content, featured_image_url, status, author_id, published_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.ExecContext(ctx, q,
		a.ID, a.Slug, a.Title, a.Category, a.Content, a.FeaturedImageURL,
		a.Status, a.AuthorID, a.PublishedAt, a.CreatedAt, a.UpdatedAt,
	)
	return err
}

func (r *CmsRepository) UpdateArticle(ctx context.Context, a *cms.CmsArticle) error {
	q := `
		UPDATE cms_articles SET
			slug = $1, title = $2, category = $3, content = $4,
			featured_image_url = $5, status = $6, published_at = $7, updated_at = $8
		WHERE id = $9
	`
	_, err := r.db.ExecContext(ctx, q,
		a.Slug, a.Title, a.Category, a.Content,
		a.FeaturedImageURL, a.Status, a.PublishedAt, a.UpdatedAt, a.ID,
	)
	return err
}

func (r *CmsRepository) DeleteArticle(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM cms_articles WHERE id = $1`, id)
	return err
}

func (r *CmsRepository) ListArticles(ctx context.Context, category, status string, offset, limit int) ([]*cms.CmsArticle, int, error) {
	type rec struct {
		ID               uuid.UUID  `db:"id"`
		Slug             string     `db:"slug"`
		Title            string     `db:"title"`
		Category         string     `db:"category"`
		Content          string     `db:"content"`
		FeaturedImageURL string     `db:"featured_image_url"`
		Status           string     `db:"status"`
		AuthorID         uuid.UUID  `db:"author_id"`
		PublishedAt      *time.Time `db:"published_at"`
		CreatedAt        time.Time  `db:"created_at"`
		UpdatedAt        time.Time  `db:"updated_at"`
	}

	where := "WHERE 1=1"
	args := []interface{}{}
	i := 1
	if category != "" {
		where += fmt.Sprintf(" AND category = $%d", i)
		args = append(args, category)
		i++
	}
	if status != "" {
		where += fmt.Sprintf(" AND status = $%d", i)
		args = append(args, status)
		i++
	}

	var total int
	err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM cms_articles "+where, args...)
	if err != nil {
		return nil, 0, err
	}

	args = append(args, limit, offset)
	q := fmt.Sprintf("SELECT id, slug, title, category, content, featured_image_url, status, author_id, published_at, created_at, updated_at FROM cms_articles %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d", where, i, i+1)
	var rows []rec
	if err := r.db.SelectContext(ctx, &rows, q, args...); err != nil {
		return nil, 0, err
	}
	result := make([]*cms.CmsArticle, len(rows))
	for j, rr := range rows {
		result[j] = &cms.CmsArticle{
			ID: rr.ID, Slug: rr.Slug, Title: rr.Title, Category: rr.Category,
			Content: rr.Content, FeaturedImageURL: rr.FeaturedImageURL,
			Status: rr.Status, AuthorID: rr.AuthorID,
			PublishedAt: rr.PublishedAt, CreatedAt: rr.CreatedAt, UpdatedAt: rr.UpdatedAt,
		}
	}
	return result, total, nil
}

func (r *CmsRepository) GetArticleBySlug(ctx context.Context, slug string) (*cms.CmsArticle, error) {
	type rec struct {
		ID               uuid.UUID  `db:"id"`
		Slug             string     `db:"slug"`
		Title            string     `db:"title"`
		Category         string     `db:"category"`
		Content          string     `db:"content"`
		FeaturedImageURL string     `db:"featured_image_url"`
		Status           string     `db:"status"`
		AuthorID         uuid.UUID  `db:"author_id"`
		PublishedAt      *time.Time `db:"published_at"`
		CreatedAt        time.Time  `db:"created_at"`
		UpdatedAt        time.Time  `db:"updated_at"`
	}
	var rr rec
	err := r.db.GetContext(ctx, &rr, `SELECT id, slug, title, category, content, featured_image_url, status, author_id, published_at, created_at, updated_at FROM cms_articles WHERE slug = $1`, slug)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, cms.ErrArticleNotFound
		}
		return nil, err
	}
	return &cms.CmsArticle{
		ID: rr.ID, Slug: rr.Slug, Title: rr.Title, Category: rr.Category,
		Content: rr.Content, FeaturedImageURL: rr.FeaturedImageURL,
		Status: rr.Status, AuthorID: rr.AuthorID,
		PublishedAt: rr.PublishedAt, CreatedAt: rr.CreatedAt, UpdatedAt: rr.UpdatedAt,
	}, nil
}

func (r *CmsRepository) GetArticleByID(ctx context.Context, id uuid.UUID) (*cms.CmsArticle, error) {
	type rec struct {
		ID               uuid.UUID  `db:"id"`
		Slug             string     `db:"slug"`
		Title            string     `db:"title"`
		Category         string     `db:"category"`
		Content          string     `db:"content"`
		FeaturedImageURL string     `db:"featured_image_url"`
		Status           string     `db:"status"`
		AuthorID         uuid.UUID  `db:"author_id"`
		PublishedAt      *time.Time `db:"published_at"`
		CreatedAt        time.Time  `db:"created_at"`
		UpdatedAt        time.Time  `db:"updated_at"`
	}
	var rr rec
	err := r.db.GetContext(ctx, &rr, `SELECT id, slug, title, category, content, featured_image_url, status, author_id, published_at, created_at, updated_at FROM cms_articles WHERE id = $1`, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, cms.ErrArticleNotFound
		}
		return nil, err
	}
	return &cms.CmsArticle{
		ID: rr.ID, Slug: rr.Slug, Title: rr.Title, Category: rr.Category,
		Content: rr.Content, FeaturedImageURL: rr.FeaturedImageURL,
		Status: rr.Status, AuthorID: rr.AuthorID,
		PublishedAt: rr.PublishedAt, CreatedAt: rr.CreatedAt, UpdatedAt: rr.UpdatedAt,
	}, nil
}

// ─── TESTIMONIAL ──────────────────────────────────────────────────────────────

func (r *CmsRepository) SaveTestimonial(ctx context.Context, t *cms.CmsTestimonial) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO cms_testimonials (id, student_name, course_id, quote, rating, photo_url, is_featured, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
		t.ID, t.StudentName, t.CourseID, t.Quote, t.Rating, t.PhotoURL, t.IsFeatured, t.CreatedAt,
	)
	return err
}

func (r *CmsRepository) UpdateTestimonial(ctx context.Context, t *cms.CmsTestimonial) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE cms_testimonials SET student_name=$1, course_id=$2, quote=$3, rating=$4, photo_url=$5, is_featured=$6 WHERE id=$7`,
		t.StudentName, t.CourseID, t.Quote, t.Rating, t.PhotoURL, t.IsFeatured, t.ID,
	)
	return err
}

func (r *CmsRepository) DeleteTestimonial(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM cms_testimonials WHERE id = $1`, id)
	return err
}

func (r *CmsRepository) ListTestimonials(ctx context.Context, courseID *uuid.UUID, isFeatured *bool) ([]*cms.CmsTestimonial, error) {
	type rec struct {
		ID          uuid.UUID  `db:"id"`
		StudentName string     `db:"student_name"`
		CourseID    *uuid.UUID `db:"course_id"`
		Quote       string     `db:"quote"`
		Rating      int        `db:"rating"`
		PhotoURL    string     `db:"photo_url"`
		IsFeatured  bool       `db:"is_featured"`
		CreatedAt   time.Time  `db:"created_at"`
	}
	where := "WHERE 1=1"
	args := []interface{}{}
	i := 1
	if courseID != nil {
		where += fmt.Sprintf(" AND course_id = $%d", i)
		args = append(args, *courseID)
		i++
	}
	if isFeatured != nil {
		where += fmt.Sprintf(" AND is_featured = $%d", i)
		args = append(args, *isFeatured)
		i++
	}
	_ = i
	var rows []rec
	if err := r.db.SelectContext(ctx, &rows, "SELECT id, student_name, course_id, quote, rating, photo_url, is_featured, created_at FROM cms_testimonials "+where+" ORDER BY created_at DESC", args...); err != nil {
		return nil, err
	}
	result := make([]*cms.CmsTestimonial, len(rows))
	for j, rr := range rows {
		result[j] = &cms.CmsTestimonial{
			ID: rr.ID, StudentName: rr.StudentName, CourseID: rr.CourseID,
			Quote: rr.Quote, Rating: rr.Rating, PhotoURL: rr.PhotoURL,
			IsFeatured: rr.IsFeatured, CreatedAt: rr.CreatedAt,
		}
	}
	return result, nil
}

// ─── FAQ ──────────────────────────────────────────────────────────────────────

func (r *CmsRepository) SaveFaq(ctx context.Context, f *cms.CmsFaq) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO cms_faq (id, question, answer, category, page_slugs, sort_order, created_at, updated_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
		f.ID, f.Question, f.Answer, f.Category, pq.Array(f.PageSlugs), f.SortOrder, f.CreatedAt, f.UpdatedAt,
	)
	return err
}

func (r *CmsRepository) UpdateFaq(ctx context.Context, f *cms.CmsFaq) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE cms_faq SET question=$1, answer=$2, category=$3, page_slugs=$4, sort_order=$5, updated_at=$6 WHERE id=$7`,
		f.Question, f.Answer, f.Category, pq.Array(f.PageSlugs), f.SortOrder, f.UpdatedAt, f.ID,
	)
	return err
}

func (r *CmsRepository) DeleteFaq(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM cms_faq WHERE id = $1`, id)
	return err
}

func (r *CmsRepository) ListFaq(ctx context.Context, category, pageSlug string) ([]*cms.CmsFaq, error) {
	type rec struct {
		ID        uuid.UUID      `db:"id"`
		Question  string         `db:"question"`
		Answer    string         `db:"answer"`
		Category  string         `db:"category"`
		PageSlugs pq.StringArray `db:"page_slugs"`
		SortOrder int            `db:"sort_order"`
		CreatedAt time.Time      `db:"created_at"`
		UpdatedAt time.Time      `db:"updated_at"`
	}
	where := "WHERE 1=1"
	args := []interface{}{}
	i := 1
	if category != "" {
		where += fmt.Sprintf(" AND category = $%d", i)
		args = append(args, category)
		i++
	}
	if pageSlug != "" {
		where += fmt.Sprintf(" AND $%d = ANY(page_slugs)", i)
		args = append(args, pageSlug)
		i++
	}
	_ = i
	var rows []rec
	if err := r.db.SelectContext(ctx, &rows, "SELECT id, question, answer, category, page_slugs, sort_order, created_at, updated_at FROM cms_faq "+where+" ORDER BY sort_order ASC, created_at ASC", args...); err != nil {
		return nil, err
	}
	result := make([]*cms.CmsFaq, len(rows))
	for j, rr := range rows {
		result[j] = &cms.CmsFaq{
			ID: rr.ID, Question: rr.Question, Answer: rr.Answer, Category: rr.Category,
			PageSlugs: []string(rr.PageSlugs), SortOrder: rr.SortOrder,
			CreatedAt: rr.CreatedAt, UpdatedAt: rr.UpdatedAt,
		}
	}
	return result, nil
}

// ─── MEDIA ────────────────────────────────────────────────────────────────────

func (r *CmsRepository) SaveMedia(ctx context.Context, m *cms.CmsMedia) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO cms_media (id, url, file_name, file_type, file_size, uploaded_by, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7)`,
		m.ID, m.URL, m.FileName, m.FileType, m.FileSize, m.UploadedBy, m.CreatedAt,
	)
	return err
}

func (r *CmsRepository) DeleteMedia(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM cms_media WHERE id = $1`, id)
	return err
}

func (r *CmsRepository) ListMedia(ctx context.Context, offset, limit int) ([]*cms.CmsMedia, int, error) {
	type rec struct {
		ID         uuid.UUID `db:"id"`
		URL        string    `db:"url"`
		FileName   string    `db:"file_name"`
		FileType   string    `db:"file_type"`
		FileSize   int64     `db:"file_size"`
		UploadedBy uuid.UUID `db:"uploaded_by"`
		CreatedAt  time.Time `db:"created_at"`
	}
	var total int
	if err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM cms_media"); err != nil {
		return nil, 0, err
	}
	var rows []rec
	if err := r.db.SelectContext(ctx, &rows, "SELECT id, url, file_name, file_type, file_size, uploaded_by, created_at FROM cms_media ORDER BY created_at DESC LIMIT $1 OFFSET $2", limit, offset); err != nil {
		return nil, 0, err
	}
	result := make([]*cms.CmsMedia, len(rows))
	for i, rr := range rows {
		result[i] = &cms.CmsMedia{
			ID: rr.ID, URL: rr.URL, FileName: rr.FileName, FileType: rr.FileType,
			FileSize: rr.FileSize, UploadedBy: rr.UploadedBy, CreatedAt: rr.CreatedAt,
		}
	}
	return result, total, nil
}
