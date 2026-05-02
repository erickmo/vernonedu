package reject_courseversion

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
var ErrInvalidCommand = errors.New("invalid reject course version command")

// RejectCourseVersionCommand digunakan oleh dept_leader untuk menolak workflow.
type RejectCourseVersionCommand struct {
	VersionID  uuid.UUID `validate:"required"`
	ApprovedBy uuid.UUID `validate:"required"`
	Reason     string    `validate:"required"`
}

// Handler menangani RejectCourseVersionCommand.
type Handler struct {
	writeRepo courseversion.WriteRepository
	readRepo  courseversion.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo courseversion.WriteRepository, readRepo courseversion.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi reject course version workflow.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*RejectCourseVersionCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cv, err := h.readRepo.GetByID(ctx, c.VersionID)
	if err != nil {
		log.Error().Err(err).Str("version_id", c.VersionID.String()).Msg("course version not found")
		return err
	}

	if err := cv.RejectWorkflow(c.ApprovedBy, c.Reason); err != nil {
		log.Warn().Err(err).Str("version_id", c.VersionID.String()).Msg("reject transition rejected")
		return err
	}

	if err := h.writeRepo.UpdateApprovalWorkflow(ctx, cv); err != nil {
		log.Error().Err(err).Msg("failed to persist rejected course version")
		return err
	}

	event := &courseversion.VersionWorkflowRejected{
		VersionID:    cv.ID,
		CourseTypeID: cv.CourseTypeID,
		ApprovedBy:   c.ApprovedBy,
		Reason:       c.Reason,
		Timestamp:    time.Now().Unix(),
	}
	if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
		log.Error().Err(pubErr).Msg("failed to publish VersionWorkflowRejected event")
	}

	log.Info().Str("version_id", cv.ID.String()).Msg("course version workflow rejected")
	return nil
}
