package update_certificate_template

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	certReadRepo  certificate.ReadRepository
	certWriteRepo certificate.WriteRepository
}

func NewHandler(certReadRepo certificate.ReadRepository, certWriteRepo certificate.WriteRepository) *Handler {
	return &Handler{
		certReadRepo:  certReadRepo,
		certWriteRepo: certWriteRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateCertificateTemplateCommand)
	if !ok {
		return ErrInvalidCommand
	}

	tmpl, err := h.certReadRepo.GetTemplateByID(ctx, updateCmd.ID)
	if err != nil {
		log.Error().Err(err).Str("template_id", updateCmd.ID.String()).Msg("failed to get certificate template")
		return err
	}

	tmpl.Name = updateCmd.Name
	if updateCmd.TemplateData != nil {
		tmpl.TemplateData = updateCmd.TemplateData
	}
	tmpl.IsActive = updateCmd.IsActive
	tmpl.UpdatedAt = time.Now()

	if err := h.certWriteRepo.UpdateTemplate(ctx, tmpl); err != nil {
		log.Error().Err(err).Str("template_id", updateCmd.ID.String()).Msg("failed to update certificate template")
		return err
	}

	log.Info().Str("template_id", updateCmd.ID.String()).Msg("certificate template updated successfully")
	return nil
}
