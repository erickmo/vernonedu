package create_courseversion

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid create course version command")

// CreateCourseVersionCommand adalah command untuk membuat CourseVersion baru.
type CreateCourseVersionCommand struct {
	CourseTypeID  uuid.UUID  `validate:"required"`
	VersionNumber string     `validate:"required"`
	ChangeType    string     `validate:"required"`
	Changelog     string
	CreatedBy     *uuid.UUID
}

// Handler menangani CreateCourseVersionCommand.
type Handler struct {
	writeRepo courseversion.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo courseversion.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk membuat CourseVersion baru.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCourseVersionCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cv, err := courseversion.NewCourseVersion(c.CourseTypeID, c.VersionNumber, c.ChangeType, c.Changelog, c.CreatedBy)
	if err != nil {
		log.Error().Err(err).Msg("failed to create course version entity")
		return err
	}

	if err := h.writeRepo.Save(ctx, cv); err != nil {
		log.Error().Err(err).Msg("failed to save course version")
		return err
	}

	event := &courseversion.VersionCreated{
		VersionID:     cv.ID,
		CourseTypeID:  cv.CourseTypeID,
		VersionNumber: cv.VersionNumber,
		ChangeType:    cv.ChangeType,
		Timestamp:     time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish VersionCreated event")
	}

	log.Info().Str("version_id", cv.ID.String()).Msg("course version created successfully")
	return nil
}
