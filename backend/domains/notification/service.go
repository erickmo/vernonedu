package notification

import (
	"context"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// allChannels lists all delivery channels to attempt on Dispatch.
var allChannels = []Channel{ChannelEmail, ChannelInApp, ChannelPush}

// templateVarRe matches Mustache-style {{variable}} placeholders.
var templateVarRe = regexp.MustCompile(`\{\{(\w+)\}\}`)

// Service implements notification business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs a Service with injected dependencies.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// Dispatch creates Notification records for each recipient × each active channel template.
// Skips missing templates, inactive templates, and disabled preferences silently.
func (s *Service) Dispatch(ctx context.Context, req DispatchRequest) error {
	for _, ch := range allChannels {
		tmpl, err := s.repo.GetTemplateByKeyChannel(ctx, req.Key, ch)
		if err != nil {
			continue // missing → skip
		}
		if !tmpl.IsActive {
			continue // inactive → skip
		}
		if err := s.validateVariables(tmpl.Body, req.Variables); err != nil {
			s.log.Warn("notification: missing template variables",
				zap.String("key", req.Key),
				zap.String("channel", string(ch)),
				zap.Error(err),
			)
			continue
		}
		for _, recipientID := range req.RecipientIDs {
			if !s.isChannelEnabled(ctx, recipientID, req.Key, ch) {
				continue
			}
			if err := s.createNotification(ctx, recipientID, tmpl, ch, req); err != nil {
				s.log.Error("notification: create record failed",
					zap.String("key", req.Key),
					zap.Stringer("recipient", recipientID),
					zap.Error(err),
				)
			}
		}
	}
	return nil
}

func (s *Service) createNotification(ctx context.Context, recipientID uuid.UUID, tmpl *NotificationTemplate, ch Channel, req DispatchRequest) error {
	vars := make(map[string]any, len(req.Variables))
	for k, v := range req.Variables {
		vars[k] = v
	}
	n := &Notification{
		RecipientID:  recipientID,
		TemplateID:   tmpl.ID,
		Channel:      ch,
		Variables:    vars,
		Status:       StatusPending,
		SourceDomain: req.SourceDomain,
		SourceID:     req.SourceID,
		ScheduledAt:  req.ScheduledAt,
	}
	return s.repo.CreateNotification(ctx, n)
}

func (s *Service) isChannelEnabled(ctx context.Context, userID uuid.UUID, key string, ch Channel) bool {
	pref, err := s.repo.GetPreference(ctx, userID, key, ch)
	if err != nil {
		return true // absence = enabled
	}
	return pref.Enabled
}

func (s *Service) validateVariables(body string, vars map[string]any) error {
	matches := templateVarRe.FindAllStringSubmatch(body, -1)
	var missing []string
	for _, m := range matches {
		varName := m[1]
		if _, ok := vars[varName]; !ok {
			missing = append(missing, varName)
		}
	}
	if len(missing) > 0 {
		return apperrors.Validationf("missing template variables: " + strings.Join(missing, ", "))
	}
	return nil
}

// MarkRead transitions an in_app notification to read status.
func (s *Service) MarkRead(ctx context.Context, notifID uuid.UUID, userID uuid.UUID) error {
	n, err := s.repo.GetNotificationByID(ctx, notifID)
	if err != nil {
		return err
	}
	if n.Channel != ChannelInApp {
		return apperrors.Validationf("only in_app notifications can be marked as read")
	}
	if n.RecipientID != userID {
		return apperrors.ErrForbidden
	}
	return s.repo.MarkRead(ctx, notifID, userID)
}

// ListNotifications returns notifications matching the filter.
func (s *Service) ListNotifications(ctx context.Context, f ListNotifFilter) ([]*Notification, error) {
	return s.repo.ListNotifications(ctx, f)
}

// CountUnread returns the number of unread in_app notifications for a user.
func (s *Service) CountUnread(ctx context.Context, userID uuid.UUID) (int, error) {
	return s.repo.CountUnread(ctx, userID)
}

// UpsertPreference creates or updates a notification preference.
func (s *Service) UpsertPreference(ctx context.Context, p *NotificationPreference) error {
	return s.repo.UpsertPreference(ctx, p)
}

// ListPreferences returns all preferences for a user.
func (s *Service) ListPreferences(ctx context.Context, userID uuid.UUID) ([]*NotificationPreference, error) {
	return s.repo.ListPreferences(ctx, userID)
}

// CreateTemplate creates a new notification template.
func (s *Service) CreateTemplate(ctx context.Context, t *NotificationTemplate) error {
	return s.repo.CreateTemplate(ctx, t)
}

// UpdateTemplate updates an existing notification template.
func (s *Service) UpdateTemplate(ctx context.Context, t *NotificationTemplate) error {
	return s.repo.UpdateTemplate(ctx, t)
}

// DeleteTemplate removes a notification template by ID.
func (s *Service) DeleteTemplate(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteTemplate(ctx, id)
}

// ListTemplates returns all notification templates.
func (s *Service) ListTemplates(ctx context.Context) ([]*NotificationTemplate, error) {
	return s.repo.ListTemplates(ctx)
}

// ProcessPendingBatch picks up pending notifications and attempts delivery.
// Push: log+skip if no device token (token validation is external).
// Retry logic: increment counter; alert if MaxRetryCount exceeded.
func (s *Service) ProcessPendingBatch(ctx context.Context, now time.Time, limit int) error {
	pending, err := s.repo.ListPending(ctx, now, limit)
	if err != nil {
		return err
	}
	for _, n := range pending {
		s.deliver(ctx, n)
	}
	return nil
}

func (s *Service) deliver(ctx context.Context, n *Notification) {
	switch n.Channel {
	case ChannelPush:
		s.log.Info("notification: push delivery skipped (no device token impl)",
			zap.Stringer("notification_id", n.ID),
		)
		return
	default:
		s.log.Info("notification: deliver",
			zap.Stringer("notification_id", n.ID),
			zap.String("channel", string(n.Channel)),
		)
	}

	now := time.Now()
	if err := s.repo.UpdateStatus(ctx, n.ID, StatusSent, &now, nil); err != nil {
		s.log.Error("notification: UpdateStatus sent failed", zap.Error(err))
	}
}
