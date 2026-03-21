package create_certificate_template

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	certWriteRepo certificate.WriteRepository
}

func NewHandler(certWriteRepo certificate.WriteRepository) *Handler {
	return &Handler{
		certWriteRepo: certWriteRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	createCmd, ok := cmd.(*CreateCertificateTemplateCommand)
	if !ok {
		return ErrInvalidCommand
	}

	tmpl, err := certificate.NewCertificateTemplate(
		createCmd.Name,
		certificate.CertType(createCmd.Type),
		createCmd.TemplateData,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create certificate template")
		return err
	}

	if err := h.certWriteRepo.SaveTemplate(ctx, tmpl); err != nil {
		log.Error().Err(err).Msg("failed to save certificate template")
		return err
	}

	log.Info().Str("template_id", tmpl.ID.String()).Msg("certificate template created successfully")
	return nil
}
