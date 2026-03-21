package create_cms_testimonial

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type CreateCmsTestimonialCommand struct {
	StudentName string `validate:"required"`
	CourseID    string // optional, can be ""
	Quote       string `validate:"required"`
	Rating      int    `validate:"required,min=1,max=5"`
	PhotoURL    string
	IsFeatured  bool
}

type Handler struct {
	writeRepo cms.TestimonialWriteRepository
}

func NewHandler(writeRepo cms.TestimonialWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCmsTestimonialCommand)
	if !ok {
		return ErrInvalidCommand
	}

	testimonial := &cms.CmsTestimonial{
		ID:          uuid.New(),
		StudentName: c.StudentName,
		Quote:       c.Quote,
		Rating:      c.Rating,
		PhotoURL:    c.PhotoURL,
		IsFeatured:  c.IsFeatured,
		CreatedAt:   time.Now(),
	}

	if c.CourseID != "" {
		courseID, err := uuid.Parse(c.CourseID)
		if err == nil {
			testimonial.CourseID = &courseID
		}
	}

	if err := h.writeRepo.SaveTestimonial(ctx, testimonial); err != nil {
		log.Error().Err(err).Str("student_name", c.StudentName).Msg("failed to save cms testimonial")
		return err
	}

	log.Info().Str("testimonial_id", testimonial.ID.String()).Msg("cms testimonial created successfully")
	return nil
}
