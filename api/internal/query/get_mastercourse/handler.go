package get_mastercourse

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
)


// GetMasterCourseQuery adalah query untuk mengambil satu MasterCourse berdasarkan ID.
type GetMasterCourseQuery struct {
	MasterCourseID uuid.UUID
}

// MasterCourseReadModel adalah model baca untuk MasterCourse.
type MasterCourseReadModel struct {
	ID               string   `json:"id"`
	CourseCode       string   `json:"course_code"`
	CourseName       string   `json:"course_name"`
	Field            string   `json:"field"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	Status           string   `json:"status"`
	CreatedAt        int64    `json:"created_at"`
	UpdatedAt        int64    `json:"updated_at"`
}

// Handler menangani GetMasterCourseQuery.
type Handler struct {
	readRepo mastercourse.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo mastercourse.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil satu MasterCourse.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetMasterCourseQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	mc, err := h.readRepo.GetByID(ctx, q.MasterCourseID)
	if err != nil {
		log.Error().Err(err).Str("master_course_id", q.MasterCourseID.String()).Msg("failed to get master course")
		return nil, err
	}

	return toReadModel(mc), nil
}

// toReadModel mengonversi domain entity ke read model.
func toReadModel(mc *mastercourse.MasterCourse) *MasterCourseReadModel {
	return &MasterCourseReadModel{
		ID:               mc.ID.String(),
		CourseCode:       mc.CourseCode,
		CourseName:       mc.CourseName,
		Field:            mc.Field,
		CoreCompetencies: mc.CoreCompetencies,
		Description:      mc.Description,
		Status:           mc.Status,
		CreatedAt:        mc.CreatedAt.Unix(),
		UpdatedAt:        mc.UpdatedAt.Unix(),
	}
}
