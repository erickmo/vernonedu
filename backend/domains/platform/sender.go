package platform

import (
	"context"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// DefaultNotificationBatchSize is the default batch size used by production
// callers (worker) when invoking ProcessPending. Tests pass an explicit batch
// size argument, so this constant is purely a default for wiring code.
const DefaultNotificationBatchSize = 50

// MaxNotificationRetries is the retry ceiling. After this many delivery
// failures, a notification transitions from pending to failed and is no
// longer picked up by the dispatcher.
const MaxNotificationRetries = 3

// SenderPayload carries the rendered content delivered to a Sender.
type SenderPayload struct {
	NotificationID uuid.UUID
	RecipientID    uuid.UUID
	Channel        NotificationChannel
	Subject        string
	Body           string
}

// Sender delivers a single notification through one channel.
// Implementations must be safe for concurrent use.
type Sender interface {
	Send(ctx context.Context, payload SenderPayload) error
}

// Senders maps a notification channel to the Sender responsible for it.
type Senders map[NotificationChannel]Sender

// EmailSender is a placeholder email channel sender.
// Real SMTP/transactional adapter lands in a follow-up plan.
type EmailSender struct {
	log *zap.Logger
}

// NewEmailSender constructs a stub email sender.
func NewEmailSender(log *zap.Logger) *EmailSender {
	return &EmailSender{log: log}
}

// Send logs the email payload and returns nil. Stub implementation.
func (s *EmailSender) Send(_ context.Context, payload SenderPayload) error {
	s.log.Info("stub email send",
		zap.String("notification_id", payload.NotificationID.String()),
		zap.String("recipient_id", payload.RecipientID.String()),
		zap.String("subject", payload.Subject),
	)
	return nil
}

// InAppSender is a placeholder in-app channel sender.
type InAppSender struct {
	log *zap.Logger
}

// NewInAppSender constructs a stub in-app sender.
func NewInAppSender(log *zap.Logger) *InAppSender {
	return &InAppSender{log: log}
}

// Send logs the in-app payload and returns nil. Stub implementation.
func (s *InAppSender) Send(_ context.Context, payload SenderPayload) error {
	s.log.Info("stub in_app send",
		zap.String("notification_id", payload.NotificationID.String()),
		zap.String("recipient_id", payload.RecipientID.String()),
	)
	return nil
}

// PushSender is a placeholder push channel sender.
type PushSender struct {
	log *zap.Logger
}

// NewPushSender constructs a stub push sender.
func NewPushSender(log *zap.Logger) *PushSender {
	return &PushSender{log: log}
}

// Send logs the push payload and returns nil. Stub implementation.
func (s *PushSender) Send(_ context.Context, payload SenderPayload) error {
	s.log.Info("stub push send",
		zap.String("notification_id", payload.NotificationID.String()),
		zap.String("recipient_id", payload.RecipientID.String()),
	)
	return nil
}

// NewSenders builds the channel→Sender lookup table consumed by the Service.
func NewSenders(email *EmailSender, inApp *InAppSender, push *PushSender) Senders {
	return Senders{
		ChannelEmail: email,
		ChannelInApp: inApp,
		ChannelPush:  push,
	}
}
