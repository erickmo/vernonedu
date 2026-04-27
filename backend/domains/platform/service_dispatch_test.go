package platform_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

// mockSender records every Send call and optionally returns a configured error.
type mockSender struct {
	mu       sync.Mutex
	calls    []platform.SenderPayload
	returnFn func(platform.SenderPayload) error
}

func (m *mockSender) Send(_ context.Context, payload platform.SenderPayload) error {
	m.mu.Lock()
	m.calls = append(m.calls, payload)
	fn := m.returnFn
	m.mu.Unlock()
	if fn != nil {
		return fn(payload)
	}
	return nil
}

func (m *mockSender) callCount() int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return len(m.calls)
}

func newDispatchSvc(t *testing.T, senders platform.Senders) (*platform.Service, platform.Repository, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, usersTable, templatesTable, notificationsTable, preferencesTable)
	repo := platform.NewRepository(pool)
	svc := platform.NewService(repo, nil, zap.NewNop(), senders, nil, nil)
	return svc, repo, pool
}

func insertPendingNotification(
	t *testing.T,
	pool *pgxpool.Pool,
	recipientID, templateID uuid.UUID,
	channel platform.NotificationChannel,
	vars map[string]any,
	scheduledAt *time.Time,
) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO platform.notifications
		 (id, recipient_id, template_id, channel, variables, status, scheduled_at)
		 VALUES ($1,$2,$3,$4,$5,'pending',$6)`,
		id, recipientID, templateID, channel, vars, scheduledAt,
	)
	require.NoError(t, err)
	return id
}

type notifRow struct {
	status       string
	retryCount   int
	errorMessage *string
	sentAt       *time.Time
}

func fetchNotif(t *testing.T, pool *pgxpool.Pool, id uuid.UUID) notifRow {
	t.Helper()
	var r notifRow
	err := pool.QueryRow(context.Background(),
		`SELECT status, retry_count, error_message, sent_at
		 FROM platform.notifications WHERE id=$1`, id,
	).Scan(&r.status, &r.retryCount, &r.errorMessage, &r.sentAt)
	require.NoError(t, err)
	return r
}

func TestProcessPending_PicksUpReadyAndCallsCorrectSender(t *testing.T) {
	mockEmail := &mockSender{}
	senders := platform.Senders{platform.ChannelEmail: mockEmail}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	tmpl, err := svc.CreateTemplate(ctx, "welcome", platform.ChannelEmail, nil, "Hi {{.name}}")
	require.NoError(t, err)

	notifID := insertPendingNotification(t, pool, uid, tmpl.ID, platform.ChannelEmail,
		map[string]any{"name": "X"}, nil)

	require.NoError(t, svc.ProcessPending(ctx, 10))

	require.Equal(t, 1, mockEmail.callCount())
	assert.Equal(t, "Hi X", mockEmail.calls[0].Body)
	assert.Equal(t, notifID, mockEmail.calls[0].NotificationID)

	row := fetchNotif(t, pool, notifID)
	assert.Equal(t, "sent", row.status)
	assert.NotNil(t, row.sentAt)
}

func TestProcessPending_SkipsScheduledInFuture(t *testing.T) {
	mockEmail := &mockSender{}
	senders := platform.Senders{platform.ChannelEmail: mockEmail}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	tmpl, err := svc.CreateTemplate(ctx, "later", platform.ChannelEmail, nil, "later")
	require.NoError(t, err)

	future := time.Now().Add(1 * time.Hour)
	notifID := insertPendingNotification(t, pool, uid, tmpl.ID, platform.ChannelEmail,
		map[string]any{}, &future)

	require.NoError(t, svc.ProcessPending(ctx, 10))

	assert.Equal(t, 0, mockEmail.callCount())
	row := fetchNotif(t, pool, notifID)
	assert.Equal(t, "pending", row.status)
}

func TestProcessPending_FailureIncrementsRetryStaysPending(t *testing.T) {
	mockEmail := &mockSender{returnFn: func(platform.SenderPayload) error {
		return errors.New("smtp down")
	}}
	senders := platform.Senders{platform.ChannelEmail: mockEmail}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	tmpl, err := svc.CreateTemplate(ctx, "fail1", platform.ChannelEmail, nil, "x")
	require.NoError(t, err)

	notifID := insertPendingNotification(t, pool, uid, tmpl.ID, platform.ChannelEmail,
		map[string]any{}, nil)

	require.NoError(t, svc.ProcessPending(ctx, 10))

	row := fetchNotif(t, pool, notifID)
	assert.Equal(t, "pending", row.status)
	assert.Equal(t, 1, row.retryCount)
	require.NotNil(t, row.errorMessage)
	assert.Equal(t, "smtp down", *row.errorMessage)
}

func TestProcessPending_ThreeFailuresMarkFailed(t *testing.T) {
	mockEmail := &mockSender{returnFn: func(platform.SenderPayload) error {
		return errors.New("smtp down")
	}}
	senders := platform.Senders{platform.ChannelEmail: mockEmail}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	tmpl, err := svc.CreateTemplate(ctx, "fail3", platform.ChannelEmail, nil, "x")
	require.NoError(t, err)

	notifID := insertPendingNotification(t, pool, uid, tmpl.ID, platform.ChannelEmail,
		map[string]any{}, nil)

	for i := 0; i < 3; i++ {
		require.NoError(t, svc.ProcessPending(ctx, 10))
	}

	row := fetchNotif(t, pool, notifID)
	assert.Equal(t, "failed", row.status)
	assert.Equal(t, 3, row.retryCount)

	callsBefore := mockEmail.callCount()

	// 4th call: notification is no longer pending, sender must not be called again.
	require.NoError(t, svc.ProcessPending(ctx, 10))
	assert.Equal(t, callsBefore, mockEmail.callCount())
}

func TestProcessPending_BatchLimitHonored(t *testing.T) {
	mockEmail := &mockSender{}
	senders := platform.Senders{platform.ChannelEmail: mockEmail}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	tmpl, err := svc.CreateTemplate(ctx, "batch", platform.ChannelEmail, nil, "x")
	require.NoError(t, err)

	for i := 0; i < 5; i++ {
		insertPendingNotification(t, pool, uid, tmpl.ID, platform.ChannelEmail,
			map[string]any{}, nil)
	}

	require.NoError(t, svc.ProcessPending(ctx, 2))

	assert.Equal(t, 2, mockEmail.callCount())

	var pendingCount int
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM platform.notifications WHERE status='pending'`,
	).Scan(&pendingCount))
	assert.Equal(t, 3, pendingCount)
}

func TestProcessPending_DispatchesPerChannel(t *testing.T) {
	mockEmail := &mockSender{}
	mockInApp := &mockSender{}
	senders := platform.Senders{
		platform.ChannelEmail: mockEmail,
		platform.ChannelInApp: mockInApp,
	}
	svc, _, pool := newDispatchSvc(t, senders)
	ctx := context.Background()

	uid := createUser(t, pool)
	emailTmpl, err := svc.CreateTemplate(ctx, "ev", platform.ChannelEmail, nil, "email body")
	require.NoError(t, err)
	inAppTmpl, err := svc.CreateTemplate(ctx, "ev", platform.ChannelInApp, nil, "inapp body")
	require.NoError(t, err)

	insertPendingNotification(t, pool, uid, emailTmpl.ID, platform.ChannelEmail,
		map[string]any{}, nil)
	insertPendingNotification(t, pool, uid, inAppTmpl.ID, platform.ChannelInApp,
		map[string]any{}, nil)

	require.NoError(t, svc.ProcessPending(ctx, 10))

	assert.Equal(t, 1, mockEmail.callCount())
	assert.Equal(t, 1, mockInApp.callCount())
}
