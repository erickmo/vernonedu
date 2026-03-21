package get_cms_page

import (
	"context"
	"fmt"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type GetCmsPageQuery struct {
	Slug string
}

type CmsPageReadModel struct {
	ID           string                 `json:"id"`
	Slug         string                 `json:"slug"`
	Title        string                 `json:"title"`
	Subtitle     string                 `json:"subtitle"`
	Content      map[string]interface{} `json:"content"`
	HeroImageURL string                 `json:"hero_image_url"`
	Seo          map[string]interface{} `json:"seo"`
	UpdatedAt    time.Time              `json:"updated_at"`
}

type Handler struct {
	readRepo cms.PageReadRepository
}

func NewHandler(r cms.PageReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCmsPageQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	p, err := h.readRepo.GetPageBySlug(ctx, q.Slug)
	if err != nil {
		log.Error().Err(err).Str("slug", q.Slug).Msg("failed to get cms page")
		return nil, fmt.Errorf("%w: %s", cms.ErrPageNotFound, q.Slug)
	}

	return &CmsPageReadModel{
		ID:           p.ID.String(),
		Slug:         p.Slug,
		Title:        p.Title,
		Subtitle:     p.Subtitle,
		Content:      p.Content,
		HeroImageURL: p.HeroImageURL,
		Seo:          p.Seo,
		UpdatedAt:    p.UpdatedAt,
	}, nil
}
