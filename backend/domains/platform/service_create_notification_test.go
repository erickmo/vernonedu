package platform_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	notificationsTable = "platform.notifications"
	preferencesTable   = "platform.notification_preferences"
	usersTable         = "identity.users"
)

func newSendSvc(t *testing.T, hasDeviceToken func(context.Context, uuid.UUID) (bool, error)) (*platform.Service, platform.Repository, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	// CASCADE truncate users to clean up notifications/preferences/templates referencing them.
	testdb.Truncate(t, pool, usersTable, templatesTable, notificationsTable, preferencesTable)
	repo := platform.NewRepository(pool)
	svc := platform.NewService(repo, nil, zap.NewNop(), nil, nil, nil)
	if hasDeviceToken != nil {
		svc.HasDeviceTokenFn = hasDeviceToken
	}
	return svc, repo, pool
}

// createUser inserts a user and returns its ID. Required because notifications.recipient_id FK -> identity.users.
func createUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1, $2, 'x', 'admin')`,
		id, id.String()+"@test.local",
	)
	require.NoError(t, err)
	return id
}

func countNotifications(t *testing.T, pool *pgxpool.Pool) int {
	t.Helper()
	var n int
	err := pool.QueryRow(context.Background(), `SELECT COUNT(*) FROM platform.notifications`).Scan(&n)
	require.NoError(t, err)
	return n
}

func TestSend_PreferenceDisabled_SilentSkip(t *testing.T) {
	svc, repo, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "welcome", platform.ChannelEmail, nil, "hi")
	require.NoError(t, err)

	require.NoError(t, repo.UpsertPreference(ctx, &platform.NotificationPreference{
		ID:          uuid.New(),
		UserID:      uid,
		TemplateKey: "welcome",
		Channel:     platform.ChannelEmail,
		Enabled:     false,
	}))

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "welcome",
		Channel:     platform.ChannelEmail,
		Variables:   map[string]any{},
	})
	require.NoError(t, err)
	assert.Nil(t, got)
	assert.Equal(t, 0, countNotifications(t, pool))
}

func TestSend_NoPreference_DefaultEnabled(t *testing.T) {
	svc, _, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "welcome", platform.ChannelEmail, nil, "hi")
	require.NoError(t, err)

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "welcome",
		Channel:     platform.ChannelEmail,
		Variables:   map[string]any{},
	})
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.Equal(t, platform.NotifPending, got.Status)
	assert.Equal(t, 1, countNotifications(t, pool))
}

func TestSend_MissingVariable_ReturnsError_NoRecord(t *testing.T) {
	svc, _, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "greet", platform.ChannelEmail, nil, "Hi {{.name}}")
	require.NoError(t, err)

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "greet",
		Channel:     platform.ChannelEmail,
		Variables:   map[string]any{},
	})
	require.Error(t, err)
	assert.True(t, errors.Is(err, platform.ErrMissingVariable), "expected ErrMissingVariable, got %v", err)
	assert.Nil(t, got)
	assert.Equal(t, 0, countNotifications(t, pool))
}

func TestSend_InactiveTemplate_SilentSkip(t *testing.T) {
	svc, _, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	tmpl, err := svc.CreateTemplate(ctx, "bye", platform.ChannelEmail, nil, "bye")
	require.NoError(t, err)
	require.NoError(t, svc.DeactivateTemplate(ctx, tmpl.ID))

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "bye",
		Channel:     platform.ChannelEmail,
		Variables:   map[string]any{},
	})
	require.NoError(t, err)
	assert.Nil(t, got)
	assert.Equal(t, 0, countNotifications(t, pool))
}

func TestSend_MissingTemplate_SilentSkip(t *testing.T) {
	svc, _, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "nope",
		Channel:     platform.ChannelEmail,
		Variables:   map[string]any{},
	})
	require.NoError(t, err)
	assert.Nil(t, got)
	assert.Equal(t, 0, countNotifications(t, pool))
}

func TestSend_PushWithoutDeviceToken_SilentSkip(t *testing.T) {
	svc, _, pool := newSendSvc(t, func(_ context.Context, _ uuid.UUID) (bool, error) {
		return false, nil
	})
	ctx := context.Background()
	uid := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "ping", platform.ChannelPush, nil, "ping")
	require.NoError(t, err)

	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "ping",
		Channel:     platform.ChannelPush,
		Variables:   map[string]any{},
	})
	require.NoError(t, err)
	assert.Nil(t, got)
	assert.Equal(t, 0, countNotifications(t, pool))
}

func TestSend_Success_StoresVariablesJSON(t *testing.T) {
	svc, _, pool := newSendSvc(t, nil)
	ctx := context.Background()
	uid := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "welcome", platform.ChannelEmail, nil, "Hi {{.name}}")
	require.NoError(t, err)

	vars := map[string]any{"name": "Alice", "count": float64(3)}
	got, err := svc.Send(ctx, platform.SendInput{
		RecipientID: uid,
		TemplateKey: "welcome",
		Channel:     platform.ChannelEmail,
		Variables:   vars,
	})
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.Equal(t, platform.NotifPending, got.Status)

	var raw []byte
	err = pool.QueryRow(ctx, `SELECT variables FROM platform.notifications WHERE id=$1`, got.ID).Scan(&raw)
	require.NoError(t, err)

	var stored map[string]any
	require.NoError(t, json.Unmarshal(raw, &stored))
	assert.Equal(t, "Alice", stored["name"])
	assert.Equal(t, float64(3), stored["count"])
}
