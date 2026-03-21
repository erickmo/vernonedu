package update_cms_page

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateCmsPageCommand struct {
	Slug         string                 `validate:"required"`
	Title        string
	Subtitle     string
	Content      map[string]interface{}
	HeroImageURL string
	Seo          map[string]interface{}
	UpdatedBy    string // user ID string
}

type Handler struct {
	writeRepo cms.PageWriteRepository
}

func NewHandler(writeRepo cms.PageWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCmsPageCommand)
	if !ok {
		return ErrInvalidCommand
	}

	updatedByID, err := uuid.Parse(c.UpdatedBy)
	if err != nil {
		return cms.ErrInvalidSlug
	}

	page := &cms.CmsPage{
		ID:           uuid.New(),
		Slug:         c.Slug,
		Title:        c.Title,
		Subtitle:     c.Subtitle,
		Content:      c.Content,
		HeroImageURL: c.HeroImageURL,
		Seo:          c.Seo,
		UpdatedBy:    updatedByID,
		UpdatedAt:    time.Now(),
	}

	if err := h.writeRepo.SavePage(ctx, page); err != nil {
		log.Error().Err(err).Str("slug", c.Slug).Msg("failed to save cms page")
		return err
	}

	log.Info().Str("slug", c.Slug).Msg("cms page updated successfully")
	return nil
}
