package list_enrollment

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
)

type ListEnrollmentQuery struct {
	Offset int
	Limit  int
}

type EnrollmentReadModel struct {
	ID            uuid.UUID `json:"id"`
	StudentID     uuid.UUID `json:"student_id"`
	StudentName   string    `json:"student_name"`
	StudentPhone  string    `json:"student_phone"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	BatchName     string    `json:"batch_name"`
	CourseName    string    `json:"course_name"`
	EnrolledAt    string    `json:"enrolled_at"`
	Status        string    `json:"status"`
	PaymentStatus string    `json:"payment_status"`
	CreatedAt     int64     `json:"created_at"`
	UpdatedAt     int64     `json:"updated_at"`
}

type ListResult struct {
	Data   []*EnrollmentReadModel `json:"data"`
	Total  int                   `json:"total"`
	Offset int                   `json:"offset"`
	Limit  int                   `json:"limit"`
}

type Handler struct {
	readRepo enrollment.ReadRepository
}

func NewHandler(readRepo enrollment.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListEnrollmentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	enrollments, total, err := h.readRepo.ListEnriched(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list enrollments")
		return nil, err
	}

	readModels := make([]*EnrollmentReadModel, len(enrollments))
	for i, e := range enrollments {
		readModels[i] = &EnrollmentReadModel{
			ID:            e.ID,
			StudentID:     e.StudentID,
			StudentName:   e.StudentName,
			StudentPhone:  e.StudentPhone,
			CourseBatchID: e.CourseBatchID,
			BatchName:     e.BatchName,
			CourseName:    e.CourseName,
			EnrolledAt:    e.EnrolledAt.Format("2006-01-02T15:04:05Z07:00"),
			Status:        e.Status,
			PaymentStatus: e.PaymentStatus,
			CreatedAt:     e.CreatedAt.Unix(),
			UpdatedAt:     e.UpdatedAt.Unix(),
		}
	}

	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
