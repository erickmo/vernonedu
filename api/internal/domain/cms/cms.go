package cms

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrPageNotFound        = errors.New("cms page not found")
	ErrArticleNotFound     = errors.New("cms article not found")
	ErrTestimonialNotFound = errors.New("cms testimonial not found")
	ErrFaqNotFound         = errors.New("cms faq not found")
	ErrMediaNotFound       = errors.New("cms media not found")
	ErrInvalidSlug         = errors.New("slug is required")
	ErrInvalidRating       = errors.New("rating must be between 1 and 5")
)

// Article categories
const (
	CategoryTipsKarir  = "tips_karir"
	CategoryInfoKursus = "info_kursus"
	CategoryBerita     = "berita"
	CategoryEvent      = "event"
)

// Article statuses
const (
	StatusDraft     = "draft"
	StatusPublished = "published"
	StatusArchived  = "archived"
)

// FAQ categories
const (
	FaqCategoryUmum         = "umum"
	FaqCategoryPendaftaran  = "pendaftaran"
	FaqCategoryPembayaran   = "pembayaran"
	FaqCategorySertifikat   = "sertifikat"
	FaqCategoryProgramKarir = "program_karir"
)

// CmsPage represents a managed static/semi-static page
type CmsPage struct {
	ID           uuid.UUID
	Slug         string                 // unique, e.g. "home", "program-karir"
	Title        string
	Subtitle     string
	Content      map[string]interface{} // JSONB
	HeroImageURL string
	Seo          map[string]interface{} // {metaTitle, metaDescription, ogImage}
	UpdatedBy    uuid.UUID
	UpdatedAt    time.Time
}

// CmsArticle represents a blog article
type CmsArticle struct {
	ID               uuid.UUID
	Slug             string
	Title            string
	Category         string
	Content          string // rich text/markdown
	FeaturedImageURL string
	Status           string
	AuthorID         uuid.UUID
	PublishedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

// CmsTestimonial represents a student testimonial shown on website
type CmsTestimonial struct {
	ID          uuid.UUID
	StudentName string
	CourseID    *uuid.UUID
	Quote       string
	Rating      int
	PhotoURL    string
	IsFeatured  bool
	CreatedAt   time.Time
}

// CmsFaq represents an FAQ entry
type CmsFaq struct {
	ID        uuid.UUID
	Question  string
	Answer    string
	Category  string
	PageSlugs []string // which pages show this FAQ
	SortOrder int
	CreatedAt time.Time
	UpdatedAt time.Time
}

// CmsMedia represents an uploaded media file
type CmsMedia struct {
	ID         uuid.UUID
	URL        string
	FileName   string
	FileType   string
	FileSize   int64
	UploadedBy uuid.UUID
	CreatedAt  time.Time
}

// Write repositories
type PageWriteRepository interface {
	SavePage(ctx context.Context, p *CmsPage) error
}

type ArticleWriteRepository interface {
	SaveArticle(ctx context.Context, a *CmsArticle) error
	UpdateArticle(ctx context.Context, a *CmsArticle) error
	DeleteArticle(ctx context.Context, id uuid.UUID) error
}

type TestimonialWriteRepository interface {
	SaveTestimonial(ctx context.Context, t *CmsTestimonial) error
	UpdateTestimonial(ctx context.Context, t *CmsTestimonial) error
	DeleteTestimonial(ctx context.Context, id uuid.UUID) error
}

type FaqWriteRepository interface {
	SaveFaq(ctx context.Context, f *CmsFaq) error
	UpdateFaq(ctx context.Context, f *CmsFaq) error
	DeleteFaq(ctx context.Context, id uuid.UUID) error
}

type MediaWriteRepository interface {
	SaveMedia(ctx context.Context, m *CmsMedia) error
	DeleteMedia(ctx context.Context, id uuid.UUID) error
}

// Read repositories
type PageReadRepository interface {
	ListPages(ctx context.Context) ([]*CmsPage, error)
	GetPageBySlug(ctx context.Context, slug string) (*CmsPage, error)
}

type ArticleReadRepository interface {
	ListArticles(ctx context.Context, category, status string, offset, limit int) ([]*CmsArticle, int, error)
	GetArticleBySlug(ctx context.Context, slug string) (*CmsArticle, error)
	GetArticleByID(ctx context.Context, id uuid.UUID) (*CmsArticle, error)
}

type TestimonialReadRepository interface {
	ListTestimonials(ctx context.Context, courseID *uuid.UUID, isFeatured *bool) ([]*CmsTestimonial, error)
}

type FaqReadRepository interface {
	ListFaq(ctx context.Context, category, pageSlug string) ([]*CmsFaq, error)
}

type MediaReadRepository interface {
	ListMedia(ctx context.Context, offset, limit int) ([]*CmsMedia, int, error)
}
