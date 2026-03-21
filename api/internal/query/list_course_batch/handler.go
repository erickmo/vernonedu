package list_course_batch

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
)

type ListCourseBatchQuery struct {
	Offset int
	Limit  int
}

type CourseBatchReadModel struct {
	ID              string `json:"id"`
	CourseID        string `json:"course_id"`
	MasterCourseID  string `json:"master_course_id"`
	Code            string `json:"code"`
	Name            string `json:"name"`
	StartDate       string `json:"start_date"`
	EndDate         string `json:"end_date"`
	FacilitatorID   string `json:"facilitator_id"`
	FacilitatorName string `json:"facilitator_name"`
	MinParticipants int    `json:"min_participants"`
	MaxParticipants int    `json:"max_participants"`
	WebsiteVisible  bool   `json:"website_visible"`
	Price           int64  `json:"price"`
	PaymentMethod   string `json:"payment_method"`
	IsActive        bool   `json:"is_active"`
	Status          string `json:"status"`
	EnrollmentCount int    `json:"enrollment_count"`
	CreatedAt       int64  `json:"created_at"`
	UpdatedAt       int64  `json:"updated_at"`
}

type ListResult struct {
	Data   []*CourseBatchReadModel `json:"data"`
	Total  int                    `json:"total"`
	Offset int                    `json:"offset"`
	Limit  int                    `json:"limit"`
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
	q, ok := query.(*ListCourseBatchQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	batches, total, err := h.courseBatchReadRepo.ListEnriched(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list course batches")
		return nil, err
	}

	readModels := make([]*CourseBatchReadModel, len(batches))
	for i, cb := range batches {
		facilitatorID := ""
		if cb.FacilitatorID != nil {
			facilitatorID = cb.FacilitatorID.String()
		}
		masterCourseID := ""
		if cb.MasterCourseID != nil {
			masterCourseID = cb.MasterCourseID.String()
		}
		readModels[i] = &CourseBatchReadModel{
			ID:              cb.ID.String(),
			CourseID:        cb.CourseID.String(),
			MasterCourseID:  masterCourseID,
			Code:            cb.Code,
			Name:            cb.Name,
			StartDate:       cb.StartDate.Format("2006-01-02T15:04:05Z07:00"),
			EndDate:         cb.EndDate.Format("2006-01-02T15:04:05Z07:00"),
			FacilitatorID:   facilitatorID,
			FacilitatorName: cb.FacilitatorName,
			MinParticipants: cb.MinParticipants,
			MaxParticipants: cb.MaxParticipants,
			WebsiteVisible:  cb.WebsiteVisible,
			Price:           cb.Price,
			PaymentMethod:   cb.PaymentMethod,
			IsActive:        cb.IsActive,
			Status:          cb.Status,
			EnrollmentCount: cb.EnrollmentCount,
			CreatedAt:       cb.CreatedAt.Unix(),
			UpdatedAt:       cb.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
