package platform

import (
	"time"

	"github.com/google/uuid"
)

type NotificationChannel string

const (
	ChannelEmail  NotificationChannel = "email"
	ChannelInApp  NotificationChannel = "in_app"
	ChannelPush   NotificationChannel = "push"
)

type NotificationStatus string

const (
	NotifPending NotificationStatus = "pending"
	NotifSent    NotificationStatus = "sent"
	NotifFailed  NotificationStatus = "failed"
	NotifRead    NotificationStatus = "read"
)

type NotificationTemplate struct {
	ID        uuid.UUID           `json:"id"`
	Key       string              `json:"key"`
	Channel   NotificationChannel `json:"channel"`
	Subject   *string             `json:"subject,omitempty"`
	Body      string              `json:"body"`
	IsActive  bool                `json:"is_active"`
	CreatedAt time.Time           `json:"created_at"`
	UpdatedAt time.Time           `json:"updated_at"`
}

type Notification struct {
	ID           uuid.UUID          `json:"id"`
	RecipientID  uuid.UUID          `json:"recipient_id"`
	TemplateID   uuid.UUID          `json:"template_id"`
	Channel      NotificationChannel `json:"channel"`
	Variables    map[string]any      `json:"variables"`
	Status       NotificationStatus  `json:"status"`
	SourceDomain *string            `json:"source_domain,omitempty"`
	SourceID     *uuid.UUID         `json:"source_id,omitempty"`
	ScheduledAt  *time.Time         `json:"scheduled_at,omitempty"`
	SentAt       *time.Time         `json:"sent_at,omitempty"`
	ReadAt       *time.Time         `json:"read_at,omitempty"`
	RetryCount   int                `json:"retry_count"`
	ErrorMessage *string            `json:"error_message,omitempty"`
	CreatedAt    time.Time          `json:"created_at"`
	UpdatedAt    time.Time          `json:"updated_at"`
}

type NotificationPreference struct {
	ID          uuid.UUID           `json:"id"`
	UserID      uuid.UUID           `json:"user_id"`
	TemplateKey string              `json:"template_key"`
	Channel     NotificationChannel `json:"channel"`
	Enabled     bool                `json:"enabled"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `json:"updated_at"`
}
