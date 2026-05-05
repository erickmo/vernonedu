package list_leave_requests

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type ListLeaveRequestsQuery struct {
	EmployeeID string
	Status     string
	SortBy     string
	SortDir    string
	Offset     int
	Limit      int
}

type LeaveRequestReadModel struct {
	ID         string `json:"id"`
	EmployeeID string `json:"employee_id"`
	LeaveType  string `json:"leave_type"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
	Reason     string `json:"reason"`
	Status     string `json:"status"`
	ReviewedBy string `json:"reviewed_by"`
	ReviewedAt int64  `json:"reviewed_at"`
	CreatedAt  int64  `json:"created_at"`
	UpdatedAt  int64  `json:"updated_at"`
}

type ListResult struct {
	Data   []*LeaveRequestReadModel `json:"data"`
	Total  int                      `json:"total"`
	Offset int                      `json:"offset"`
	Limit  int                      `json:"limit"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListLeaveRequestsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	var employeeID *uuid.UUID
	if q.EmployeeID != "" {
		parsed, err := uuid.Parse(q.EmployeeID)
		if err != nil {
			return nil, ErrInvalidQuery
		}
		employeeID = &parsed
	}

	requests, total, err := h.readRepo.ListLeaveRequests(ctx, employeeID, q.Status, q.SortBy, q.SortDir, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list leave requests")
		return nil, err
	}

	readModels := make([]*LeaveRequestReadModel, len(requests))
	for i, lr := range requests {
		reviewedBy := ""
		if lr.ReviewedBy != nil {
			reviewedBy = lr.ReviewedBy.String()
		}
		var reviewedAt int64
		if lr.ReviewedAt != nil {
			reviewedAt = lr.ReviewedAt.Unix()
		}
		readModels[i] = &LeaveRequestReadModel{
			ID:         lr.ID.String(),
			EmployeeID: lr.EmployeeID.String(),
			LeaveType:  lr.LeaveType,
			StartDate:  lr.StartDate.Format("2006-01-02"),
			EndDate:    lr.EndDate.Format("2006-01-02"),
			Reason:     lr.Reason,
			Status:     lr.Status,
			ReviewedBy: reviewedBy,
			ReviewedAt: reviewedAt,
			CreatedAt:  lr.CreatedAt.Unix(),
			UpdatedAt:  lr.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
