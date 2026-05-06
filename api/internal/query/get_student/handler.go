package get_student

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type GetStudentQuery struct {
	StudentID uuid.UUID
}

type StudentDetailReadModel struct {
	ID                    uuid.UUID `json:"id"`
	Name                  string    `json:"name"`
	Email                 string    `json:"email"`
	Phone                 string    `json:"phone"`
	DepartmentID          string    `json:"department_id"`
	DepartmentName        string    `json:"department_name"`
	JoinedAt              string    `json:"joined_at"`
	IsActive              bool      `json:"is_active"`
	TotalEnrollments      int       `json:"total_enrollments"`
	CompletedCourses      int       `json:"completed_courses"`
	Address               string    `json:"address"`
	City                  string    `json:"city"`
	Province              string    `json:"province"`
	PostalCode            string    `json:"postal_code"`
	BirthDate             string    `json:"birth_date"` // "YYYY-MM-DD" or ""
	Gender                string    `json:"gender"`
	NIK                   string    `json:"nik"`
	PhotoURL              string    `json:"photo_url"`
	EducationLevel        string    `json:"education_level"`
	SchoolName            string    `json:"school_name"`
	EmergencyContactName  string    `json:"emergency_contact_name"`
	EmergencyContactPhone string    `json:"emergency_contact_phone"`
	CreatedAt             int64     `json:"created_at"`
	UpdatedAt             int64     `json:"updated_at"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetStudentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	s, err := h.readRepo.GetDetail(ctx, q.StudentID)
	if err != nil {
		log.Error().Err(err).Str("student_id", q.StudentID.String()).Msg("failed to get student")
		return nil, err
	}

	deptID := ""
	if s.DepartmentID != nil {
		deptID = s.DepartmentID.String()
	}

	birthDate := ""
	if s.BirthDate != nil {
		birthDate = s.BirthDate.Format("2006-01-02")
	}

	return &StudentDetailReadModel{
		ID:                    s.ID,
		Name:                  s.Name,
		Email:                 s.Email,
		Phone:                 s.Phone,
		DepartmentID:          deptID,
		DepartmentName:        s.DepartmentName,
		JoinedAt:              s.JoinedAt.Format("2006-01-02T15:04:05Z07:00"),
		IsActive:              s.IsActive,
		TotalEnrollments:      s.TotalEnrollments,
		CompletedCourses:      s.CompletedCourses,
		Address:               s.Address,
		City:                  s.City,
		Province:              s.Province,
		PostalCode:            s.PostalCode,
		BirthDate:             birthDate,
		Gender:                s.Gender,
		NIK:                   s.NIK,
		PhotoURL:              s.PhotoURL,
		EducationLevel:        s.EducationLevel,
		SchoolName:            s.SchoolName,
		EmergencyContactName:  s.EmergencyContactName,
		EmergencyContactPhone: s.EmergencyContactPhone,
		CreatedAt:             s.CreatedAt.Unix(),
		UpdatedAt:             s.UpdatedAt.Unix(),
	}, nil
}
