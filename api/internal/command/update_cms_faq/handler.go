package update_cms_faq

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateCmsFaqCommand struct {
	ID        string   `validate:"required"`
	Question  string
	Answer    string
	Category  string
	PageSlugs []string
	SortOrder int
}

type Handler struct {
	writeRepo cms.FaqWriteRepository
	readRepo  cms.FaqReadRepository
}

func NewHandler(writeRepo cms.FaqWriteRepository, readRepo cms.FaqReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCmsFaqCommand)
	if !ok {
		return ErrInvalidCommand
	}

	faqID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid faq id")
	}

	pageSlugs := c.PageSlugs
	if pageSlugs == nil {
		pageSlugs = []string{}
	}

	faq := &cms.CmsFaq{
		ID:        faqID,
		Question:  c.Question,
		Answer:    c.Answer,
		Category:  c.Category,
		PageSlugs: pageSlugs,
		SortOrder: c.SortOrder,
		UpdatedAt: time.Now(),
	}

	if err := h.writeRepo.UpdateFaq(ctx, faq); err != nil {
		log.Error().Err(err).Str("faq_id", c.ID).Msg("failed to update cms faq")
		return err
	}

	log.Info().Str("faq_id", c.ID).Msg("cms faq updated successfully")
	return nil
}
