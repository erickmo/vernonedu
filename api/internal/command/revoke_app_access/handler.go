package revoke_app_access

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
	switch c := cmd.(type) {
	case *RevokeAppAccessCommand:
		return h.revokeOne(ctx, c)
	case *RevokeAllBatchAccessCommand:
		return h.revokeAll(ctx, c)
	default:
		return ErrInvalidCommand
	}
}

func (h *Handler) revokeOne(ctx context.Context, c *RevokeAppAccessCommand) error {
	if err := h.writeRepo.RevokeByStudentAndBatch(ctx, c.StudentID, c.BatchID); err != nil {
		log.Error().Err(err).Msg("failed to revoke app access")
		return err
	}
	event := &studentappaccess.AppAccessRevokedEvent{
		EventType: "AppAccessRevoked",
		StudentID: c.StudentID,
		BatchID:   c.BatchID,
		Reason:    c.Reason,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish AppAccessRevoked")
	}
	log.Info().Str("student_id", c.StudentID.String()).Msg("app access revoked")
	return nil
}

func (h *Handler) revokeAll(ctx context.Context, c *RevokeAllBatchAccessCommand) error {
	if err := h.writeRepo.RevokeAllByBatch(ctx, c.BatchID); err != nil {
		log.Error().Err(err).Msg("failed to revoke all batch app access")
		return err
	}
	event := &studentappaccess.AppAccessRevokedEvent{
		EventType: "AppAccessRevoked",
		BatchID:   c.BatchID,
		Reason:    c.Reason,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish AppAccessRevoked (batch)")
	}
	log.Info().Str("batch_id", c.BatchID.String()).Msg("all batch app access revoked")
	return nil
}
