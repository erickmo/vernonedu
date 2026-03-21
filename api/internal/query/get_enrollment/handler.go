package get_enrollment

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
)

type GetEnrollmentQuery struct {
	EnrollmentID uuid.UUID
}

type EnrollmentReadModel struct {
	ID            uuid.UUID `json:"id"`
	StudentID     uuid.UUID `json:"student_id"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	EnrolledAt    string    `json:"enrolled_at"`
	Status        string    `json:"status"`
	PaymentStatus string    `json:"payment_status"`
	CreatedAt     int64     `json:"created_at"`
	UpdatedAt     int64     `json:"updated_at"`
}

type Handler struct {
	readRepo enrollment.ReadRepository
}

func NewHandler(readRepo enrollment.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetEnrollmentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	e, err := h.readRepo.GetByID(ctx, q.EnrollmentID)
	if err != nil {
		log.Error().Err(err).Str("enrollment_id", q.EnrollmentID.String()).Msg("failed to get enrollment")
		return nil, err
	}

	readModel := &EnrollmentReadModel{
		ID:            e.ID,
		StudentID:     e.StudentID,
		CourseBatchID: e.CourseBatchID,
		EnrolledAt:    e.EnrolledAt.Format("2006-01-02T15:04:05Z07:00"),
		Status:        e.Status,
		PaymentStatus: e.PaymentStatus,
		CreatedAt:     e.CreatedAt.Unix(),
		UpdatedAt:     e.UpdatedAt.Unix(),
	}

	return readModel, nil
}
