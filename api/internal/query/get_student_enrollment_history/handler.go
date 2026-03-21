package get_student_enrollment_history

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type GetStudentEnrollmentHistoryQuery struct {
	StudentID string
}

type EnrollmentHistoryReadModel struct {
	ID               uuid.UUID `json:"id"`
	BatchID          uuid.UUID `json:"batch_id"`
	BatchCode        string    `json:"batch_code"`
	BatchName        string    `json:"batch_name"`
	BatchType        string    `json:"batch_type"`
	CourseName       string    `json:"course_name"`
	CourseCode       string    `json:"course_code"`
	MasterCourseName string    `json:"master_course_name"`
	EnrolledAt       string    `json:"enrolled_at"`
	TotalAttendance  int       `json:"total_attendance"`
	TotalSessions    int       `json:"total_sessions"`
	FinalScore       *float64  `json:"final_score"`
	Grade            *string   `json:"grade"`
	Status           string    `json:"status"`
	PaymentStatus    string    `json:"payment_status"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetStudentEnrollmentHistoryQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	studentID, err := uuid.Parse(q.StudentID)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	items, err := h.readRepo.GetEnrollmentHistory(ctx, studentID)
	if err != nil {
		log.Error().Err(err).Str("student_id", q.StudentID).Msg("failed to get enrollment history")
		return nil, err
	}

	result := make([]*EnrollmentHistoryReadModel, len(items))
	for i, item := range items {
		result[i] = &EnrollmentHistoryReadModel{
			ID:               item.ID,
			BatchID:          item.BatchID,
			BatchCode:        item.BatchCode,
			BatchName:        item.BatchName,
			BatchType:        item.BatchType,
			CourseName:       item.CourseName,
			CourseCode:       item.CourseCode,
			MasterCourseName: item.MasterCourseName,
			EnrolledAt:       item.EnrolledAt.Format("2006-01-02T15:04:05Z07:00"),
			TotalAttendance:  item.TotalAttendance,
			TotalSessions:    item.TotalSessions,
			FinalScore:       item.FinalScore,
			Grade:            item.Grade,
			Status:           item.Status,
			PaymentStatus:    item.PaymentStatus,
		}
	}

	return result, nil
}
