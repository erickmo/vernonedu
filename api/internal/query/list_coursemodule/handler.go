package list_coursemodule

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursemodule"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// ListCourseModuleQuery adalah query untuk mengambil daftar CourseModule dari satu CourseVersion.
type ListCourseModuleQuery struct {
	CourseVersionID uuid.UUID
}

// CourseModuleReadModel adalah model baca untuk CourseModule.
type CourseModuleReadModel struct {
	ID                  string   `json:"id"`
	CourseVersionID     string   `json:"course_version_id"`
	ModuleCode          string   `json:"module_code"`
	ModuleTitle         string   `json:"module_title"`
	DurationHours       float64  `json:"duration_hours"`
	Sequence            int      `json:"sequence"`
	ContentDepth        string   `json:"content_depth"`
	Topics              []string `json:"topics"`
	PracticalActivities []string `json:"practical_activities"`
	AssessmentMethod    string   `json:"assessment_method"`
	ToolsRequired       []string `json:"tools_required"`
	IsReference         bool     `json:"is_reference"`
	RefModuleID         *string  `json:"ref_module_id"`
	CreatedAt           int64    `json:"created_at"`
	UpdatedAt           int64    `json:"updated_at"`
}

// Handler menangani ListCourseModuleQuery.
type Handler struct {
	readRepo coursemodule.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo coursemodule.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil daftar CourseModule diurut berdasarkan sequence.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCourseModuleQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	modules, err := h.readRepo.ListByVersion(ctx, q.CourseVersionID)
	if err != nil {
		log.Error().Err(err).Str("course_version_id", q.CourseVersionID.String()).Msg("failed to list course modules")
		return nil, err
	}

	readModels := make([]*CourseModuleReadModel, len(modules))
	for i, cm := range modules {
		rm := &CourseModuleReadModel{
			ID:                  cm.ID.String(),
			CourseVersionID:     cm.CourseVersionID.String(),
			ModuleCode:          cm.ModuleCode,
			ModuleTitle:         cm.ModuleTitle,
			DurationHours:       cm.DurationHours,
			Sequence:            cm.Sequence,
			ContentDepth:        cm.ContentDepth,
			Topics:              cm.Topics,
			PracticalActivities: cm.PracticalActivities,
			AssessmentMethod:    cm.AssessmentMethod,
			ToolsRequired:       cm.ToolsRequired,
			IsReference:         cm.IsReference,
			CreatedAt:           cm.CreatedAt.Unix(),
			UpdatedAt:           cm.UpdatedAt.Unix(),
		}
		if cm.RefModuleID != nil {
			s := cm.RefModuleID.String()
			rm.RefModuleID = &s
		}
		readModels[i] = rm
	}

	return readModels, nil
}
