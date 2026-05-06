package list_job_vacancies

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
)

type JobVacancyReadModel struct {
	ID              uuid.UUID  `json:"id"`
	Title           string     `json:"title"`
	Description     string     `json:"description"`
	PartnerID       uuid.UUID  `json:"partner_id"`
	DepartmentID    *uuid.UUID `json:"department_id"`
	Location        string     `json:"location"`
	Type            string     `json:"type"`
	Status          string     `json:"status"`
	ExperienceLevel string     `json:"experience_level"`
	Slots           int        `json:"slots"`
	MinSalary       *int64     `json:"min_salary"`
	MaxSalary       *int64     `json:"max_salary"`
	RequiredSkills  []string   `json:"required_skills"`
	Deadline        *int64     `json:"deadline"`
	CreatedBy       uuid.UUID  `json:"created_by"`
	CreatedAt       int64      `json:"created_at"`
	UpdatedAt       int64      `json:"updated_at"`
}

type ListResult struct {
	Data   []*JobVacancyReadModel `json:"data"`
	Total  int                   `json:"total"`
	Offset int                   `json:"offset"`
	Limit  int                   `json:"limit"`
}

type Handler struct {
	readRepo job_vacancy.ReadRepository
}

func NewHandler(readRepo job_vacancy.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

var ErrInvalidQuery = errors.New("invalid query type for list_job_vacancies")

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
	q, ok := query.(*ListJobVacanciesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	vacancies, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status, q.PartnerID, q.Type, q.Search, q.SortBy, q.SortDir)
	if err != nil {
		log.Error().Err(err).Msg("failed to list job vacancies")
		return nil, err
	}
	readModels := make([]*JobVacancyReadModel, len(vacancies))
	for i, v := range vacancies {
		rm := &JobVacancyReadModel{
			ID: v.ID, Title: v.Title, Description: v.Description,
			PartnerID: v.PartnerID, DepartmentID: v.DepartmentID,
			Location: v.Location, Type: v.Type, Status: v.Status,
			ExperienceLevel: v.ExperienceLevel, Slots: v.Slots,
			MinSalary: v.MinSalary, MaxSalary: v.MaxSalary,
			RequiredSkills: v.RequiredSkills,
			CreatedBy:      v.CreatedBy,
			CreatedAt:      v.CreatedAt.Unix(),
			UpdatedAt:      v.UpdatedAt.Unix(),
		}
		if v.Deadline != nil {
			unix := v.Deadline.Unix()
			rm.Deadline = &unix
		}
		readModels[i] = rm
	}
	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
