package list_cms_testimonials

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type ListCmsTestimonialsQuery struct {
	CourseID   string // optional, empty = no filter
	IsFeatured *bool  // optional, nil = no filter
}

type CmsTestimonialReadModel struct {
	ID          string    `json:"id"`
	StudentName string    `json:"student_name"`
	CourseID    *string   `json:"course_id"`
	Quote       string    `json:"quote"`
	Rating      int       `json:"rating"`
	PhotoURL    string    `json:"photo_url"`
	IsFeatured  bool      `json:"is_featured"`
	CreatedAt   time.Time `json:"created_at"`
}

type Handler struct {
	readRepo cms.TestimonialReadRepository
}

func NewHandler(r cms.TestimonialReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCmsTestimonialsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	var courseID *uuid.UUID
	if q.CourseID != "" {
		id, err := uuid.Parse(q.CourseID)
		if err == nil {
			courseID = &id
		}
	}

	testimonials, err := h.readRepo.ListTestimonials(ctx, courseID, q.IsFeatured)
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms testimonials")
		return nil, err
	}

	result := make([]*CmsTestimonialReadModel, len(testimonials))
	for i, t := range testimonials {
		var cid *string
		if t.CourseID != nil {
			s := t.CourseID.String()
			cid = &s
		}
		result[i] = &CmsTestimonialReadModel{
			ID:          t.ID.String(),
			StudentName: t.StudentName,
			CourseID:    cid,
			Quote:       t.Quote,
			Rating:      t.Rating,
			PhotoURL:    t.PhotoURL,
			IsFeatured:  t.IsFeatured,
			CreatedAt:   t.CreatedAt,
		}
	}

	return result, nil
}
