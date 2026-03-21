package create_coursemodule

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
var ErrInvalidCommand = errors.New("invalid create course module command")

// CreateCourseModuleCommand adalah command untuk membuat CourseModule baru.
type CreateCourseModuleCommand struct {
	CourseVersionID     uuid.UUID  `validate:"required"`
	ModuleCode          string     `validate:"required"`
	ModuleTitle         string     `validate:"required,min=1"`
	DurationHours       float64
	Sequence            int `validate:"required,min=1"`
	ContentDepth        string
	Topics              []string
	PracticalActivities []string
	AssessmentMethod    string
	ToolsRequired       []string
	Requirements        []string
	IsReference         bool
	RefModuleID         *uuid.UUID
}

// Handler menangani CreateCourseModuleCommand.
type Handler struct {
	writeRepo coursemodule.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursemodule.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk membuat CourseModule baru.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCourseModuleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cm, err := coursemodule.NewCourseModule(
		c.CourseVersionID, c.ModuleCode, c.ModuleTitle, c.ContentDepth, c.AssessmentMethod,
		c.DurationHours, c.Sequence, c.Topics, c.PracticalActivities, c.ToolsRequired,
		c.Requirements, c.IsReference, c.RefModuleID,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create course module entity")
		return err
	}

	if err := h.writeRepo.Save(ctx, cm); err != nil {
		log.Error().Err(err).Msg("failed to save course module")
		return err
	}

	log.Info().Str("module_id", cm.ID.String()).Msg("course module created successfully")
	return nil
}
