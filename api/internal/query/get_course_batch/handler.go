package get_course_batch

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
)

type GetCourseBatchQuery struct {
	CourseBatchID uuid.UUID
}

type CourseBatchReadModel struct {
	ID              uuid.UUID `json:"id"`
	CourseID        string    `json:"course_id"`
	MasterCourseID  string    `json:"master_course_id"`
	Code            string    `json:"code"`
	Name            string    `json:"name"`
	StartDate       string    `json:"start_date"`
	EndDate         string    `json:"end_date"`
	FacilitatorID   string    `json:"facilitator_id"`
	MinParticipants int       `json:"min_participants"`
	MaxParticipants int       `json:"max_participants"`
	WebsiteVisible  bool      `json:"website_visible"`
	Price           int64     `json:"price"`
	PaymentMethod   string    `json:"payment_method"`
	IsActive        bool      `json:"is_active"`
	Status          string    `json:"status"`
	CreatedAt       int64     `json:"created_at"`
	UpdatedAt       int64     `json:"updated_at"`
}

type Handler struct {
	courseBatchReadRepo coursebatch.ReadRepository
}

func NewHandler(courseBatchReadRepo coursebatch.ReadRepository) *Handler {
	return &Handler{
		courseBatchReadRepo: courseBatchReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCourseBatchQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	cb, err := h.courseBatchReadRepo.GetByID(ctx, q.CourseBatchID)
	if err != nil {
		log.Error().Err(err).Str("course_batch_id", q.CourseBatchID.String()).Msg("failed to get course batch")
		return nil, err
	}

	facilitatorID := ""
	if cb.FacilitatorID != nil {
		facilitatorID = cb.FacilitatorID.String()
	}

	masterCourseID := ""
	if cb.MasterCourseID != nil {
		masterCourseID = cb.MasterCourseID.String()
	}

	readModel := &CourseBatchReadModel{
		ID:              cb.ID,
		CourseID:        cb.CourseID.String(),
		MasterCourseID:  masterCourseID,
		Code:            cb.Code,
		Name:            cb.Name,
		StartDate:       cb.StartDate.Format("2006-01-02T15:04:05Z07:00"),
		EndDate:         cb.EndDate.Format("2006-01-02T15:04:05Z07:00"),
		FacilitatorID:   facilitatorID,
		MinParticipants: cb.MinParticipants,
		MaxParticipants: cb.MaxParticipants,
		WebsiteVisible:  cb.WebsiteVisible,
		Price:           cb.Price,
		PaymentMethod:   cb.PaymentMethod,
		IsActive:        cb.IsActive,
		Status:          cb.Status,
		CreatedAt:       cb.CreatedAt.Unix(),
		UpdatedAt:       cb.UpdatedAt.Unix(),
	}

	return readModel, nil
}
