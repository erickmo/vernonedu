package get_talentpool

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
)


// GetTalentPoolQuery adalah query untuk mengambil satu TalentPool berdasarkan ID.
type GetTalentPoolQuery struct {
	TalentPoolID uuid.UUID
}

// TalentPoolReadModel adalah model baca untuk TalentPool.
type TalentPoolReadModel struct {
	ID                  string                       `json:"id"`
	ParticipantID       string                       `json:"participant_id"`
	ParticipantName     string                       `json:"participant_name"`
	ParticipantEmail    string                       `json:"participant_email"`
	MasterCourseID      string                       `json:"master_course_id"`
	CourseTypeID        string                       `json:"course_type_id"`
	CourseVersionID     string                       `json:"course_version_id"`
	CharacterTestResult map[string]interface{}       `json:"character_test_result"`
	TestScore           *float64                     `json:"test_score"`
	TalentpoolStatus    string                       `json:"talentpool_status"`
	PlacementHistory    []talentpool.PlacementRecord `json:"placement_history"`
	JoinedAt            int64                        `json:"joined_at"`
	UpdatedAt           int64                        `json:"updated_at"`
}

// Handler menangani GetTalentPoolQuery.
type Handler struct {
	readRepo talentpool.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo talentpool.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil satu TalentPool.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetTalentPoolQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	tp, err := h.readRepo.GetByID(ctx, q.TalentPoolID)
	if err != nil {
		log.Error().Err(err).Str("talent_pool_id", q.TalentPoolID.String()).Msg("failed to get talent pool entry")
		return nil, err
	}

	return toReadModel(tp), nil
}

// toReadModel mengonversi domain entity ke read model.
func toReadModel(tp *talentpool.TalentPool) *TalentPoolReadModel {
	return &TalentPoolReadModel{
		ID:                  tp.ID.String(),
		ParticipantID:       tp.ParticipantID.String(),
		ParticipantName:     tp.ParticipantName,
		ParticipantEmail:    tp.ParticipantEmail,
		MasterCourseID:      tp.MasterCourseID.String(),
		CourseTypeID:        tp.CourseTypeID.String(),
		CourseVersionID:     tp.CourseVersionID.String(),
		CharacterTestResult: tp.CharacterTestResult,
		TestScore:           tp.TestScore,
		TalentpoolStatus:    tp.TalentpoolStatus,
		PlacementHistory:    tp.PlacementHistory,
		JoinedAt:            tp.JoinedAt.Unix(),
		UpdatedAt:           tp.UpdatedAt.Unix(),
	}
}
