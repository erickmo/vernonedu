package get_cms_article

import (
	"context"
	"fmt"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type GetCmsArticleQuery struct {
	Slug string
}

type CmsArticleReadModel struct {
	ID               string     `json:"id"`
	Slug             string     `json:"slug"`
	Title            string     `json:"title"`
	Category         string     `json:"category"`
	Content          string     `json:"content"`
	FeaturedImageURL string     `json:"featured_image_url"`
	Status           string     `json:"status"`
	AuthorID         string     `json:"author_id"`
	PublishedAt      *time.Time `json:"published_at"`
	CreatedAt        time.Time  `json:"created_at"`
}

type Handler struct {
	readRepo cms.ArticleReadRepository
}

func NewHandler(r cms.ArticleReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCmsArticleQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	a, err := h.readRepo.GetArticleBySlug(ctx, q.Slug)
	if err != nil {
		log.Error().Err(err).Str("slug", q.Slug).Msg("failed to get cms article")
		return nil, fmt.Errorf("%w: %s", cms.ErrArticleNotFound, q.Slug)
	}

	return &CmsArticleReadModel{
		ID:               a.ID.String(),
		Slug:             a.Slug,
		Title:            a.Title,
		Category:         a.Category,
		Content:          a.Content,
		FeaturedImageURL: a.FeaturedImageURL,
		Status:           a.Status,
		AuthorID:         a.AuthorID.String(),
		PublishedAt:      a.PublishedAt,
		CreatedAt:        a.CreatedAt,
	}, nil
}
