package events

import (
	"time"

	"github.com/google/uuid"
)

// Cross-domain event payload contracts.
//
// All listeners performing notification fan-out type-assert against these
// structs and skip silently on a type mismatch (do not crash the bus).

type EnrollmentConfirmedPayload struct {
	EnrollmentID uuid.UUID
	StudentID    uuid.UUID
	BatchID      uuid.UUID
	CourseTitle  string
}

// EnrollmentCompletedPayload is published when an enrollment transitions to
// completed. Consumed by credentialing for certificate issuance and by
// notifications.
type EnrollmentCompletedPayload struct {
	EnrollmentID uuid.UUID
	StudentID    uuid.UUID
	BatchID      uuid.UUID
}

// EnrollmentDroppedPayload is published when an enrollment is dropped (or
// admin-overridden after completion). Same shape as Completed for now.
type EnrollmentDroppedPayload EnrollmentCompletedPayload

type PaymentConfirmedPayload struct {
	PaymentID uuid.UUID
	StudentID uuid.UUID
	Amount    string
}

type PaymentTermDuePayload struct {
	TermID    uuid.UUID
	StudentID uuid.UUID
	AdminIDs  []uuid.UUID
	AmountDue string
	DueDate   string
}

type PaymentTermOverduePayload PaymentTermDuePayload

type UserCreatedPayload struct {
	UserID   uuid.UUID
	Email    string
	FullName string
}

// FacilitatorProposedPayload is published when a course creator proposes a
// facilitator for a course. Consumed by notification fan-out (dept leader).
type FacilitatorProposedPayload struct {
	ProposalID    uuid.UUID
	CourseID      uuid.UUID
	ProposedBy    uuid.UUID
	FacilitatorID uuid.UUID
}

// FacilitatorApprovedPayload is published once both dept leader and academic
// leader approve a proposal. Calendar listener uses BatchID to fan-out
// attendee adds across class_session events.
type FacilitatorApprovedPayload struct {
	ProposalID    uuid.UUID
	CourseID      uuid.UUID
	FacilitatorID uuid.UUID
	ApprovedBy    uuid.UUID // academic leader
	// BatchID is optional — set by upstream if a batch already exists.
	// May be zero-valued (skipped by calendar listener if so).
	BatchID uuid.UUID
}

// FacilitatorRejectedPayload is published when either reviewer rejects.
type FacilitatorRejectedPayload struct {
	ProposalID    uuid.UUID
	CourseID      uuid.UUID
	FacilitatorID uuid.UUID
	Stage         string // "dept_leader" | "academic_leader"
	RejectedBy    uuid.UUID
}

type InvoiceSentPayload struct {
	InvoiceID     uuid.UUID
	BilledPartyID uuid.UUID
	AdminIDs      []uuid.UUID
	Amount        string
	DueDate       string
}

type InvoiceOverduePayload InvoiceSentPayload

// TeamMemberCreatedPayload describes a newly created team member for
// notification fan-out and downstream listeners.
type TeamMemberCreatedPayload struct {
	TeamMemberID uuid.UUID
	UserID       uuid.UUID
	Role         string
	DepartmentID *uuid.UUID
	Status       string
}

// TeamMemberStatusChangedPayload carries old/new employment status so
// listeners can decide what notification to send.
type TeamMemberStatusChangedPayload struct {
	TeamMemberID uuid.UUID
	OldStatus    string
	NewStatus    string
}

type ClassReminderPayload struct {
	ClassID       uuid.UUID
	FacilitatorID uuid.UUID
	AttendeeIDs   []uuid.UUID
	ClassTitle    string
	StartAt       string
}

type CertificateIssuedPayload struct {
	CertificateID     uuid.UUID
	CertificateNumber string
	StudentID         uuid.UUID
	EnrollmentID      uuid.UUID
	CourseTitle       string
}

// ClassPayload describes a single class within a batch for calendar fan-out.
type ClassPayload struct {
	ClassID  uuid.UUID
	Title    string
	StartAt  time.Time
	EndAt    time.Time
	Location string
}

// BatchCreatedPayload triggers creation of one class_session calendar event per Class.
type BatchCreatedPayload struct {
	BatchID  uuid.UUID
	CourseID uuid.UUID
	Classes  []ClassPayload
}

// BatchClosedPayload is published when a course batch transitions to closed.
type BatchClosedPayload struct {
	BatchID  uuid.UUID
	CourseID uuid.UUID
}

// ClassFacilitatorAssignedPayload triggers attendee add on the class_session event.
type ClassFacilitatorAssignedPayload struct {
	ClassID       uuid.UUID
	FacilitatorID uuid.UUID
}

// ClassRescheduledPayload mutates start/end on the class_session event.
type ClassRescheduledPayload struct {
	ClassID uuid.UUID
	StartAt time.Time
	EndAt   time.Time
}

// ClassCancelledPayload removes the class_session event (attendees cascade).
type ClassCancelledPayload struct {
	ClassID uuid.UUID
}

// PartnershipMeetingScheduledPayload creates a partner_meeting calendar event.
type PartnershipMeetingScheduledPayload struct {
	MeetingID   uuid.UUID
	Title       string
	StartAt     time.Time
	EndAt       time.Time
	Location    string
	Agenda      string
	AttendeeIDs []uuid.UUID
}
