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
	CourseTitle  string
}

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

type FacilitatorEventPayload struct {
	FacilitatorID   uuid.UUID
	CourseCreatorID uuid.UUID
	DeptLeaderID    uuid.UUID
	CourseTitle     string
	// BatchID is set on facilitator.approved so the calendar listener can
	// fan-out attendee adds to every class_session event for the batch.
	// Other lifecycle events (proposed/rejected) may leave it zero-valued.
	BatchID uuid.UUID
}

type InvoiceSentPayload struct {
	InvoiceID     uuid.UUID
	BilledPartyID uuid.UUID
	AdminIDs      []uuid.UUID
	Amount        string
	DueDate       string
}

type InvoiceOverduePayload InvoiceSentPayload

type TeamMemberEventPayload struct {
	MemberID     uuid.UUID
	DeptLeaderID uuid.UUID
	Status       string
}

type ClassReminderPayload struct {
	ClassID       uuid.UUID
	FacilitatorID uuid.UUID
	AttendeeIDs   []uuid.UUID
	ClassTitle    string
	StartAt       string
}

type CertificateIssuedPayload struct {
	CertificateID uuid.UUID
	StudentID     uuid.UUID
	CourseTitle   string
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
	BatchID uuid.UUID
	Classes []ClassPayload
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
