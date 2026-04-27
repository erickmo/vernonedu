//go:build integration

package calendar_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/calendar"
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
			calendar.attendees,
			calendar.syncs,
			calendar.events,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,$2,'hash','admin')`,
		id, id.String()+"@test.com",
	)
	require.NoError(t, err)
	return id
}

func newSvc(t *testing.T, pool *pgxpool.Pool) *calendar.Service {
	t.Helper()
	log := zap.NewNop()
	bus := events.NewBus(log)
	repo := calendar.NewRepository(pool)
	return calendar.NewService(repo, bus, log)
}

func TestCreateAndGetEvent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	userID := seedUser(t, pool)
	svc := newSvc(t, pool)

	now := time.Now().UTC().Truncate(time.Second)
	e := &calendar.CalendarEvent{
		Title:     "Staff Meeting",
		EventType: calendar.EventTypeStaffMeeting,
		StartAt:   now,
		EndAt:     now.Add(1 * time.Hour),
		CreatedBy: userID,
	}

	err := svc.CreateEvent(context.Background(), e)
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, e.ID)

	got, err := svc.GetEvent(context.Background(), e.ID)
	require.NoError(t, err)
	require.Equal(t, e.Title, got.Title)
	require.Equal(t, calendar.EventTypeStaffMeeting, got.EventType)
}

func TestUpdateAndDeleteManualEvent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	userID := seedUser(t, pool)
	svc := newSvc(t, pool)

	now := time.Now().UTC().Truncate(time.Second)
	e := &calendar.CalendarEvent{
		Title:     "Admin Deadline",
		EventType: calendar.EventTypeAdminDeadline,
		StartAt:   now,
		EndAt:     now.Add(30 * time.Minute),
		CreatedBy: userID,
	}
	require.NoError(t, svc.CreateEvent(context.Background(), e))

	e.Title = "Updated Deadline"
	require.NoError(t, svc.UpdateEvent(context.Background(), e))

	got, err := svc.GetEvent(context.Background(), e.ID)
	require.NoError(t, err)
	require.Equal(t, "Updated Deadline", got.Title)

	require.NoError(t, svc.DeleteEvent(context.Background(), e.ID))
	_, err = svc.GetEvent(context.Background(), e.ID)
	require.Error(t, err)
}

func TestAddAttendeeAndRSVP(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	userID := seedUser(t, pool)
	attendeeID := seedUser(t, pool)
	svc := newSvc(t, pool)

	now := time.Now().UTC().Truncate(time.Second)
	e := &calendar.CalendarEvent{
		Title:     "Team Meeting",
		EventType: calendar.EventTypeStaffMeeting,
		StartAt:   now,
		EndAt:     now.Add(1 * time.Hour),
		CreatedBy: userID,
	}
	require.NoError(t, svc.CreateEvent(context.Background(), e))

	require.NoError(t, svc.AddAttendee(context.Background(), e.ID, attendeeID, calendar.RoleAttendee))

	attendees, err := svc.GetAttendees(context.Background(), e.ID)
	require.NoError(t, err)
	require.Len(t, attendees, 1)
	require.Equal(t, calendar.RSVPPending, attendees[0].RSVPStatus)

	require.NoError(t, svc.UpdateRSVP(context.Background(), e.ID, attendeeID, calendar.RSVPAccepted))

	attendees, err = svc.GetAttendees(context.Background(), e.ID)
	require.NoError(t, err)
	require.Equal(t, calendar.RSVPAccepted, attendees[0].RSVPStatus)
}

func TestExportICalForUser(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	userID := seedUser(t, pool)
	svc := newSvc(t, pool)

	now := time.Now().UTC().Truncate(time.Second)
	for i := 0; i < 2; i++ {
		e := &calendar.CalendarEvent{
			Title:     "Event",
			EventType: calendar.EventTypeStaffMeeting,
			StartAt:   now.Add(time.Duration(i) * time.Hour),
			EndAt:     now.Add(time.Duration(i+1) * time.Hour),
			CreatedBy: userID,
		}
		require.NoError(t, svc.CreateEvent(context.Background(), e))
	}

	ical, err := svc.ExportICalForUser(context.Background(), userID)
	require.NoError(t, err)
	require.Contains(t, ical, "BEGIN:VCALENDAR")
	require.Contains(t, ical, "BEGIN:VEVENT")
	require.Contains(t, ical, "END:VCALENDAR")
}

func TestUpsertSync(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	userID := seedUser(t, pool)
	svc := newSvc(t, pool)

	sync := &calendar.CalendarSync{
		UserID:       userID,
		Provider:     calendar.ProviderGoogleCalendar,
		AccessToken:  "access-token",
		RefreshToken: "refresh-token",
	}
	require.NoError(t, svc.UpsertSync(context.Background(), sync))

	got, err := svc.GetSync(context.Background(), userID)
	require.NoError(t, err)
	require.Equal(t, calendar.ProviderGoogleCalendar, got.Provider)

	// Upsert again with new token
	sync.AccessToken = "new-token"
	require.NoError(t, svc.UpsertSync(context.Background(), sync))
	got2, err := svc.GetSync(context.Background(), userID)
	require.NoError(t, err)
	require.Equal(t, "new-token", got2.AccessToken)
}
