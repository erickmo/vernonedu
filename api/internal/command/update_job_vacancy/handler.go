package update_job_vacancy

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo job_vacancy.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo job_vacancy.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateJobVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}
	v, err := h.writeRepo.GetByIDForWrite(ctx, c.ID)
	if err != nil {
		return err
	}
	if c.RequiredSkills == nil {
		c.RequiredSkills = []string{}
	}
	v.Title = c.Title
	v.Description = c.Description
	v.PartnerID = c.PartnerID
	v.DepartmentID = c.DepartmentID
	v.Location = c.Location
	v.Type = c.Type
	v.ExperienceLevel = c.ExperienceLevel
	v.Slots = c.Slots
	v.MinSalary = c.MinSalary
	v.MaxSalary = c.MaxSalary
	v.RequiredSkills = c.RequiredSkills
	v.Deadline = c.Deadline
	v.UpdatedAt = time.Now()
	if err := h.writeRepo.Update(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to update job vacancy")
		return err
	}
	log.Info().Str("vacancy_id", v.ID.String()).Msg("job vacancy updated")
	return nil
}
