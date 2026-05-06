package list_student

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type ListStudentQuery struct {
	Offset int
	Limit  int
	Search string
	Sort   string
}

type StudentReadModel struct {
	ID                    uuid.UUID `json:"id"`
	Name                  string    `json:"name"`
	Email                 string    `json:"email"`
	Phone                 string    `json:"phone"`
	DepartmentID          string    `json:"department_id"`
	JoinedAt              string    `json:"joined_at"`
	IsActive              bool      `json:"is_active"`
	ActiveBatchCount      int       `json:"active_batch_count"`
	CompletedCourseCount  int       `json:"completed_course_count"`
	Address               string    `json:"address"`
	City                  string    `json:"city"`
	Province              string    `json:"province"`
	PostalCode            string    `json:"postal_code"`
	BirthDate             string    `json:"birth_date"`
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

type ListResult struct {
	Data   []*StudentReadModel `json:"data"`
	Total  int                 `json:"total"`
	Offset int                 `json:"offset"`
	Limit  int                 `json:"limit"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
	q, ok := query.(*ListStudentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	students, total, err := h.readRepo.ListWithCounts(ctx, q.Offset, q.Limit, q.Search, q.Sort)
	if err != nil {
		log.Error().Err(err).Msg("failed to list students")
		return nil, err
	}

	readModels := make([]*StudentReadModel, len(students))
	for i, s := range students {
		deptID := ""
		if s.DepartmentID != nil {
			deptID = s.DepartmentID.String()
		}
		birthDate := ""
		if s.BirthDate != nil {
			birthDate = s.BirthDate.Format("2006-01-02")
		}
		readModels[i] = &StudentReadModel{
			ID:                    s.ID,
			Name:                  s.Name,
			Email:                 s.Email,
			Phone:                 s.Phone,
			DepartmentID:          deptID,
			JoinedAt:              s.JoinedAt.Format("2006-01-02T15:04:05Z07:00"),
			IsActive:              s.IsActive,
			ActiveBatchCount:      s.ActiveBatchCount,
			CompletedCourseCount:  s.CompletedCourseCount,
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
		}
	}

	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
