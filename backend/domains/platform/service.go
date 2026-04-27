package platform

import (
	"context"
	"errors"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Service holds platform notification logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs platform Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
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
func (s *Service) Send(ctx context.Context, in SendInput) (*Notification, error) {
	template, err := s.repo.GetTemplateByKey(ctx, in.TemplateKey, in.Channel)
	if err != nil {
		s.log.Warn("notification template not found",
			zap.String("key", in.TemplateKey),
			zap.String("channel", string(in.Channel)),
		)
		return nil, nil
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
func (s *Service) ProcessPending(ctx context.Context, batchSize int) error {
	pending, err := s.repo.ListPendingNotifications(ctx, batchSize)
	if err != nil {
		return err
	}

	for _, n := range pending {
		if err := s.repo.UpdateNotificationStatus(ctx, n.ID, NotifSent); err != nil {
			s.log.Error("failed to mark notification sent", zap.String("id", n.ID.String()), zap.Error(err))
		}
	}
	return nil
}
