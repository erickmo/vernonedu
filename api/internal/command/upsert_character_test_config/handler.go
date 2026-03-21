package upsert_character_test_config

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/charactertest"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// UpsertCharacterTestConfigCommand berisi data untuk membuat atau memperbarui konfigurasi tes karakter.
type UpsertCharacterTestConfigCommand struct {
	CourseVersionID    uuid.UUID `validate:"required"`
	TestType           string    `validate:"required,min=1"`
	TestProvider       string
	PassingThreshold   float64
	TalentpoolEligible bool
}

// Handler menangani perintah upsert konfigurasi tes karakter.
type Handler struct {
	writeRepo charactertest.WriteRepository
	readRepo  charactertest.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance Handler baru untuk upsert_character_test_config.
func NewHandler(writeRepo charactertest.WriteRepository, readRepo charactertest.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		writeRepo: writeRepo,
		readRepo:  readRepo,
		eventBus:  eventBus,
	}
}

// Handle mengeksekusi proses upsert konfigurasi tes karakter.
// Cek apakah sudah ada konfigurasi untuk version ini:
//   - Jika ada: Update konfigurasi yang existing dan publikasikan CharacterTestConfigUpdated
//   - Jika tidak: Buat konfigurasi baru dan publikasikan CharacterTestConfigCreated
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	upsertCmd, ok := cmd.(*UpsertCharacterTestConfigCommand)
	if !ok {
		return ErrInvalidCommand
	}

	// Cek apakah sudah ada konfigurasi tes karakter untuk version ini
	existing, err := h.readRepo.GetByVersionID(ctx, upsertCmd.CourseVersionID)

	if err != nil && !errors.Is(err, charactertest.ErrConfigNotFound) {
		log.Error().Err(err).Str("course_version_id", upsertCmd.CourseVersionID.String()).Msg("gagal mengecek konfigurasi tes karakter existing")
		return err
	}

	var event eventbus.DomainEvent

	if existing != nil {
		// Update konfigurasi yang sudah ada
		if err := existing.Update(
			upsertCmd.TestType,
			upsertCmd.TestProvider,
			upsertCmd.PassingThreshold,
			upsertCmd.TalentpoolEligible,
		); err != nil {
			log.Error().Err(err).Str("config_id", existing.ID.String()).Msg("gagal mengupdate konfigurasi tes karakter")
			return err
		}

		if err := h.writeRepo.Update(ctx, existing); err != nil {
			log.Error().Err(err).Str("config_id", existing.ID.String()).Msg("gagal menyimpan perubahan konfigurasi tes karakter")
			return err
		}

		event = &charactertest.CharacterTestConfigUpdated{
			ConfigID:        existing.ID,
			CourseVersionID: existing.CourseVersionID,
			Timestamp:       time.Now().Unix(),
		}

		log.Info().Str("config_id", existing.ID.String()).Msg("konfigurasi tes karakter berhasil diperbarui")
	} else {
		// Buat konfigurasi baru
		ctc, err := charactertest.NewCharacterTestConfig(
			upsertCmd.CourseVersionID,
			upsertCmd.TestType,
			upsertCmd.TestProvider,
			upsertCmd.PassingThreshold,
			upsertCmd.TalentpoolEligible,
		)
		if err != nil {
			log.Error().Err(err).Msg("gagal membuat konfigurasi tes karakter baru")
			return err
		}

		if err := h.writeRepo.Save(ctx, ctc); err != nil {
			log.Error().Err(err).Msg("gagal menyimpan konfigurasi tes karakter baru")
			return err
		}

		event = &charactertest.CharacterTestConfigCreated{
			ConfigID:        ctc.ID,
			CourseVersionID: ctc.CourseVersionID,
			TestType:        ctc.TestType,
			Timestamp:       time.Now().Unix(),
		}

		log.Info().Str("config_id", ctc.ID.String()).Msg("konfigurasi tes karakter berhasil dibuat")
	}

	// Publikasikan event yang sesuai
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("gagal mempublikasikan event konfigurasi tes karakter")
		return err
	}

	return nil
}
