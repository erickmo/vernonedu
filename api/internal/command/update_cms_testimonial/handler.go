package update_cms_testimonial

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateCmsTestimonialCommand struct {
	ID          string `validate:"required"`
	StudentName string
	CourseID    string
	Quote       string
	Rating      int
	PhotoURL    string
	IsFeatured  bool
}

type Handler struct {
	writeRepo cms.TestimonialWriteRepository
	readRepo  cms.TestimonialReadRepository
}

func NewHandler(writeRepo cms.TestimonialWriteRepository, readRepo cms.TestimonialReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCmsTestimonialCommand)
	if !ok {
		return ErrInvalidCommand
	}

	testimonialID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid testimonial id")
	}

	testimonial := &cms.CmsTestimonial{
		ID:          testimonialID,
		StudentName: c.StudentName,
		Quote:       c.Quote,
		Rating:      c.Rating,
		PhotoURL:    c.PhotoURL,
		IsFeatured:  c.IsFeatured,
	}

	if c.CourseID != "" {
		courseID, err := uuid.Parse(c.CourseID)
		if err == nil {
			testimonial.CourseID = &courseID
		}
	}

	if err := h.writeRepo.UpdateTestimonial(ctx, testimonial); err != nil {
		log.Error().Err(err).Str("testimonial_id", c.ID).Msg("failed to update cms testimonial")
		return err
	}

	log.Info().Str("testimonial_id", c.ID).Msg("cms testimonial updated successfully")
	return nil
}
