package list_mastercourse

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
)


// ListMasterCourseQuery adalah query untuk mengambil daftar MasterCourse dengan filter.
type ListMasterCourseQuery struct {
	Offset int
	Limit  int
	Status string
	Field  string
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
	SupportingAppUrl *string  `json:"supporting_app_url"`
	CreatedAt        int64    `json:"created_at"`
	UpdatedAt        int64    `json:"updated_at"`
}

// ListResult adalah hasil dari ListMasterCourseQuery.
type ListResult struct {
	Data   []*MasterCourseReadModel `json:"data"`
	Total  int                      `json:"total"`
	Offset int                      `json:"offset"`
	Limit  int                      `json:"limit"`
}

// Handler menangani ListMasterCourseQuery.
type Handler struct {
	readRepo mastercourse.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo mastercourse.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil daftar MasterCourse.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListMasterCourseQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	courses, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status, q.Field)
	if err != nil {
		log.Error().Err(err).Msg("failed to list master courses")
		return nil, err
	}

	readModels := make([]*MasterCourseReadModel, len(courses))
	for i, mc := range courses {
		readModels[i] = &MasterCourseReadModel{
			ID:               mc.ID.String(),
			CourseCode:       mc.CourseCode,
			CourseName:       mc.CourseName,
			Field:            mc.Field,
			CoreCompetencies: mc.CoreCompetencies,
			Description:      mc.Description,
			Status:           mc.Status,
			SupportingAppUrl: mc.SupportingAppUrl,
			CreatedAt:        mc.CreatedAt.Unix(),
			UpdatedAt:        mc.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
