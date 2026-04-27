package platform

import (
	"context"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Notification template keys triggered by cross-domain events.
const (
	keyEnrollmentConfirmed     = "enrollment.confirmed"
	keyPaymentConfirmed        = "payment.confirmed"
	keyPaymentTermDue          = "payment.term.due"
	keyPaymentTermOverdue      = "payment.term.overdue"
	keyUserWelcome             = "user.welcome"
	keyFacilitatorProposed     = "facilitator.proposed"
	keyFacilitatorApproved     = "facilitator.approved"
	keyFacilitatorRejected     = "facilitator.rejected"
	keyInvoiceSent             = "invoice.sent"
	keyInvoiceOverdue          = "invoice.overdue"
	keyTeamMemberCreated       = "team_member.created"
	keyTeamMemberStatusChanged = "team_member.status_changed"
	keyClassReminder           = "class.reminder"
	keyCertificateIssued       = "certificate.issued"
)

// sendOne dispatches a single notification, swallowing errors so one bad
// recipient does not block sibling sends in the same fan-out.
func (s *Service) sendOne(ctx context.Context, key string, recipientID uuid.UUID, vars map[string]any) {
	if recipientID == uuid.Nil {
		return
	}
	if _, err := s.Send(ctx, SendInput{
		RecipientID: recipientID,
		TemplateKey: key,
		Channel:     ChannelEmail,
		Variables:   vars,
	}); err != nil {
		s.log.Warn("notification dispatch failed",
			zap.Error(err),
			zap.String("key", key),
			zap.String("recipient", recipientID.String()),
		)
	}
}

// logBadPayload logs and skips when a cross-domain event carries an unexpected payload type.
func (s *Service) logBadPayload(eventType events.EventType) {
	s.log.Warn("dropping event with unexpected payload",
		zap.String("event", string(eventType)),
	)
}

func (s *Service) handleEnrollmentConfirmed(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.EnrollmentConfirmedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{
		"course_title": p.CourseTitle,
	}
	s.sendOne(ctx, keyEnrollmentConfirmed, p.StudentID, vars)
	return nil
}

func (s *Service) handlePaymentConfirmed(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.PaymentConfirmedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"amount": p.Amount}
	s.sendOne(ctx, keyPaymentConfirmed, p.StudentID, vars)
	return nil
}

func (s *Service) handlePaymentTermDue(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.PaymentTermDuePayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"amount": p.AmountDue, "due_date": p.DueDate}
	s.sendOne(ctx, keyPaymentTermDue, p.StudentID, vars)
	for _, aid := range p.AdminIDs {
		s.sendOne(ctx, keyPaymentTermDue, aid, vars)
	}
	return nil
}

func (s *Service) handlePaymentTermOverdue(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.PaymentTermOverduePayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"amount": p.AmountDue, "due_date": p.DueDate}
	s.sendOne(ctx, keyPaymentTermOverdue, p.StudentID, vars)
	for _, aid := range p.AdminIDs {
		s.sendOne(ctx, keyPaymentTermOverdue, aid, vars)
	}
	return nil
}

func (s *Service) handleUserCreated(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.UserCreatedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{
		"email":     p.Email,
		"full_name": p.FullName,
	}
	s.sendOne(ctx, keyUserWelcome, p.UserID, vars)
	return nil
}

func (s *Service) handleFacilitatorProposed(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.FacilitatorEventPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"course_title": p.CourseTitle}
	s.sendOne(ctx, keyFacilitatorProposed, p.DeptLeaderID, vars)
	return nil
}

func (s *Service) handleFacilitatorApproved(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.FacilitatorEventPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"course_title": p.CourseTitle}
	s.sendOne(ctx, keyFacilitatorApproved, p.CourseCreatorID, vars)
	s.sendOne(ctx, keyFacilitatorApproved, p.FacilitatorID, vars)
	return nil
}

func (s *Service) handleFacilitatorRejected(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.FacilitatorEventPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"course_title": p.CourseTitle}
	s.sendOne(ctx, keyFacilitatorRejected, p.CourseCreatorID, vars)
	s.sendOne(ctx, keyFacilitatorRejected, p.FacilitatorID, vars)
	return nil
}

func (s *Service) handleInvoiceSent(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.InvoiceSentPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"amount": p.Amount, "due_date": p.DueDate}
	s.sendOne(ctx, keyInvoiceSent, p.BilledPartyID, vars)
	return nil
}

func (s *Service) handleInvoiceOverdue(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.InvoiceOverduePayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"amount": p.Amount, "due_date": p.DueDate}
	s.sendOne(ctx, keyInvoiceOverdue, p.BilledPartyID, vars)
	for _, aid := range p.AdminIDs {
		s.sendOne(ctx, keyInvoiceOverdue, aid, vars)
	}
	return nil
}

func (s *Service) handleTeamMemberCreated(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.TeamMemberEventPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"status": p.Status}
	s.sendOne(ctx, keyTeamMemberCreated, p.MemberID, vars)
	s.sendOne(ctx, keyTeamMemberCreated, p.DeptLeaderID, vars)
	return nil
}

func (s *Service) handleTeamMemberStatusChanged(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.TeamMemberEventPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"status": p.Status}
	s.sendOne(ctx, keyTeamMemberStatusChanged, p.MemberID, vars)
	s.sendOne(ctx, keyTeamMemberStatusChanged, p.DeptLeaderID, vars)
	return nil
}

func (s *Service) handleClassReminder(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.ClassReminderPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{
		"class_title": p.ClassTitle,
		"start_at":    p.StartAt,
	}
	s.sendOne(ctx, keyClassReminder, p.FacilitatorID, vars)
	for _, aid := range p.AttendeeIDs {
		s.sendOne(ctx, keyClassReminder, aid, vars)
	}
	return nil
}

func (s *Service) handleCertificateIssued(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.CertificateIssuedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	vars := map[string]any{"course_title": p.CourseTitle}
	s.sendOne(ctx, keyCertificateIssued, p.StudentID, vars)
	return nil
}
