package notification

import (
	"time"

	"github.com/google/uuid"
)

// Channel identifies the delivery channel for a notification.
type Channel string

const (
	ChannelEmail Channel = "email"
	ChannelInApp Channel = "in_app"
	ChannelPush  Channel = "push"
)

// NotifStatus represents the delivery state of a notification.
type NotifStatus string

const (
	StatusPending NotifStatus = "pending"
	StatusSent    NotifStatus = "sent"
	StatusFailed  NotifStatus = "failed"
	StatusRead    NotifStatus = "read"
)

// MaxRetryCount is the maximum number of delivery retries before alerting admins.
const MaxRetryCount = 3

// NotificationTemplate is the per-key+channel message template.
type NotificationTemplate struct {
	ID        uuid.UUID `json:"id"`
	Key       string    `json:"key"`
	Channel   Channel   `json:"channel"`
	Subject   *string   `json:"subject,omitempty"`
	Body      string    `json:"body"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Notification is a single delivery attempt per recipient per channel.
type Notification struct {
	ID           uuid.UUID   `json:"id"`
	RecipientID  uuid.UUID   `json:"recipient_id"`
	TemplateID   uuid.UUID   `json:"template_id"`
	Channel      Channel     `json:"channel"`
	Variables    map[string]any `json:"variables"`
	Status       NotifStatus `json:"status"`
	SourceDomain *string     `json:"source_domain,omitempty"`
	SourceID     *uuid.UUID  `json:"source_id,omitempty"`
	ScheduledAt  *time.Time  `json:"scheduled_at,omitempty"`
	SentAt       *time.Time  `json:"sent_at,omitempty"`
	ReadAt       *time.Time  `json:"read_at,omitempty"`
	RetryCount   int         `json:"retry_count"`
	ErrorMessage *string     `json:"error_message,omitempty"`
	CreatedAt    time.Time   `json:"created_at"`
}

// NotificationPreference controls per-user opt-in/out per key+channel.
// Absence of a record means enabled by default.
type NotificationPreference struct {
	ID          uuid.UUID `json:"id"`
	UserID      uuid.UUID `json:"user_id"`
	TemplateKey string    `json:"template_key"`
	Channel     Channel   `json:"channel"`
	Enabled     bool      `json:"enabled"`
}

// DispatchRequest triggers notification creation for one or more recipients.
type DispatchRequest struct {
	Key          string
	Variables    map[string]any
	RecipientIDs []uuid.UUID
	SourceDomain *string
	SourceID     *uuid.UUID
	ScheduledAt  *time.Time
}

// ListNotifFilter filters notifications for listing.
type ListNotifFilter struct {
	RecipientID *uuid.UUID
	Status      *NotifStatus
	Channel     *Channel
}
