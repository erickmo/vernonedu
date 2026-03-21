package update_coursetype

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid update course type command")

// UpdateCourseTypeCommand adalah command untuk memperbarui CourseType.
type UpdateCourseTypeCommand struct {
	CourseTypeID           uuid.UUID `validate:"required"`
	TargetAudience         string
	CertificationType      string
	ExtraDocs              []string
	ComponentFailureConfig *coursetype.ComponentFailureConfig
	PriceType              string
	PriceMin               *int64
	PriceMax               *int64
	PriceCurrency          string
	PriceNotes             string
	NormalPrice            int64
	MinPrice               int64
	MinParticipants        int
	MaxParticipants        int
}

// Handler menangani UpdateCourseTypeCommand.
type Handler struct {
	writeRepo coursetype.WriteRepository
	readRepo  coursetype.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursetype.WriteRepository, readRepo coursetype.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk memperbarui CourseType.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCourseTypeCommand)
	if !ok {
		return ErrInvalidCommand
	}

	ct, err := h.readRepo.GetByID(ctx, c.CourseTypeID)
	if err != nil {
		log.Error().Err(err).Str("id", c.CourseTypeID.String()).Msg("course type not found")
		return err
	}

	if err := ct.Update(c.TargetAudience, c.CertificationType, c.ExtraDocs, c.ComponentFailureConfig, c.NormalPrice, c.MinPrice, c.MinParticipants, c.MaxParticipants); err != nil {
		log.Error().Err(err).Msg("failed to update course type entity")
		return err
	}

	ct.UpdatePrice(c.PriceType, c.PriceMin, c.PriceMax, c.PriceCurrency, c.PriceNotes)

	if err := h.writeRepo.Update(ctx, ct); err != nil {
		log.Error().Err(err).Msg("failed to persist course type update")
		return err
	}

	event := &coursetype.CourseTypeUpdated{
		CourseTypeID: ct.ID,
		Timestamp:    time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseTypeUpdated event")
	}

	log.Info().Str("course_type_id", ct.ID.String()).Msg("course type updated successfully")
	return nil
}
