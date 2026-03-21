package update_coursemodule

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursemodule"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid update course module command")

// UpdateCourseModuleCommand adalah command untuk memperbarui CourseModule.
type UpdateCourseModuleCommand struct {
	ModuleID            uuid.UUID `validate:"required"`
	ModuleTitle         string    `validate:"required,min=1"`
	DurationHours       float64
	Sequence            int `validate:"required,min=1"`
	ContentDepth        string
	Topics              []string
	PracticalActivities []string
	AssessmentMethod    string
	ToolsRequired       []string
}

// Handler menangani UpdateCourseModuleCommand.
type Handler struct {
	writeRepo coursemodule.WriteRepository
	readRepo  coursemodule.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursemodule.WriteRepository, readRepo coursemodule.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk memperbarui CourseModule.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCourseModuleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cm, err := h.readRepo.GetByID(ctx, c.ModuleID)
	if err != nil {
		log.Error().Err(err).Str("module_id", c.ModuleID.String()).Msg("course module not found")
		return err
	}

	if err := cm.Update(c.ModuleTitle, c.ContentDepth, c.AssessmentMethod, c.DurationHours, c.Sequence,
		c.Topics, c.PracticalActivities, c.ToolsRequired); err != nil {
		log.Error().Err(err).Msg("failed to update course module entity")
		return err
	}

	if err := h.writeRepo.Update(ctx, cm); err != nil {
		log.Error().Err(err).Msg("failed to persist course module update")
		return err
	}

	log.Info().Str("module_id", cm.ID.String()).Msg("course module updated successfully")
	return nil
}
