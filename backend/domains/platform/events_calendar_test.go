package platform_test

import (
	"context"
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

// newCalendarListenerSvc builds a Service + Bus with both notification and
// calendar subscriptions wired and a cleaned platform.calendar_* schema.
func newCalendarListenerSvc(t *testing.T) (*platform.Service, events.Bus, platform.Repository, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, calendarAttendeesTable, calendarEventsTable, usersTable)
	repo := platform.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(repo, bus, zap.NewNop(), nil)
	platform.RegisterSubscriptions(bus, svc)
	return svc, bus, repo, pool
}

func countCalendarEvents(t *testing.T, pool *pgxpool.Pool) int {
	t.Helper()
	var n int
	err := pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM platform.calendar_events`).Scan(&n)
	require.NoError(t, err)
	return n
}

func TestCalendarListener_BatchCreated_CreatesClassSessionEvents(t *testing.T) {
	_, bus, _, pool := newCalendarListenerSvc(t)
	ctx := context.Background()

	batchID := uuid.New()
	class1 := uuid.New()
	class2 := uuid.New()
	start := time.Now().Add(2 * time.Hour).UTC().Truncate(time.Second)

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.BatchCreated,
		Payload: events.BatchCreatedPayload{
			BatchID: batchID,
			Classes: []events.ClassPayload{
				{ClassID: class1, Title: "Class 1", StartAt: start, EndAt: start.Add(time.Hour), Location: "R1"},
				{ClassID: class2, Title: "Class 2", StartAt: start.Add(24 * time.Hour), EndAt: start.Add(25 * time.Hour)},
			},
		},
	}))

	assert.Equal(t, 2, countCalendarEvents(t, pool))

	var typ, src string
	var srcID, gotBatch uuid.UUID
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT event_type::text, source_domain, source_id, batch_id
		   FROM platform.calendar_events WHERE source_id=$1`, class1,
	).Scan(&typ, &src, &srcID, &gotBatch))
	assert.Equal(t, "class_session", typ)
	assert.Equal(t, "course", src)
	assert.Equal(t, class1, srcID)
	assert.Equal(t, batchID, gotBatch)
}

func TestCalendarListener_ClassRescheduled_UpdatesEventTimes(t *testing.T) {
	_, bus, repo, pool := newCalendarListenerSvc(t)
	ctx := context.Background()

	classID := uuid.New()
	src := "course"
	originalStart := time.Now().Add(time.Hour).UTC().Truncate(time.Second)
	evt := &platform.CalendarEvent{
		ID:           uuid.New(),
		Title:        "Class to reschedule",
		EventType:    platform.CalendarTypeClassSession,
		StartAt:      originalStart,
		EndAt:        originalStart.Add(time.Hour),
		SourceDomain: &src,
		SourceID:     &classID,
	}
	require.NoError(t, repo.CreateCalendarEvent(ctx, evt))

	newStart := originalStart.Add(48 * time.Hour)
	newEnd := newStart.Add(90 * time.Minute)
	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.ClassRescheduled,
		Payload: events.ClassRescheduledPayload{
			ClassID: classID,
			StartAt: newStart,
			EndAt:   newEnd,
		},
	}))

	got, err := repo.GetCalendarEvent(ctx, evt.ID)
	require.NoError(t, err)
	assert.True(t, got.StartAt.Equal(newStart), "start_at: want %v got %v", newStart, got.StartAt)
	assert.True(t, got.EndAt.Equal(newEnd), "end_at: want %v got %v", newEnd, got.EndAt)
	_ = pool // keep linter happy
}

func TestCalendarListener_ClassCancelled_DeletesEvent(t *testing.T) {
	_, bus, repo, pool := newCalendarListenerSvc(t)
	ctx := context.Background()

	classID := uuid.New()
	src := "course"
	start := time.Now().Add(time.Hour).UTC().Truncate(time.Second)
	evt := &platform.CalendarEvent{
		ID:           uuid.New(),
		Title:        "Class to cancel",
		EventType:    platform.CalendarTypeClassSession,
		StartAt:      start,
		EndAt:        start.Add(time.Hour),
		SourceDomain: &src,
		SourceID:     &classID,
	}
	require.NoError(t, repo.CreateCalendarEvent(ctx, evt))
	require.Equal(t, 1, countCalendarEvents(t, pool))

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type:    events.ClassCancelled,
		Payload: events.ClassCancelledPayload{ClassID: classID},
	}))

	assert.Equal(t, 0, countCalendarEvents(t, pool))
}

func TestCalendarListener_FacilitatorApproved_AddsAttendeeToAllBatchClasses(t *testing.T) {
	_, bus, repo, pool := newCalendarListenerSvc(t)
	ctx := context.Background()

	facilitator := createUser(t, pool)
	batchID := uuid.New()
	src := "course"
	start := time.Now().Add(time.Hour).UTC().Truncate(time.Second)

	class1 := uuid.New()
	class2 := uuid.New()
	for _, cid := range []uuid.UUID{class1, class2} {
		c := cid
		require.NoError(t, repo.CreateCalendarEvent(ctx, &platform.CalendarEvent{
			ID:           uuid.New(),
			Title:        "Batch Class",
			EventType:    platform.CalendarTypeClassSession,
			StartAt:      start,
			EndAt:        start.Add(time.Hour),
			SourceDomain: &src,
			SourceID:     &c,
			BatchID:      &batchID,
		}))
	}

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.FacilitatorApproved,
		Payload: events.FacilitatorEventPayload{
			FacilitatorID: facilitator,
			CourseTitle:   "Calc",
			BatchID:       batchID,
		},
	}))

	var n int
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM platform.calendar_attendees a
		   JOIN platform.calendar_events e ON e.id = a.event_id
		  WHERE e.batch_id = $1 AND a.user_id = $2`,
		batchID, facilitator,
	).Scan(&n))
	assert.Equal(t, 2, n)
}
