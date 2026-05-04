package get_attendance_summary

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type AttendanceSummaryQuery struct {
	Period string `validate:"required"`
}

type AttendanceSummaryReadModel struct {
	EmployeeID    string `json:"employee_id"`
	EmployeeName  string `json:"employee_name"`
	PresentDays   int    `json:"present_days"`
	AbsentDays    int    `json:"absent_days"`
	LateDays      int    `json:"late_days"`
	LeaveDays     int    `json:"leave_days"`
	TotalWorkDays int    `json:"total_work_days"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*AttendanceSummaryQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	summaries, err := h.readRepo.GetAttendanceSummary(ctx, q.Period)
	if err != nil {
		log.Error().Err(err).Msg("failed to get attendance summary")
		return nil, err
	}

	readModels := make([]*AttendanceSummaryReadModel, len(summaries))
	for i, s := range summaries {
		readModels[i] = &AttendanceSummaryReadModel{
			EmployeeID:    s.EmployeeID.String(),
			EmployeeName:  s.EmployeeName,
			PresentDays:   s.PresentDays,
			AbsentDays:    s.AbsentDays,
			LateDays:      s.LateDays,
			LeaveDays:     s.LeaveDays,
			TotalWorkDays: s.TotalWorkDays,
		}
	}

	return readModels, nil
}
