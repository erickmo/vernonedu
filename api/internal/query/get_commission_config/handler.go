package get_commission_config

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// CommissionConfigReadModel is the response shape for commission config.
type CommissionConfigReadModel struct {
	OpLeaderPct        float64 `json:"op_leader_pct"`
	OpLeaderBasis      string  `json:"op_leader_basis"`
	DeptLeaderPct      float64 `json:"dept_leader_pct"`
	DeptLeaderBasis    string  `json:"dept_leader_basis"`
	CourseCreatorPct   float64 `json:"course_creator_pct"`
	CourseCreatorBasis string  `json:"course_creator_basis"`
	UpdatedAt          int64   `json:"updated_at"`
}

type Handler struct {
	readRepo settings.CommissionReadRepository
}

func NewHandler(readRepo settings.CommissionReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*GetCommissionConfigQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	cfg, err := h.readRepo.Get(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to get commission config")
		return nil, err
	}

	return &CommissionConfigReadModel{
		OpLeaderPct:        cfg.OpLeaderPct,
		OpLeaderBasis:      cfg.OpLeaderBasis,
		DeptLeaderPct:      cfg.DeptLeaderPct,
		DeptLeaderBasis:    cfg.DeptLeaderBasis,
		CourseCreatorPct:   cfg.CourseCreatorPct,
		CourseCreatorBasis: cfg.CourseCreatorBasis,
		UpdatedAt:          cfg.UpdatedAt.Unix(),
	}, nil
}
