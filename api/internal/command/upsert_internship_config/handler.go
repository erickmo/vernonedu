package upsert_internship_config

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/internship"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// UpsertInternshipConfigCommand berisi data untuk membuat atau memperbarui konfigurasi magang.
type UpsertInternshipConfigCommand struct {
	CourseVersionID    uuid.UUID  `validate:"required"`
	PartnerCompanyName string     `validate:"required,min=1"`
	PositionTitle      string     `validate:"required,min=1"`
	SupervisorName     string
	SupervisorContact  string
	MOUDocumentURL     string
	DurationWeeks      int        `validate:"required,min=1"`
	IsCompanyProvided  bool
	PartnerCompanyID   *uuid.UUID
}

// Handler menangani perintah upsert konfigurasi magang.
type Handler struct {
	writeRepo internship.WriteRepository
	readRepo  internship.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance Handler baru untuk upsert_internship_config.
func NewHandler(writeRepo internship.WriteRepository, readRepo internship.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		writeRepo: writeRepo,
		readRepo:  readRepo,
		eventBus:  eventBus,
	}
}

// Handle mengeksekusi proses upsert konfigurasi magang.
// Cek apakah sudah ada konfigurasi untuk version ini:
//   - Jika ada: Update konfigurasi yang existing dan publikasikan InternshipConfigUpdated
//   - Jika tidak: Buat konfigurasi baru dan publikasikan InternshipConfigCreated
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	upsertCmd, ok := cmd.(*UpsertInternshipConfigCommand)
	if !ok {
		return ErrInvalidCommand
	}

	// Cek apakah sudah ada konfigurasi magang untuk version ini
	existing, err := h.readRepo.GetByVersionID(ctx, upsertCmd.CourseVersionID)

	if err != nil && !errors.Is(err, internship.ErrConfigNotFound) {
		log.Error().Err(err).Str("course_version_id", upsertCmd.CourseVersionID.String()).Msg("gagal mengecek konfigurasi magang existing")
		return err
	}

	var event eventbus.DomainEvent

	if existing != nil {
		// Update konfigurasi yang sudah ada
		if err := existing.Update(
			upsertCmd.PartnerCompanyName,
			upsertCmd.PartnerCompanyID,
			upsertCmd.PositionTitle,
			upsertCmd.DurationWeeks,
			upsertCmd.SupervisorName,
			upsertCmd.SupervisorContact,
			upsertCmd.MOUDocumentURL,
			upsertCmd.IsCompanyProvided,
		); err != nil {
			log.Error().Err(err).Str("config_id", existing.ID.String()).Msg("gagal mengupdate konfigurasi magang")
			return err
		}

		if err := h.writeRepo.Update(ctx, existing); err != nil {
			log.Error().Err(err).Str("config_id", existing.ID.String()).Msg("gagal menyimpan perubahan konfigurasi magang")
			return err
		}

		event = &internship.InternshipConfigUpdated{
			ConfigID:        existing.ID,
			CourseVersionID: existing.CourseVersionID,
			Timestamp:       time.Now().Unix(),
		}

		log.Info().Str("config_id", existing.ID.String()).Msg("konfigurasi magang berhasil diperbarui")
	} else {
		// Buat konfigurasi baru
		ic, err := internship.NewInternshipConfig(
			upsertCmd.CourseVersionID,
			upsertCmd.PartnerCompanyName,
			upsertCmd.PartnerCompanyID,
			upsertCmd.PositionTitle,
			upsertCmd.DurationWeeks,
			upsertCmd.SupervisorName,
			upsertCmd.SupervisorContact,
			upsertCmd.MOUDocumentURL,
			upsertCmd.IsCompanyProvided,
		)
		if err != nil {
			log.Error().Err(err).Msg("gagal membuat konfigurasi magang baru")
			return err
		}

		if err := h.writeRepo.Save(ctx, ic); err != nil {
			log.Error().Err(err).Msg("gagal menyimpan konfigurasi magang baru")
			return err
		}

		event = &internship.InternshipConfigCreated{
			ConfigID:        ic.ID,
			CourseVersionID: ic.CourseVersionID,
			Timestamp:       time.Now().Unix(),
		}

		log.Info().Str("config_id", ic.ID.String()).Msg("konfigurasi magang berhasil dibuat")
	}

	// Publikasikan event yang sesuai
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("gagal mempublikasikan event konfigurasi magang")
		return err
	}

	return nil
}
