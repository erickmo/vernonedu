package list_talentpool

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
)


// ListTalentPoolQuery adalah query untuk mengambil daftar TalentPool dengan filter.
type ListTalentPoolQuery struct {
	Offset         int
	Limit          int
	Status         string
	MasterCourseID uuid.UUID // uuid.Nil jika tidak ingin filter
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

// ListResult adalah hasil dari ListTalentPoolQuery.
type ListResult struct {
	Data   []*TalentPoolReadModel `json:"data"`
	Total  int                   `json:"total"`
	Offset int                   `json:"offset"`
	Limit  int                   `json:"limit"`
}

// Handler menangani ListTalentPoolQuery.
type Handler struct {
	readRepo talentpool.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo talentpool.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil daftar TalentPool.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListTalentPoolQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	entries, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status, q.MasterCourseID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list talent pool entries")
		return nil, err
	}

	readModels := make([]*TalentPoolReadModel, len(entries))
	for i, tp := range entries {
		readModels[i] = &TalentPoolReadModel{
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

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
