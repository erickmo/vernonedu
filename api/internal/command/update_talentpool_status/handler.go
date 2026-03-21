package update_talentpool_status

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)


// ErrInvalidStatus dikembalikan ketika status tidak valid.
var ErrInvalidStatus = errors.New("status harus 'placed' atau 'inactive'")

// UpdateTalentPoolStatusCommand adalah command untuk memperbarui status TalentPool.
type UpdateTalentPoolStatusCommand struct {
	TalentPoolID uuid.UUID `validate:"required"`
	Status       string    `validate:"required"` // "placed" | "inactive"
	Placement    *talentpool.PlacementRecord   // wajib diisi jika status = "placed"
}

// Handler menangani UpdateTalentPoolStatusCommand.
type Handler struct {
	writeRepo talentpool.WriteRepository
	readRepo  talentpool.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo talentpool.WriteRepository, readRepo talentpool.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk memperbarui status TalentPool.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateTalentPoolStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}

	tp, err := h.readRepo.GetByID(ctx, c.TalentPoolID)
	if err != nil {
		log.Error().Err(err).Str("talent_pool_id", c.TalentPoolID.String()).Msg("talent pool entry not found")
		return err
	}

	now := time.Now()

	switch c.Status {
	case "placed":
		if c.Placement == nil {
			return errors.New("placement data wajib diisi saat status placed")
		}
		record := *c.Placement
		record.PlacedAt = now
		tp.MarkPlaced(record)

		event := &talentpool.TalentPoolPlacementAdded{
			TalentPoolID:  tp.ID,
			ParticipantID: tp.ParticipantID,
			CompanyName:   record.CompanyName,
			Position:      record.Position,
			Timestamp:     now.Unix(),
		}
		if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish TalentPoolPlacementAdded event")
		}

	case "inactive":
		if err := tp.Deactivate(); err != nil {
			log.Error().Err(err).Msg("failed to deactivate talent pool entry")
			return err
		}
		event := &talentpool.TalentPoolStatusUpdated{
			TalentPoolID: tp.ID,
			NewStatus:    tp.TalentpoolStatus,
			Timestamp:    now.Unix(),
		}
		if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish TalentPoolStatusUpdated event")
		}

	default:
		return ErrInvalidStatus
	}

	if err := h.writeRepo.Update(ctx, tp); err != nil {
		log.Error().Err(err).Msg("failed to persist talent pool update")
		return err
	}

	log.Info().Str("talent_pool_id", tp.ID.String()).Str("status", tp.TalentpoolStatus).Msg("talent pool status updated successfully")
	return nil
}
