package promote_courseversion

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
var ErrInvalidCommand = errors.New("invalid promote course version command")

// ErrInvalidTargetStatus dikembalikan ketika target_status tidak valid.
var ErrInvalidTargetStatus = errors.New("target_status harus 'review' atau 'approved'")

// PromoteCourseVersionCommand adalah command untuk mempromosikan status CourseVersion.
type PromoteCourseVersionCommand struct {
	VersionID    uuid.UUID  `validate:"required"`
	TargetStatus string     `validate:"required"` // "review" | "approved"
	ApprovedBy   *uuid.UUID // wajib diisi jika target_status = "approved"
}

// Handler menangani PromoteCourseVersionCommand.
type Handler struct {
	writeRepo courseversion.WriteRepository
	readRepo  courseversion.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo courseversion.WriteRepository, readRepo courseversion.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk mempromosikan status CourseVersion.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*PromoteCourseVersionCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cv, err := h.readRepo.GetByID(ctx, c.VersionID)
	if err != nil {
		log.Error().Err(err).Str("version_id", c.VersionID.String()).Msg("course version not found")
		return err
	}

	now := time.Now()

	switch c.TargetStatus {
	case "review":
		if err := cv.PromoteToReview(); err != nil {
			log.Error().Err(err).Msg("failed to promote version to review")
			return err
		}
		if err := h.writeRepo.Update(ctx, cv); err != nil {
			return err
		}
		event := &courseversion.VersionPromotedToReview{
			VersionID:    cv.ID,
			CourseTypeID: cv.CourseTypeID,
			Timestamp:    now.Unix(),
		}
		if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish VersionPromotedToReview event")
		}

	case "approved":
		if c.ApprovedBy == nil {
			return errors.New("approved_by wajib diisi saat status approved")
		}
		// Arsipkan semua versi approved sebelumnya
		if err := h.writeRepo.ArchiveAllApproved(ctx, cv.CourseTypeID); err != nil {
			log.Error().Err(err).Msg("failed to archive previous approved versions")
			return err
		}
		if err := cv.Approve(*c.ApprovedBy); err != nil {
			log.Error().Err(err).Msg("failed to approve version")
			return err
		}
		if err := h.writeRepo.Update(ctx, cv); err != nil {
			return err
		}
		event := &courseversion.VersionApproved{
			VersionID:    cv.ID,
			CourseTypeID: cv.CourseTypeID,
			ApprovedBy:   *c.ApprovedBy,
			Timestamp:    now.Unix(),
		}
		if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish VersionApproved event")
		}

	default:
		return ErrInvalidTargetStatus
	}

	log.Info().Str("version_id", cv.ID.String()).Str("status", cv.Status).Msg("course version promoted successfully")
	return nil
}
