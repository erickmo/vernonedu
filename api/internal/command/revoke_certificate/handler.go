package revoke_certificate

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	certReadRepo  certificate.ReadRepository
	certWriteRepo certificate.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(certReadRepo certificate.ReadRepository, certWriteRepo certificate.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		certReadRepo:  certReadRepo,
		certWriteRepo: certWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	revokeCmd, ok := cmd.(*RevokeCertificateCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cert, err := h.certReadRepo.GetByID(ctx, revokeCmd.CertificateID)
	if err != nil {
		log.Error().Err(err).Str("certificate_id", revokeCmd.CertificateID.String()).Msg("failed to get certificate")
		return err
	}

	if err := cert.Revoke(revokeCmd.Reason); err != nil {
		log.Error().Err(err).Str("certificate_id", revokeCmd.CertificateID.String()).Msg("failed to revoke certificate")
		return err
	}

	if err := h.certWriteRepo.Revoke(ctx, cert.ID, cert.RevocationReason, *cert.RevokedAt); err != nil {
		log.Error().Err(err).Str("certificate_id", cert.ID.String()).Msg("failed to persist certificate revocation")
		return err
	}

	event := &certificate.CertificateRevokedEvent{
		EventType:     "CertificateRevoked",
		CertificateID: cert.ID,
		StudentID:     cert.StudentID,
		CertCode:      cert.CertificateCode,
		Reason:        cert.RevocationReason,
		Timestamp:     time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CertificateRevoked event")
		return err
	}

	log.Info().Str("certificate_id", cert.ID.String()).Msg("certificate revoked successfully")
	return nil
}
