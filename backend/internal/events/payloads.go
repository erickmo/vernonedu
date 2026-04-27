package events

import "github.com/google/uuid"

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
