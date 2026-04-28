//go:build integration

package platform_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			platform.notifications,
			platform.notification_templates,
			platform.notification_preferences,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,$2,'hash','student')`,
		id, id.String()+"@test.com",
	)
	require.NoError(t, err)
	return id
}

// TestSend_DBErrorPropagates verifies that DB errors are returned, not swallowed.
func TestSend_DBErrorPropagates(t *testing.T) {
	pool := newTestPool(t)
	pool.Close() // intentionally closed to force a DB error

	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(platform.NewRepository(pool), bus, zap.NewNop())

	_, err := svc.Send(context.Background(), platform.SendInput{
		RecipientID: uuid.New(),
		TemplateKey: "some.key",
		Channel:     platform.ChannelInApp,
	})
	require.Error(t, err)
}
