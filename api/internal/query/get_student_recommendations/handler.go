package get_student_recommendations

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type GetStudentRecommendationsQuery struct {
	StudentID string
}

type RecommendationReadModel struct {
	MasterCourseID string `json:"master_course_id"`
	CourseName     string `json:"course_name"`
	CourseCode     string `json:"course_code"`
	Field          string `json:"field"`
	Reason         string `json:"reason"`
	HasActiveBatch bool   `json:"has_active_batch"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetStudentRecommendationsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	studentID, err := uuid.Parse(q.StudentID)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	items, err := h.readRepo.GetRecommendations(ctx, studentID)
	if err != nil {
		log.Error().Err(err).Str("student_id", q.StudentID).Msg("failed to get recommendations")
		return nil, err
	}

	result := make([]*RecommendationReadModel, len(items))
	for i, item := range items {
		result[i] = &RecommendationReadModel{
			MasterCourseID: item.MasterCourseID.String(),
			CourseName:     item.CourseName,
			CourseCode:     item.CourseCode,
			Field:          item.Field,
			Reason:         item.Reason,
			HasActiveBatch: item.HasActiveBatch,
		}
	}

	return result, nil
}
