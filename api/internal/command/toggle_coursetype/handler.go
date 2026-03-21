package toggle_coursetype

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
var ErrInvalidCommand = errors.New("invalid toggle course type command")

// ToggleCourseTypeCommand adalah command untuk toggle aktif/nonaktif CourseType.
type ToggleCourseTypeCommand struct {
	CourseTypeID uuid.UUID `validate:"required"`
}

// Handler menangani ToggleCourseTypeCommand.
type Handler struct {
	writeRepo coursetype.WriteRepository
	readRepo  coursetype.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursetype.WriteRepository, readRepo coursetype.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk toggle status aktif CourseType.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*ToggleCourseTypeCommand)
	if !ok {
		return ErrInvalidCommand
	}

	ct, err := h.readRepo.GetByID(ctx, c.CourseTypeID)
	if err != nil {
		log.Error().Err(err).Str("id", c.CourseTypeID.String()).Msg("course type not found")
		return err
	}

	var event interface {
		EventName() string
		EventData() interface{}
	}

	if ct.IsActive {
		if err := ct.Deactivate(); err != nil {
			return err
		}
		event = &coursetype.CourseTypeDeactivated{
			CourseTypeID:   ct.ID,
			MasterCourseID: ct.MasterCourseID,
			TypeName:       ct.TypeName,
			Timestamp:      time.Now().Unix(),
		}
	} else {
		if err := ct.Activate(); err != nil {
			return err
		}
		event = &coursetype.CourseTypeActivated{
			CourseTypeID:   ct.ID,
			MasterCourseID: ct.MasterCourseID,
			TypeName:       ct.TypeName,
			Timestamp:      time.Now().Unix(),
		}
	}

	if err := h.writeRepo.Update(ctx, ct); err != nil {
		log.Error().Err(err).Msg("failed to persist course type toggle")
		return err
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish course type toggle event")
	}

	log.Info().Str("course_type_id", ct.ID.String()).Bool("is_active", ct.IsActive).Msg("course type toggled successfully")
	return nil
}
