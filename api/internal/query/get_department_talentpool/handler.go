package getdepartmenttalentpool

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type GetDepartmentTalentPoolQuery struct {
	DepartmentID string
}

type DepartmentTalentPoolReadModel struct {
	ID               string   `json:"id"`
	ParticipantID    string   `json:"participant_id"`
	ParticipantName  string   `json:"participant_name"`
	ParticipantEmail string   `json:"participant_email"`
	Status           string   `json:"status"`
	JoinedAt         int64    `json:"joined_at"`
	TestScore        *float64 `json:"test_score"`
}

type Handler struct {
	repo department.ReadRepository
}

func NewHandler(repo department.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	query, ok := q.(*GetDepartmentTalentPoolQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	deptID, err := uuid.Parse(query.DepartmentID)
	if err != nil {
		return nil, fmt.Errorf("invalid department id: %w", err)
	}

	entries, err := h.repo.GetTalentPoolEntries(ctx, deptID)
	if err != nil {
		return nil, fmt.Errorf("get department talentpool: %w", err)
	}

	result := make([]*DepartmentTalentPoolReadModel, len(entries))
	for i, e := range entries {
		result[i] = &DepartmentTalentPoolReadModel{
			ID:               e.ID.String(),
			ParticipantID:    e.ParticipantID.String(),
			ParticipantName:  e.ParticipantName,
			ParticipantEmail: e.ParticipantEmail,
			Status:           e.Status,
			JoinedAt:         e.JoinedAt.Unix(),
			TestScore:        e.TestScore,
		}
	}
	return result, nil
}
