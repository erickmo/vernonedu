package notification

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Notification type constants
const (
	TypeApprovalRequested = "approval_requested"
	TypeApprovalApproved  = "approval_approved"
	TypeApprovalRejected  = "approval_rejected"
	TypeEnrollment        = "enrollment"
	TypePayment           = "payment"
	TypeCertificate       = "certificate"
	TypeSystem            = "system"
)

// Notification channel constants
const (
	ChannelInApp    = "in_app"
	ChannelPush     = "push"
	ChannelEmail    = "email"
	ChannelWhatsApp = "whatsapp"
)

var (
	ErrNotificationNotFound = errors.New("notification not found")
	ErrInvalidRecipient     = errors.New("invalid recipient id")
	ErrInvalidType          = errors.New("invalid notification type")
)

// Notification is the core domain entity for in-app notifications.
type Notification struct {
	ID          uuid.UUID
	RecipientID uuid.UUID
	Type        string
	Title       string
	Body        string
	Channel     string
	Metadata    map[string]interface{}
	ReadAt      *time.Time
	CreatedAt   time.Time
}

// NewNotification constructs a new unread in-app notification.
func NewNotification(
	recipientID uuid.UUID,
	notifType, title, body, channel string,
	metadata map[string]interface{},
) *Notification {
	if channel == "" {
		channel = ChannelInApp
	}
	return &Notification{
		ID:          uuid.New(),
		RecipientID: recipientID,
		Type:        notifType,
		Title:       title,
		Body:        body,
		Channel:     channel,
		Metadata:    metadata,
		CreatedAt:   time.Now(),
	}
}

// MarkRead marks this notification as read.
func (n *Notification) MarkRead() {
	now := time.Now()
	n.ReadAt = &now
}

// IsRead returns true if the notification has been read.
func (n *Notification) IsRead() bool {
	return n.ReadAt != nil
}

// WriteRepository defines write operations for notifications.
type WriteRepository interface {
	Save(ctx context.Context, n *Notification) error
	MarkRead(ctx context.Context, id, recipientID uuid.UUID) error
	MarkAllRead(ctx context.Context, recipientID uuid.UUID) error
}

// ReadRepository defines read operations for notifications.
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Notification, error)
	ListByRecipient(
		ctx context.Context,
		recipientID uuid.UUID,
		offset, limit int,
		onlyUnread bool,
		notifType string,
	) ([]*Notification, int, error)
	GetUnreadCount(ctx context.Context, recipientID uuid.UUID) (int, error)
}
