package grant_app_access

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/studentappaccess"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo studentappaccess.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo studentappaccess.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*GrantAppAccessCommand)
	if !ok {
		return ErrInvalidCommand
	}

	access := studentappaccess.NewStudentAppAccess(c.StudentID, c.AppName, c.BatchID)

	if err := h.writeRepo.Save(ctx, access); err != nil {
		log.Error().Err(err).Msg("failed to grant app access")
		return err
	}

	event := &studentappaccess.AppAccessGrantedEvent{
		EventType: "AppAccessGranted",
		StudentID: c.StudentID,
		AppName:   c.AppName,
		BatchID:   c.BatchID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish AppAccessGranted")
	}

	log.Info().Str("student_id", c.StudentID.String()).Str("app", c.AppName).Msg("app access granted")
	return nil
}
