package calendar

import (
	"time"

	"github.com/google/uuid"
)

type CalEventType string

const (
	EventTypeClassSession     CalEventType = "class_session"
	EventTypeStaffMeeting     CalEventType = "staff_meeting"
	EventTypeAdminDeadline    CalEventType = "admin_deadline"
	EventTypePaymentDue       CalEventType = "payment_due"
	EventTypeFacilitatorSched CalEventType = "facilitator_schedule"
	EventTypePartnerMeeting   CalEventType = "partner_meeting"
)

type SourceDomain string

const (
	SourceCourse     SourceDomain = "course"
	SourceEnrollment SourceDomain = "enrollment"
	SourcePayment    SourceDomain = "payment"
	SourceTeamMember SourceDomain = "team_member"
	SourcePartner    SourceDomain = "partner"
	SourceManual     SourceDomain = "manual"
)

type AttendeeRole string

const (
	RoleOrganizer AttendeeRole = "organizer"
	RoleAttendee  AttendeeRole = "attendee"
)

type RSVPStatus string

const (
	RSVPPending  RSVPStatus = "pending"
	RSVPAccepted RSVPStatus = "accepted"
	RSVPDeclined RSVPStatus = "declined"
)

type SyncProvider string

const ProviderGoogleCalendar SyncProvider = "google_calendar"

type CalendarEvent struct {
	ID                     uuid.UUID     `json:"id"`
	Title                  string        `json:"title"`
	Description            *string       `json:"description,omitempty"`
	EventType              CalEventType  `json:"event_type"`
	StartAt                time.Time     `json:"start_at"`
	EndAt                  time.Time     `json:"end_at"`
	IsAllDay               bool          `json:"is_all_day"`
	RecurrenceRule         *string       `json:"recurrence_rule,omitempty"`
	Location               *string       `json:"location,omitempty"`
	SourceDomain           *SourceDomain `json:"source_domain,omitempty"`
	SourceID               *uuid.UUID    `json:"source_id,omitempty"`
	PartnershipAgreementID *uuid.UUID    `json:"partnership_agreement_id,omitempty"`
	Agenda                 *string       `json:"agenda,omitempty"`
	MeetingNotes           *string       `json:"meeting_notes,omitempty"`
	ClassReminderSent      bool          `json:"-"`
	CreatedBy              uuid.UUID     `json:"created_by"`
	CreatedAt              time.Time     `json:"created_at"`
}

type CalendarAttendee struct {
	ID         uuid.UUID    `json:"id"`
	EventID    uuid.UUID    `json:"event_id"`
	UserID     uuid.UUID    `json:"user_id"`
	Role       AttendeeRole `json:"role"`
	RSVPStatus RSVPStatus   `json:"rsvp_status"`
}

type CalendarSync struct {
	ID             uuid.UUID    `json:"id"`
	UserID         uuid.UUID    `json:"user_id"`
	Provider       SyncProvider `json:"provider"`
	AccessToken    string       `json:"-"`
	RefreshToken   string       `json:"-"`
	LastSyncedAt   *time.Time   `json:"last_synced_at,omitempty"`
	TokenExpiresAt *time.Time   `json:"token_expires_at,omitempty"`
}

type ListFilter struct {
	UserID    *uuid.UUID
	From      *time.Time
	To        *time.Time
	EventType *CalEventType
}

// ClassInfo is a cross-schema read from catalog.classes.
type ClassInfo struct {
	ID          uuid.UUID
	BatchID     uuid.UUID
	Title       *string
	SessionDate time.Time
	StartTime   time.Time
	EndTime     time.Time
	Mode        string
	Location    *string
	OnlineLink  *string
}
