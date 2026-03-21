package create_coursetype

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
var ErrInvalidCommand = errors.New("invalid create course type command")

// CreateCourseTypeCommand adalah command untuk membuat CourseType baru.
type CreateCourseTypeCommand struct {
	MasterCourseID         uuid.UUID `validate:"required"`
	TypeName               string    `validate:"required"`
	PriceType              string
	PriceCurrency          string
	TargetAudience         string
	CertificationType      string
	ExtraDocs              []string
	ComponentFailureConfig *coursetype.ComponentFailureConfig
}

// Handler menangani CreateCourseTypeCommand.
type Handler struct {
	writeRepo coursetype.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursetype.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk membuat CourseType baru.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCourseTypeCommand)
	if !ok {
		return ErrInvalidCommand
	}

	ct, err := coursetype.NewCourseType(
		c.MasterCourseID, c.TypeName, c.PriceType, c.PriceCurrency,
		c.TargetAudience, c.CertificationType, c.ExtraDocs, c.ComponentFailureConfig,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create course type entity")
		return err
	}

	if err := h.writeRepo.Save(ctx, ct); err != nil {
		log.Error().Err(err).Msg("failed to save course type")
		return err
	}

	event := &coursetype.CourseTypeActivated{
		CourseTypeID:   ct.ID,
		MasterCourseID: ct.MasterCourseID,
		TypeName:       ct.TypeName,
		Timestamp:      time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseTypeActivated event")
	}

	log.Info().Str("course_type_id", ct.ID.String()).Msg("course type created successfully")
	return nil
}
