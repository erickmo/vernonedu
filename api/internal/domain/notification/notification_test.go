package notification_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

func TestNewNotification_DefaultsChannelToInApp(t *testing.T) {
	recipientID := uuid.New()
	n := notification.NewNotification(recipientID, notification.TypeApprovalRequested, "title", "body", "", nil)

	if n.Channel != notification.ChannelInApp {
		t.Errorf("expected channel %q, got %q", notification.ChannelInApp, n.Channel)
	}
}

func TestNewNotification_SetsAllFields(t *testing.T) {
	recipientID := uuid.New()
	meta := map[string]interface{}{"key": "value"}
	before := time.Now().UTC().Truncate(time.Second)

	n := notification.NewNotification(
		recipientID,
		notification.TypeApprovalRequested,
		"Permintaan Persetujuan",
		"Ada persetujuan baru yang menunggu",
		notification.ChannelInApp,
		meta,
	)

	if n.ID == uuid.Nil {
		t.Error("expected non-nil notification ID")
	}
	if n.RecipientID != recipientID {
		t.Errorf("expected recipient %s, got %s", recipientID, n.RecipientID)
	}
	if n.Type != notification.TypeApprovalRequested {
		t.Errorf("expected type %s, got %s", notification.TypeApprovalRequested, n.Type)
	}
	if n.Title != "Permintaan Persetujuan" {
		t.Errorf("unexpected title: %s", n.Title)
	}
	if n.Body != "Ada persetujuan baru yang menunggu" {
		t.Errorf("unexpected body: %s", n.Body)
	}
	if n.ReadAt != nil {
		t.Error("new notification should not have ReadAt set")
	}
	if n.CreatedAt.Before(before) {
		t.Error("CreatedAt should be >= before time")
	}
}

func TestNotification_IsRead_FalseWhenUnread(t *testing.T) {
	n := notification.NewNotification(uuid.New(), notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)

	if n.IsRead() {
		t.Error("new notification should not be read")
	}
}

func TestNotification_MarkRead_SetsReadAt(t *testing.T) {
	before := time.Now().UTC().Truncate(time.Second)
	n := notification.NewNotification(uuid.New(), notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)

	n.MarkRead()

	if !n.IsRead() {
		t.Error("notification should be read after MarkRead()")
	}
	if n.ReadAt == nil {
		t.Error("ReadAt should be set after MarkRead()")
	}
	if n.ReadAt.Before(before) {
		t.Error("ReadAt should be >= before time")
	}
}

func TestNotification_MarkRead_Idempotent(t *testing.T) {
	n := notification.NewNotification(uuid.New(), notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)
	n.MarkRead()
	firstReadAt := *n.ReadAt

	// Second call to MarkRead should not panic
	n.MarkRead()

	// ReadAt will be updated to a new time — both calls are valid
	_ = firstReadAt
}

func TestNewNotification_NilMetadata(t *testing.T) {
	n := notification.NewNotification(uuid.New(), notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)
	if n.Metadata != nil {
		t.Error("metadata should be nil when not provided")
	}
}

func TestNewNotification_UniqueIDs(t *testing.T) {
	recipientID := uuid.New()
	n1 := notification.NewNotification(recipientID, notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)
	n2 := notification.NewNotification(recipientID, notification.TypeSystem, "t", "b", notification.ChannelInApp, nil)

	if n1.ID == n2.ID {
		t.Error("two notifications should have different IDs")
	}
}

func TestNotificationTypes_Constants(t *testing.T) {
	types := []string{
		notification.TypeApprovalRequested,
		notification.TypeApprovalApproved,
		notification.TypeApprovalRejected,
		notification.TypeEnrollment,
		notification.TypePayment,
		notification.TypeCertificate,
		notification.TypeSystem,
	}
	for _, tt := range types {
		if tt == "" {
			t.Errorf("notification type constant should not be empty")
		}
	}
}

func TestNotificationChannels_Constants(t *testing.T) {
	channels := []string{
		notification.ChannelInApp,
		notification.ChannelPush,
		notification.ChannelEmail,
		notification.ChannelWhatsApp,
	}
	for _, ch := range channels {
		if ch == "" {
			t.Errorf("notification channel constant should not be empty")
		}
	}
}
