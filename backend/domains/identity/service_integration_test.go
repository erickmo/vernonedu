//go:build integration

package identity_test

import (
	"context"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
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
	require.NoError(t, err, "connect test db")
	require.NoError(t, pool.Ping(context.Background()), "ping test db")
	return pool
}

func truncateIdentity(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			identity.facilitator_proposals,
			identity.facilitator_profiles,
			identity.team_members,
			identity.departments,
			identity.fee_tiers,
			identity.student_profiles,
			identity.students,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err, "truncate identity")
}

func newTestService(t *testing.T, pool *pgxpool.Pool) *identity.Service {
	t.Helper()
	log := zap.NewNop()
	repo := identity.NewRepository(pool)
	bus := events.NewBus(log)
	return identity.NewService(repo, bus, log)
}

func TestRegister_CreatesStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	user, err := svc.Register(ctx, identity.RegisterInput{
		Email:    "alice@test.local",
		Password: "secret123",
		Name:     "Alice",
		Phone:    "0811",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	})

	require.NoError(t, err)
	require.NotNil(t, user)
	require.Equal(t, "alice@test.local", user.Email)
	require.Equal(t, identity.RoleStudent, user.Role)
	require.True(t, user.IsActive)

	student, err := svc.GetStudentByUserID(ctx, user.ID)
	require.NoError(t, err)
	require.Equal(t, "Alice", student.Name)
	require.Equal(t, identity.SourceB2C, student.Source)
}

func TestRegister_DuplicateEmail(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	in := identity.RegisterInput{
		Email:    "dup@test.local",
		Password: "secret123",
		Name:     "Dup",
		Phone:    "0811",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	}
	_, err := svc.Register(ctx, in)
	require.NoError(t, err)

	_, err = svc.Register(ctx, in)
	require.Error(t, err)
	require.Contains(t, err.Error(), "email already registered")
}

func TestLogin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	created, err := svc.Register(ctx, identity.RegisterInput{
		Email:    "bob@test.local",
		Password: "secret123",
		Name:     "Bob",
		Phone:    "0811",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	})
	require.NoError(t, err)

	cases := []struct {
		name     string
		email    string
		password string
		wantErr  bool
	}{
		{"valid", "bob@test.local", "secret123", false},
		{"wrong password", "bob@test.local", "wrong", true},
		{"unknown email", "ghost@test.local", "secret123", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			u, err := svc.Login(ctx, tc.email, tc.password)
			if tc.wantErr {
				require.Error(t, err)
				return
			}
			require.NoError(t, err)
			require.Equal(t, created.ID, u.ID)
		})
	}
}

func TestLogin_DeactivatedUser(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	user, err := svc.Register(ctx, identity.RegisterInput{
		Email:    "off@test.local",
		Password: "secret123",
		Name:     "Off",
		Phone:    "0811",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	})
	require.NoError(t, err)

	require.NoError(t, svc.DeactivateUser(ctx, user.ID))

	_, err = svc.Login(ctx, "off@test.local", "secret123")
	require.Error(t, err)
	require.Contains(t, err.Error(), "deactivated")
}
