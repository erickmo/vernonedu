package platform_test

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

// recordingBus captures Publish calls for assertion.
type recordingBus struct {
	mu        sync.Mutex
	published []events.Event
}

func (r *recordingBus) Publish(_ context.Context, e events.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.published = append(r.published, e)
	return nil
}

func (r *recordingBus) Subscribe(events.EventType, events.HandlerFunc) {}

func (r *recordingBus) snapshot() []events.Event {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]events.Event, len(r.published))
	copy(out, r.published)
	return out
}

func newReminderSvc(t *testing.T) (*platform.Service, platform.Repository, *recordingBus, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, usersTable, calendarEventsTable, calendarAttendeesTable)
	repo := platform.NewRepository(pool)
	bus := &recordingBus{}
	svc := platform.NewService(repo, bus, zap.NewNop(), nil, nil, nil)
	return svc, repo, bus, pool
}

// insertClassEvent creates a class_session calendar event with the given offset
// from now() for start_at (and start+1h for end_at).
func insertClassEvent(t *testing.T, repo platform.Repository, creator uuid.UUID, startOffset time.Duration, title string) *platform.CalendarEvent {
	t.Helper()
	src := "course"
	srcID := uuid.New()
	start := time.Now().Add(startOffset).UTC().Truncate(time.Second)
	evt := &platform.CalendarEvent{
		ID:           uuid.New(),
		Title:        title,
		EventType:    platform.CalendarTypeClassSession,
		StartAt:      start,
		EndAt:        start.Add(time.Hour),
		SourceDomain: &src,
		SourceID:     &srcID,
		CreatedBy:    &creator,
	}
	require.NoError(t, repo.CreateCalendarEvent(context.Background(), evt))
	return evt
}

func TestScanReminders_FiresOncePerEvent(t *testing.T) {
	svc, repo, bus, pool := newReminderSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	facilitator := createUser(t, pool)
	student := createUser(t, pool)

	// 62 minutes from now → inside [60, 65] window.
	evt := insertClassEvent(t, repo, creator, 62*time.Minute, "Math 101")

	_, err := svc.AddAttendee(ctx, evt.ID, facilitator, "facilitator")
	require.NoError(t, err)
	_, err = svc.AddAttendee(ctx, evt.ID, student, "attendee")
	require.NoError(t, err)

	require.NoError(t, svc.ScanClassReminders(ctx))

	pubs := bus.snapshot()
	require.Len(t, pubs, 1)
	assert.Equal(t, events.ClassReminder, pubs[0].Type)
	payload, ok := pubs[0].Payload.(events.ClassReminderPayload)
	require.True(t, ok, "payload should be ClassReminderPayload")
	assert.Equal(t, "Math 101", payload.ClassTitle)
	assert.Equal(t, facilitator, payload.FacilitatorID)
	assert.ElementsMatch(t, []uuid.UUID{facilitator, student}, payload.AttendeeIDs)

	// reminder_fired_at populated in DB.
	got, err := repo.GetCalendarEvent(ctx, evt.ID)
	require.NoError(t, err)
	require.NotNil(t, got.ReminderFiredAt, "reminder_fired_at should be set")
}

func TestScanReminders_SecondCall_DoesNotRefire(t *testing.T) {
	svc, repo, bus, pool := newReminderSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	facilitator := createUser(t, pool)

	evt := insertClassEvent(t, repo, creator, 62*time.Minute, "Physics 201")
	_, err := svc.AddAttendee(ctx, evt.ID, facilitator, "facilitator")
	require.NoError(t, err)

	require.NoError(t, svc.ScanClassReminders(ctx))
	require.NoError(t, svc.ScanClassReminders(ctx))

	assert.Len(t, bus.snapshot(), 1, "second scan must not republish")
}

func TestScanReminders_OutsideWindow_Skipped(t *testing.T) {
	svc, repo, bus, pool := newReminderSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)

	// Too soon (30 min away) and too far (90 min away) — both excluded.
	tooSoon := insertClassEvent(t, repo, creator, 30*time.Minute, "Soon")
	tooLate := insertClassEvent(t, repo, creator, 90*time.Minute, "Late")

	require.NoError(t, svc.ScanClassReminders(ctx))
	assert.Empty(t, bus.snapshot())

	soon, err := repo.GetCalendarEvent(ctx, tooSoon.ID)
	require.NoError(t, err)
	assert.Nil(t, soon.ReminderFiredAt)

	late, err := repo.GetCalendarEvent(ctx, tooLate.ID)
	require.NoError(t, err)
	assert.Nil(t, late.ReminderFiredAt)
}

func TestScanReminders_NotClassSession_Skipped(t *testing.T) {
	svc, repo, bus, pool := newReminderSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)

	// manual_internal event in the time window — must NOT be picked up.
	start := time.Now().Add(62 * time.Minute).UTC().Truncate(time.Second)
	evt := &platform.CalendarEvent{
		ID:        uuid.New(),
		Title:     "Internal Standup",
		EventType: platform.CalendarTypeManualInternal,
		StartAt:   start,
		EndAt:     start.Add(time.Hour),
		CreatedBy: &creator,
	}
	require.NoError(t, repo.CreateCalendarEvent(ctx, evt))

	require.NoError(t, svc.ScanClassReminders(ctx))
	assert.Empty(t, bus.snapshot())

	got, err := repo.GetCalendarEvent(ctx, evt.ID)
	require.NoError(t, err)
	assert.Nil(t, got.ReminderFiredAt)
}
