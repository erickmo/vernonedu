package create_job_vacancy

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	repo     job_vacancy.WriteRepository
	eventBus eventbus.EventBus
}

func NewHandler(repo job_vacancy.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{repo: repo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateJobVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}
	v, err := job_vacancy.NewJobVacancy(
		c.Title, c.Description, c.PartnerID, c.DepartmentID,
		c.Location, c.Type, c.ExperienceLevel, c.Slots,
		c.MinSalary, c.MaxSalary, c.RequiredSkills, c.Deadline, c.CreatedBy,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create job vacancy domain object")
		return err
	}
	if err := h.repo.Save(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to save job vacancy")
		return err
	}
	event := &job_vacancy.JobVacancyCreatedEvent{
		EventType: "JobVacancyCreated",
		VacancyID: v.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish JobVacancyCreated event")
	}
	log.Info().Str("vacancy_id", v.ID.String()).Msg("job vacancy created")
	return nil
}
