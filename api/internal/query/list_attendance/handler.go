package list_attendance

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type ListAttendanceQuery struct {
	EmployeeID string
	From       string
	To         string
	Status     string
	Offset     int
	Limit      int
}

type AttendanceReadModel struct {
	ID         string `json:"id"`
	EmployeeID string `json:"employee_id"`
	Date       string `json:"date"`
	Status     string `json:"status"`
	ClockIn    string `json:"clock_in"`
	ClockOut   string `json:"clock_out"`
	Note       string `json:"note"`
	CreatedAt  int64  `json:"created_at"`
	UpdatedAt  int64  `json:"updated_at"`
}

type ListResult struct {
	Data   []*AttendanceReadModel `json:"data"`
	Total  int                    `json:"total"`
	Offset int                    `json:"offset"`
	Limit  int                    `json:"limit"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListAttendanceQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	var employeeID uuid.UUID
	if q.EmployeeID != "" {
		var err error
		employeeID, err = uuid.Parse(q.EmployeeID)
		if err != nil {
			return nil, ErrInvalidQuery
		}
	}

	from := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
	to := time.Now()
	if q.From != "" {
		parsed, err := time.Parse("2006-01-02", q.From)
		if err == nil {
			from = parsed
		}
	}
	if q.To != "" {
		parsed, err := time.Parse("2006-01-02", q.To)
		if err == nil {
			to = parsed
		}
	}

	records, err := h.readRepo.GetAttendanceByRange(ctx, employeeID, from, to)
	if err != nil {
		log.Error().Err(err).Msg("failed to list attendance")
		return nil, err
	}

	// Filter by status if provided
	filtered := records
	if q.Status != "" {
		var filteredTmp []*hrm.StaffAttendance
		for _, a := range records {
			if a.Status == q.Status {
				filteredTmp = append(filteredTmp, a)
			}
		}
		filtered = filteredTmp
	}

	// Apply pagination
	total := len(filtered)
	start := q.Offset
	if start > total {
		start = total
	}
	end := start + q.Limit
	if q.Limit == 0 {
		end = total
	}
	if end > total {
		end = total
	}
	page := filtered[start:end]

	readModels := make([]*AttendanceReadModel, len(page))
	for i, a := range page {
		clockIn := ""
		if a.ClockIn != nil {
			clockIn = a.ClockIn.Format(time.RFC3339)
		}
		clockOut := ""
		if a.ClockOut != nil {
			clockOut = a.ClockOut.Format(time.RFC3339)
		}
		readModels[i] = &AttendanceReadModel{
			ID:         a.ID.String(),
			EmployeeID: a.EmployeeID.String(),
			Date:       a.Date.Format("2006-01-02"),
			Status:     a.Status,
			ClockIn:    clockIn,
			ClockOut:   clockOut,
			Note:       a.Note,
			CreatedAt:  a.CreatedAt.Unix(),
			UpdatedAt:  a.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
