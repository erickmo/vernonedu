package delete_cms_testimonial

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type DeleteCmsTestimonialCommand struct {
	ID string `validate:"required"`
}

type Handler struct {
	writeRepo cms.TestimonialWriteRepository
}

func NewHandler(writeRepo cms.TestimonialWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCmsTestimonialCommand)
	if !ok {
		return ErrInvalidCommand
	}

	testimonialID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid testimonial id")
	}

	if err := h.writeRepo.DeleteTestimonial(ctx, testimonialID); err != nil {
		log.Error().Err(err).Str("testimonial_id", c.ID).Msg("failed to delete cms testimonial")
		return err
	}

	log.Info().Str("testimonial_id", c.ID).Msg("cms testimonial deleted successfully")
	return nil
}
