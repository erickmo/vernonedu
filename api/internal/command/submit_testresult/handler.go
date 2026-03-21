package submit_testresult

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

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid submit test result command")

// SubmitTestResultCommand adalah command untuk mengirimkan hasil tes karakter peserta program_karir.
// Jika peserta lulus threshold, entri TalentPool baru akan dibuat.
type SubmitTestResultCommand struct {
	CourseVersionID  uuid.UUID              `validate:"required"`
	MasterCourseID   uuid.UUID              `validate:"required"`
	CourseTypeID     uuid.UUID              `validate:"required"`
	ParticipantID    uuid.UUID              `validate:"required"`
	ParticipantName  string                 `validate:"required"`
	ParticipantEmail string                 `validate:"required"`
	TestResult       map[string]interface{}
	TestScore        *float64
}

// Handler menangani SubmitTestResultCommand.
type Handler struct {
	writeRepo talentpool.WriteRepository
	readRepo  talentpool.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo talentpool.WriteRepository, readRepo talentpool.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk submit hasil tes karakter dan membuat entri TalentPool.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*SubmitTestResultCommand)
	if !ok {
		return ErrInvalidCommand
	}

	tp, err := talentpool.NewTalentPool(
		c.ParticipantID, c.ParticipantName, c.ParticipantEmail,
		c.MasterCourseID, c.CourseTypeID, c.CourseVersionID,
		c.TestResult, c.TestScore,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create talent pool entity")
		return err
	}

	if err := h.writeRepo.Save(ctx, tp); err != nil {
		log.Error().Err(err).Msg("failed to save talent pool entry")
		return err
	}

	event := &talentpool.TalentPoolEntryCreated{
		TalentPoolID:    tp.ID,
		ParticipantID:   tp.ParticipantID,
		MasterCourseID:  tp.MasterCourseID,
		CourseVersionID: tp.CourseVersionID,
		Timestamp:       time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish TalentPoolEntryCreated event")
	}

	log.Info().Str("talent_pool_id", tp.ID.String()).Msg("talent pool entry created from test result")
	return nil
}
