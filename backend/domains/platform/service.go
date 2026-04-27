package platform

import (
	"context"
	"errors"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// HasDeviceTokenFunc reports whether a user has a registered push device token.
// Used by Send() to skip Push-channel notifications when the recipient cannot
// receive them. The default implementation returns false; identity-domain wiring
// is expected to override it later.
type HasDeviceTokenFunc func(ctx context.Context, userID uuid.UUID) (bool, error)

// Service holds platform notification logic.
type Service struct {
	repo    Repository
	bus     events.Bus
	log     *zap.Logger
	senders Senders

	// HasDeviceTokenFn is used to gate Push-channel deliveries.
	// Defaults to a stub returning (false, nil) until identity wiring is added.
	HasDeviceTokenFn HasDeviceTokenFunc
}

// NewService constructs platform Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger, senders Senders) *Service {
	return &Service{
		repo:    repo,
		bus:     bus,
		log:     log,
		senders: senders,
		HasDeviceTokenFn: func(context.Context, uuid.UUID) (bool, error) {
			return false, nil
		},
	}
}

// CreateTemplate creates a new active notification template.
// Returns apperrors.ErrConflict on duplicate (key, channel).
func (s *Service) CreateTemplate(ctx context.Context, key string, channel NotificationChannel, subject *string, body string) (*NotificationTemplate, error) {
	t := &NotificationTemplate{
		ID:       uuid.New(),
		Key:      key,
		Channel:  channel,
		Subject:  subject,
		Body:     body,
		IsActive: true,
	}
	if err := s.repo.CreateTemplate(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

// DeactivateTemplate flips is_active=false on the template (soft delete).
func (s *Service) DeactivateTemplate(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeactivateTemplate(ctx, id)
}

// GetActiveTemplate returns the active template for (key, channel) or (nil, nil)
// when missing or inactive — silent skip per platform spec rules.
func (s *Service) GetActiveTemplate(ctx context.Context, key string, channel NotificationChannel) (*NotificationTemplate, error) {
	t, err := s.repo.GetTemplateByKey(ctx, key, channel)
	if err != nil {
		if errors.Is(err, apperrors.ErrNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return t, nil
}

// SendInput carries notification dispatch parameters.
type SendInput struct {
	RecipientID  uuid.UUID
	TemplateKey  string
	Channel      NotificationChannel
	Variables    map[string]any
	SourceDomain *string
	SourceID     *uuid.UUID
}

// Send creates and dispatches a notification.
//
// Behaviour (per platform spec):
//   - Missing or inactive template       → silent skip, returns (nil, nil)
//   - Preference exists with enabled=false → silent skip, returns (nil, nil)
//   - Push channel without device_token  → silent skip, returns (nil, nil)
//   - Template body references a variable not in Variables → returns (nil, ErrMissingVariable)
//   - Otherwise creates a pending notification
func (s *Service) Send(ctx context.Context, in SendInput) (*Notification, error) {
	template, err := s.repo.GetTemplateByKey(ctx, in.TemplateKey, in.Channel)
	if err != nil {
		if errors.Is(err, apperrors.ErrNotFound) {
			s.log.Warn("notification template not found",
				zap.String("key", in.TemplateKey),
				zap.String("channel", string(in.Channel)),
			)
			return nil, nil
		}
		return nil, err
	}

	// Preference check — absence treated as enabled.
	pref, err := s.repo.GetPreference(ctx, in.RecipientID, in.TemplateKey, in.Channel)
	if err != nil && !errors.Is(err, apperrors.ErrNotFound) {
		return nil, err
	}
	if pref != nil && !pref.Enabled {
		return nil, nil
	}

	// Push channel requires a registered device token.
	if in.Channel == ChannelPush {
		ok, err := s.HasDeviceTokenFn(ctx, in.RecipientID)
		if err != nil {
			return nil, err
		}
		if !ok {
			return nil, nil
		}
	}

	// Validate template variables: render body (and subject if present).
	// Missing keys → ErrMissingVariable, no record is created.
	if _, err := Render(template.Body, in.Variables); err != nil {
		if errors.Is(err, ErrMissingVariable) {
			return nil, ErrMissingVariable
		}
		return nil, err
	}
	if template.Subject != nil {
		if _, err := Render(*template.Subject, in.Variables); err != nil {
			if errors.Is(err, ErrMissingVariable) {
				return nil, ErrMissingVariable
			}
			return nil, err
		}
	}

	n := &Notification{
		ID:           uuid.New(),
		RecipientID:  in.RecipientID,
		TemplateID:   template.ID,
		Channel:      in.Channel,
		Variables:    in.Variables,
		Status:       NotifPending,
		SourceDomain: in.SourceDomain,
		SourceID:     in.SourceID,
	}

	if err := s.repo.CreateNotification(ctx, n); err != nil {
		return nil, err
	}

	return n, nil
}

// MarkRead marks a notification as read.
func (s *Service) MarkRead(ctx context.Context, id uuid.UUID) error {
	return s.repo.MarkNotificationRead(ctx, id)
}

// ListMyNotifications returns paginated notifications for a recipient.
func (s *Service) ListMyNotifications(ctx context.Context, recipientID uuid.UUID, limit, offset int) ([]*Notification, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	return s.repo.ListNotificationsByRecipient(ctx, recipientID, limit, offset)
}

// ProcessPending dispatches pending notifications (called by worker).
//
// For each ready notification (status=pending and scheduled_at NULL or due):
//  1. Load the template (by ID) and render subject + body against variables.
//  2. Look up the channel-specific Sender and invoke Send.
//  3. On success, mark the notification sent.
//  4. On failure, increment retry_count; once it reaches MaxNotificationRetries
//     the notification transitions to status=failed.
//
// Per-notification errors are logged and do not abort the batch — the worker
// keeps draining until the batch is exhausted.
func (s *Service) ProcessPending(ctx context.Context, batchSize int) error {
	pending, err := s.repo.ListPendingNotifications(ctx, batchSize)
	if err != nil {
		return err
	}

	for _, n := range pending {
		s.dispatchOne(ctx, n)
	}
	return nil
}

// dispatchOne handles delivery for a single notification including
// per-step error handling. Kept under the 40-line limit.
func (s *Service) dispatchOne(ctx context.Context, n *Notification) {
	payload, err := s.buildPayload(ctx, n)
	if err != nil {
		s.recordFailure(ctx, n.ID, err)
		return
	}

	sender, ok := s.senders[n.Channel]
	if !ok || sender == nil {
		s.recordFailure(ctx, n.ID, errors.New("no sender for channel "+string(n.Channel)))
		return
	}

	if err := sender.Send(ctx, payload); err != nil {
		s.recordFailure(ctx, n.ID, err)
		return
	}

	if err := s.repo.MarkNotificationSent(ctx, n.ID); err != nil {
		s.log.Error("failed to mark notification sent",
			zap.String("id", n.ID.String()),
			zap.Error(err),
		)
	}
}

// buildPayload renders the template and assembles a SenderPayload.
func (s *Service) buildPayload(ctx context.Context, n *Notification) (SenderPayload, error) {
	tmpl, err := s.repo.GetTemplateByID(ctx, n.TemplateID)
	if err != nil {
		return SenderPayload{}, err
	}

	body, err := Render(tmpl.Body, n.Variables)
	if err != nil {
		return SenderPayload{}, err
	}

	var subject string
	if tmpl.Subject != nil {
		subject, err = Render(*tmpl.Subject, n.Variables)
		if err != nil {
			return SenderPayload{}, err
		}
	}

	return SenderPayload{
		NotificationID: n.ID,
		RecipientID:    n.RecipientID,
		Channel:        n.Channel,
		Subject:        subject,
		Body:           body,
	}, nil
}

// recordFailure logs and persists a delivery failure.
func (s *Service) recordFailure(ctx context.Context, id uuid.UUID, cause error) {
	s.log.Warn("notification delivery failed",
		zap.String("id", id.String()),
		zap.Error(cause),
	)
	if err := s.repo.RecordNotificationFailure(ctx, id, cause.Error()); err != nil {
		s.log.Error("failed to record notification failure",
			zap.String("id", id.String()),
			zap.Error(err),
		)
	}
}
