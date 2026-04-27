package platform

import (
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// RegisterSubscriptions wires every cross-domain event that should produce a
// notification to its dedicated handler on the Service. Each handler is
// responsible for its own type-assertion + recipient fan-out and never
// returns an error so that one bad recipient cannot block sibling sends or
// other handlers on the bus.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	registrations := []struct {
		t events.EventType
		h events.HandlerFunc
	}{
		{events.EnrollmentConfirmed, svc.handleEnrollmentConfirmed},
		{events.PaymentConfirmed, svc.handlePaymentConfirmed},
		{events.PaymentTermDue, svc.handlePaymentTermDue},
		{events.PaymentTermOverdue, svc.handlePaymentTermOverdue},
		{events.UserCreated, svc.handleUserCreated},
		{events.FacilitatorProposed, svc.handleFacilitatorProposed},
		{events.FacilitatorApproved, svc.handleFacilitatorApproved},
		{events.FacilitatorRejected, svc.handleFacilitatorRejected},
		{events.InvoiceSent, svc.handleInvoiceSent},
		{events.InvoiceOverdue, svc.handleInvoiceOverdue},
		{events.TeamMemberCreated, svc.handleTeamMemberCreated},
		{events.TeamMemberStatusChanged, svc.handleTeamMemberStatusChanged},
		{events.ClassReminder, svc.handleClassReminder},
		{events.CertificateIssued, svc.handleCertificateIssued},
	}
	for _, r := range registrations {
		bus.Subscribe(r.t, r.h)
	}
}
