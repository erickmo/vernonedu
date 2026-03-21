package issue_certificate

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	certWriteRepo certificate.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(certWriteRepo certificate.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		certWriteRepo: certWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	issueCmd, ok := cmd.(*IssueCertificateCommand)
	if !ok {
		return ErrInvalidCommand
	}

	var templateID *uuid.UUID
	if issueCmd.TemplateID != "" {
		id, err := uuid.Parse(issueCmd.TemplateID)
		if err == nil {
			templateID = &id
		}
	}

	var studentID *uuid.UUID
	if issueCmd.StudentID != "" {
		id, err := uuid.Parse(issueCmd.StudentID)
		if err == nil {
			studentID = &id
		}
	}

	var batchID *uuid.UUID
	if issueCmd.BatchID != "" {
		id, err := uuid.Parse(issueCmd.BatchID)
		if err == nil {
			batchID = &id
		}
	}

	var courseID *uuid.UUID
	if issueCmd.CourseID != "" {
		id, err := uuid.Parse(issueCmd.CourseID)
		if err == nil {
			courseID = &id
		}
	}

	cert, err := certificate.NewCertificate(
		templateID,
		studentID,
		batchID,
		courseID,
		certificate.CertType(issueCmd.Type),
		issueCmd.VerificationBaseURL,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create certificate")
		return err
	}

	if err := h.certWriteRepo.Save(ctx, cert); err != nil {
		log.Error().Err(err).Msg("failed to save certificate")
		return err
	}

	event := &certificate.CertificateIssuedEvent{
		EventType:     "CertificateIssued",
		CertificateID: cert.ID,
		StudentID:     cert.StudentID,
		CertCode:      cert.CertificateCode,
		CertType:      string(cert.Type),
		Timestamp:     time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CertificateIssued event")
		return err
	}

	log.Info().Str("certificate_id", cert.ID.String()).Str("code", cert.CertificateCode).Msg("certificate issued successfully")
	return nil
}
