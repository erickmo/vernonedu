package platform

import (
	"context"

	"github.com/google/uuid"
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
