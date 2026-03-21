package list_cms_pages

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type ListCmsPagesQuery struct{}

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
	_, ok := query.(*ListCmsPagesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	pages, err := h.readRepo.ListPages(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms pages")
		return nil, err
	}

	result := make([]*CmsPageReadModel, len(pages))
	for i, p := range pages {
		result[i] = &CmsPageReadModel{
			ID:           p.ID.String(),
			Slug:         p.Slug,
			Title:        p.Title,
			Subtitle:     p.Subtitle,
			Content:      p.Content,
			HeroImageURL: p.HeroImageURL,
			Seo:          p.Seo,
			UpdatedAt:    p.UpdatedAt,
		}
	}

	return result, nil
}
