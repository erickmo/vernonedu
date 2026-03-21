package delete_cms_faq

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type DeleteCmsFaqCommand struct {
	ID string `validate:"required"`
}

type Handler struct {
	writeRepo cms.FaqWriteRepository
}

func NewHandler(writeRepo cms.FaqWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCmsFaqCommand)
	if !ok {
		return ErrInvalidCommand
	}

	faqID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid faq id")
	}

	if err := h.writeRepo.DeleteFaq(ctx, faqID); err != nil {
		log.Error().Err(err).Str("faq_id", c.ID).Msg("failed to delete cms faq")
		return err
	}

	log.Info().Str("faq_id", c.ID).Msg("cms faq deleted successfully")
	return nil
}
