package notification

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Trigger key constants — used when calling Dispatch so no magic strings.
const (
	KeyUserWelcome             = "user.welcome"
	KeyEnrollmentConfirmed     = "enrollment.confirmed"
	KeyPaymentConfirmed        = "payment.confirmed"
	KeyPaymentTermDue          = "payment.term.due"
	KeyPaymentTermOverdue      = "payment.term.overdue"
	KeyFacilitatorProposed     = "facilitator.proposed"
	KeyFacilitatorApproved     = "facilitator.approved"
	KeyFacilitatorRejected     = "facilitator.rejected"
	KeyTeamMemberCreated       = "team_member.created"
	KeyTeamMemberStatusChanged = "team_member.status_changed"
	KeyInvoiceSent             = "invoice.sent"
	KeyInvoiceOverdue          = "invoice.overdue"
	KeyClassReminder           = "class.reminder"
	KeyCertificateIssued       = "certificate.issued"
)

// RegisterSubscriptions wires all 14 event subscriptions to the bus.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.UserCreated, handleUserCreated(svc))
	bus.Subscribe(events.EnrollmentConfirmed, handleEnrollmentConfirmed(svc))
	bus.Subscribe(events.PaymentConfirmed, handlePaymentConfirmed(svc))
	bus.Subscribe(events.PaymentTermDue, handlePaymentTermDue(svc))
	bus.Subscribe(events.PaymentTermOverdue, handlePaymentTermOverdue(svc))
	bus.Subscribe(events.FacilitatorProposed, handleFacilitatorProposed(svc))
	bus.Subscribe(events.FacilitatorApproved, handleFacilitatorApproved(svc))
	bus.Subscribe(events.FacilitatorRejected, handleFacilitatorRejected(svc))
	bus.Subscribe(events.TeamMemberCreated, handleTeamMemberCreated(svc))
	bus.Subscribe(events.TeamMemberStatusChanged, handleTeamMemberStatusChanged(svc))
	bus.Subscribe(events.InvoiceSent, handleInvoiceSent(svc))
	bus.Subscribe(events.InvoiceOverdue, handleInvoiceOverdue(svc))
	bus.Subscribe(events.ClassReminder, handleClassReminder(svc))
	bus.Subscribe(events.CertificateIssued, handleCertificateIssued(svc))
}

// ── handlers ──────────────────────────────────────────────────────────────────

func handleUserCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			UserID uuid.UUID `json:"user_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse UserCreated payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyUserWelcome,
			RecipientIDs: []uuid.UUID{p.UserID},
			Variables:    map[string]any{},
		})
		return nil
	}
}

func handleEnrollmentConfirmed(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			EnrollmentID uuid.UUID `json:"enrollment_id"`
			UserID       uuid.UUID `json:"user_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse EnrollmentConfirmed payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyEnrollmentConfirmed,
			RecipientIDs: []uuid.UUID{p.UserID},
			Variables:    map[string]any{"enrollment_id": p.EnrollmentID},
		})
		return nil
	}
}

func handlePaymentConfirmed(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			PaymentID uuid.UUID `json:"payment_id"`
			UserID    uuid.UUID `json:"user_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse PaymentConfirmed payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyPaymentConfirmed,
			RecipientIDs: []uuid.UUID{p.UserID},
			Variables:    map[string]any{"payment_id": p.PaymentID},
		})
		return nil
	}
}

func handlePaymentTermDue(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			TermID    uuid.UUID   `json:"term_id"`
			PaymentID uuid.UUID   `json:"payment_id"`
			UserID    uuid.UUID   `json:"user_id"`
			AdminIDs  []uuid.UUID `json:"admin_ids"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse PaymentTermDue payload", zap.Error(err))
			return nil
		}
		recipients := append([]uuid.UUID{p.UserID}, p.AdminIDs...)
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyPaymentTermDue,
			RecipientIDs: recipients,
			Variables:    map[string]any{"term_id": p.TermID, "payment_id": p.PaymentID},
		})
		return nil
	}
}

func handlePaymentTermOverdue(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			TermID    uuid.UUID   `json:"term_id"`
			PaymentID uuid.UUID   `json:"payment_id"`
			UserID    uuid.UUID   `json:"user_id"`
			AdminIDs  []uuid.UUID `json:"admin_ids"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse PaymentTermOverdue payload", zap.Error(err))
			return nil
		}
		recipients := append([]uuid.UUID{p.UserID}, p.AdminIDs...)
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyPaymentTermOverdue,
			RecipientIDs: recipients,
			Variables:    map[string]any{"term_id": p.TermID, "payment_id": p.PaymentID},
		})
		return nil
	}
}

func handleFacilitatorProposed(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ProposalID   uuid.UUID `json:"proposal_id"`
			DeptLeaderID uuid.UUID `json:"dept_leader_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse FacilitatorProposed payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyFacilitatorProposed,
			RecipientIDs: []uuid.UUID{p.DeptLeaderID},
			Variables:    map[string]any{"proposal_id": p.ProposalID},
		})
		return nil
	}
}

func handleFacilitatorApproved(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ProposalID      uuid.UUID `json:"proposal_id"`
			CourseCreatorID uuid.UUID `json:"course_creator_id"`
			FacilitatorID   uuid.UUID `json:"facilitator_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse FacilitatorApproved payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyFacilitatorApproved,
			RecipientIDs: []uuid.UUID{p.CourseCreatorID, p.FacilitatorID},
			Variables:    map[string]any{"proposal_id": p.ProposalID},
		})
		return nil
	}
}

func handleFacilitatorRejected(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ProposalID      uuid.UUID `json:"proposal_id"`
			CourseCreatorID uuid.UUID `json:"course_creator_id"`
			FacilitatorID   uuid.UUID `json:"facilitator_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse FacilitatorRejected payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyFacilitatorRejected,
			RecipientIDs: []uuid.UUID{p.CourseCreatorID, p.FacilitatorID},
			Variables:    map[string]any{"proposal_id": p.ProposalID},
		})
		return nil
	}
}

func handleTeamMemberCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			TeamMemberID uuid.UUID `json:"team_member_id"`
			UserID       uuid.UUID `json:"user_id"`
			DeptLeaderID uuid.UUID `json:"dept_leader_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse TeamMemberCreated payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyTeamMemberCreated,
			RecipientIDs: []uuid.UUID{p.UserID, p.DeptLeaderID},
			Variables:    map[string]any{"team_member_id": p.TeamMemberID},
		})
		return nil
	}
}

func handleTeamMemberStatusChanged(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			TeamMemberID uuid.UUID `json:"team_member_id"`
			UserID       uuid.UUID `json:"user_id"`
			DeptLeaderID uuid.UUID `json:"dept_leader_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse TeamMemberStatusChanged payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyTeamMemberStatusChanged,
			RecipientIDs: []uuid.UUID{p.UserID, p.DeptLeaderID},
			Variables:    map[string]any{"team_member_id": p.TeamMemberID},
		})
		return nil
	}
}

func handleInvoiceSent(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			InvoiceID    uuid.UUID `json:"invoice_id"`
			BilledUserID uuid.UUID `json:"billed_user_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse InvoiceSent payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyInvoiceSent,
			RecipientIDs: []uuid.UUID{p.BilledUserID},
			Variables:    map[string]any{"invoice_id": p.InvoiceID},
		})
		return nil
	}
}

func handleInvoiceOverdue(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			InvoiceID    uuid.UUID   `json:"invoice_id"`
			BilledUserID uuid.UUID   `json:"billed_user_id"`
			AdminIDs     []uuid.UUID `json:"admin_ids"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse InvoiceOverdue payload", zap.Error(err))
			return nil
		}
		recipients := append([]uuid.UUID{p.BilledUserID}, p.AdminIDs...)
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyInvoiceOverdue,
			RecipientIDs: recipients,
			Variables:    map[string]any{"invoice_id": p.InvoiceID},
		})
		return nil
	}
}

func handleClassReminder(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ClassID       uuid.UUID   `json:"class_id"`
			FacilitatorID uuid.UUID   `json:"facilitator_id"`
			AttendeeIDs   []uuid.UUID `json:"attendee_ids"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse ClassReminder payload", zap.Error(err))
			return nil
		}
		recipients := append([]uuid.UUID{p.FacilitatorID}, p.AttendeeIDs...)
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyClassReminder,
			RecipientIDs: recipients,
			Variables:    map[string]any{"class_id": p.ClassID},
		})
		return nil
	}
}

func handleCertificateIssued(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			CertificateID uuid.UUID `json:"certificate_id"`
			StudentID     uuid.UUID `json:"student_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("notification: parse CertificateIssued payload", zap.Error(err))
			return nil
		}
		dispatch(ctx, svc, DispatchRequest{
			Key:          KeyCertificateIssued,
			RecipientIDs: []uuid.UUID{p.StudentID},
			Variables:    map[string]any{"certificate_id": p.CertificateID},
		})
		return nil
	}
}

// ── helpers ───────────────────────────────────────────────────────────────────

func dispatch(ctx context.Context, svc *Service, req DispatchRequest) {
	if err := svc.Dispatch(ctx, req); err != nil {
		svc.log.Error("notification: dispatch failed",
			zap.String("key", req.Key),
			zap.Error(err),
		)
	}
}

func unmarshalPayload(payload any, dst any) error {
	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, dst)
}
