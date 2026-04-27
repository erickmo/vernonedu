package events

// Cross-domain event type constants.
const (
	UserCreated      EventType = "auth.user.created"
	UserDeactivated  EventType = "auth.user.deactivated"

	EnrollmentConfirmed EventType = "enrollment.confirmed"
	EnrollmentCompleted EventType = "enrollment.completed"
	EnrollmentDropped   EventType = "enrollment.dropped"

	BatchCreated              EventType = "course.batch.created"
	BatchClosed               EventType = "course.batch.closed"
	ClassFacilitatorAssigned  EventType = "course.class.facilitator_assigned"
	ClassRescheduled          EventType = "course.class.rescheduled"
	ClassCancelled            EventType = "course.class.cancelled"

	PaymentConfirmed  EventType = "payment.confirmed"
	PaymentTermDue    EventType = "payment.term.due"
	PaymentTermOverdue EventType = "payment.term.overdue"
	PaymentInitiated  EventType = "payment.initiated"
	PaymentSettled    EventType = "payment.settled"
	PaymentFailed     EventType = "payment.failed"

	FacilitatorProposed EventType = "facilitator.proposed"
	FacilitatorApproved EventType = "facilitator.approved"
	FacilitatorRejected EventType = "facilitator.rejected"

	TeamMemberCreated       EventType = "team_member.created"
	TeamMemberStatusChanged EventType = "team_member.status_changed"

	InvoiceSent    EventType = "invoice.sent"
	InvoiceOverdue EventType = "invoice.overdue"

	ClassReminder     EventType = "class.reminder"
	CertificateIssued EventType = "certificate.issued"

	PartnershipMeetingScheduled EventType = "partnership_agreement.meeting_scheduled"
)
