package create_cms_faq

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type CreateCmsFaqCommand struct {
	Question  string   `validate:"required"`
	Answer    string   `validate:"required"`
	Category  string   `validate:"required"`
	PageSlugs []string
	SortOrder int
}

type Handler struct {
	writeRepo cms.FaqWriteRepository
}

func NewHandler(writeRepo cms.FaqWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCmsFaqCommand)
	if !ok {
		return ErrInvalidCommand
	}

	pageSlugs := c.PageSlugs
	if pageSlugs == nil {
		pageSlugs = []string{}
	}

	now := time.Now()
	faq := &cms.CmsFaq{
		ID:        uuid.New(),
		Question:  c.Question,
		Answer:    c.Answer,
		Category:  c.Category,
		PageSlugs: pageSlugs,
		SortOrder: c.SortOrder,
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := h.writeRepo.SaveFaq(ctx, faq); err != nil {
		log.Error().Err(err).Str("question", c.Question).Msg("failed to save cms faq")
		return err
	}

	log.Info().Str("faq_id", faq.ID.String()).Msg("cms faq created successfully")
	return nil
}
