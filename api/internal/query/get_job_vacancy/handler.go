package get_job_vacancy

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_job_vacancies"
)

var ErrInvalidQuery = errors.New("invalid query type for get_job_vacancy")

type Handler struct {
	readRepo job_vacancy.ReadRepository
}

func NewHandler(readRepo job_vacancy.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
	q, ok := query.(*GetJobVacancyQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	v, err := h.readRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get job vacancy")
		return nil, err
	}
	rm := &list_job_vacancies.JobVacancyReadModel{
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
	return rm, nil
}
