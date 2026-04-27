package platform_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

const (
	calendarEventsTable    = "platform.calendar_events"
	calendarAttendeesTable = "platform.calendar_attendees"
)

func newCalendarSvc(t *testing.T) (*platform.Service, platform.Repository, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, usersTable, calendarEventsTable, calendarAttendeesTable)
	repo := platform.NewRepository(pool)
	svc := platform.NewService(repo, nil, zap.NewNop(), nil)
	return svc, repo, pool
}

func sampleManualInput(creator uuid.UUID, internal bool) platform.CreateManualEventInput {
	start := time.Now().Add(time.Hour).UTC().Truncate(time.Second)
	desc := "desc"
	loc := "Room A"
	return platform.CreateManualEventInput{
		Title:       "Standup",
		Description: &desc,
		StartAt:     start,
		EndAt:       start.Add(time.Hour),
		Location:    &loc,
		CreatorID:   creator,
		Internal:    internal,
	}
}

func TestCreateManualEvent_Internal_OK(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	uid := createUser(t, pool)

	evt, err := svc.CreateManualEvent(ctx, sampleManualInput(uid, true))
	require.NoError(t, err)
	require.NotNil(t, evt)
	assert.Equal(t, platform.CalendarTypeManualInternal, evt.EventType)
	require.NotNil(t, evt.CreatedBy)
	assert.Equal(t, uid, *evt.CreatedBy)

	var count int
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM platform.calendar_events WHERE id=$1`, evt.ID,
	).Scan(&count))
	assert.Equal(t, 1, count)
}

func TestAddAttendee_OK(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	attendee := createUser(t, pool)

	evt, err := svc.CreateManualEvent(ctx, sampleManualInput(creator, true))
	require.NoError(t, err)

	a, err := svc.AddAttendee(ctx, evt.ID, attendee, "attendee")
	require.NoError(t, err)
	require.NotNil(t, a)
	assert.Equal(t, platform.RsvpPending, a.RsvpStatus)

	var status string
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT rsvp_status FROM platform.calendar_attendees WHERE event_id=$1 AND user_id=$2`,
		evt.ID, attendee,
	).Scan(&status))
	assert.Equal(t, "pending", status)
}

func TestAddAttendee_Duplicate_ReturnsConflict(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	attendee := createUser(t, pool)

	evt, err := svc.CreateManualEvent(ctx, sampleManualInput(creator, true))
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, evt.ID, attendee, "attendee")
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, evt.ID, attendee, "attendee")
	require.Error(t, err)
	assert.True(t, errors.Is(err, apperrors.ErrConflict), "expected ErrConflict, got %v", err)
}

func TestListEventsByUser_AsAttendee_AND_AsCreator(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	user1 := createUser(t, pool)
	user2 := createUser(t, pool)

	eventA, err := svc.CreateManualEvent(ctx, sampleManualInput(user1, true))
	require.NoError(t, err)

	eventB, err := svc.CreateManualEvent(ctx, sampleManualInput(user2, true))
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, eventB.ID, user1, "attendee")
	require.NoError(t, err)

	got, err := svc.ListEventsByUser(ctx, user1)
	require.NoError(t, err)

	ids := map[uuid.UUID]bool{}
	for _, e := range got {
		ids[e.ID] = true
	}
	assert.True(t, ids[eventA.ID], "expected eventA in results")
	assert.True(t, ids[eventB.ID], "expected eventB in results")
}

func TestDeleteEvent_CascadesAttendees(t *testing.T) {
	svc, repo, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	a1 := createUser(t, pool)
	a2 := createUser(t, pool)

	evt, err := svc.CreateManualEvent(ctx, sampleManualInput(creator, true))
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, evt.ID, a1, "attendee")
	require.NoError(t, err)
	_, err = svc.AddAttendee(ctx, evt.ID, a2, "attendee")
	require.NoError(t, err)

	require.NoError(t, svc.DeleteEvent(ctx, evt.ID))

	// Event row gone.
	var count int
	require.NoError(t, pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM platform.calendar_events WHERE id=$1`, evt.ID,
	).Scan(&count))
	assert.Equal(t, 0, count)

	// Attendee rows cascade-deleted.
	atts, err := repo.ListCalendarAttendeesByEvent(ctx, evt.ID)
	require.NoError(t, err)
	assert.Empty(t, atts)
}

func TestUpdateEvent_AutoCreated_Rejected(t *testing.T) {
	_, repo, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)

	src := "enrollment"
	srcID := uuid.New()
	autoEvt := &platform.CalendarEvent{
		ID:           uuid.New(),
		Title:        "Auto Class",
		EventType:    platform.CalendarTypeClassSession,
		StartAt:      time.Now().UTC().Truncate(time.Second),
		EndAt:        time.Now().Add(time.Hour).UTC().Truncate(time.Second),
		SourceDomain: &src,
		SourceID:     &srcID,
		CreatedBy:    &creator,
	}
	require.NoError(t, repo.CreateCalendarEvent(ctx, autoEvt))

	svc := platform.NewService(repo, nil, zap.NewNop(), nil)
	modified := *autoEvt
	modified.Title = "Hacked Title"
	err := svc.UpdateEvent(ctx, &modified)
	require.Error(t, err)
	assert.True(t, errors.Is(err, apperrors.ErrAutoCreatedReadOnly), "expected ErrAutoCreatedReadOnly, got %v", err)

	// DB row unchanged.
	got, err := repo.GetCalendarEvent(ctx, autoEvt.ID)
	require.NoError(t, err)
	assert.Equal(t, "Auto Class", got.Title)
}

func TestUpdateEvent_Manual_OK(t *testing.T) {
	svc, repo, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)

	evt, err := svc.CreateManualEvent(ctx, sampleManualInput(creator, true))
	require.NoError(t, err)

	evt.Title = "Updated Standup"
	require.NoError(t, svc.UpdateEvent(ctx, evt))

	got, err := repo.GetCalendarEvent(ctx, evt.ID)
	require.NoError(t, err)
	assert.Equal(t, "Updated Standup", got.Title)
}
