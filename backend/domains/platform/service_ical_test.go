package platform_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
)

func TestExportICalForUser_IncludesAllAttendedEvents(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	user1 := createUser(t, pool)
	user2 := createUser(t, pool)

	inA := sampleManualInput(user1, true)
	inA.Title = "Event Alpha"
	eventA, err := svc.CreateManualEvent(ctx, inA)
	require.NoError(t, err)

	inB := sampleManualInput(user2, true)
	inB.Title = "Event Beta"
	eventB, err := svc.CreateManualEvent(ctx, inB)
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, eventB.ID, user1, "attendee")
	require.NoError(t, err)

	out, err := svc.ExportICalForUser(ctx, user1)
	require.NoError(t, err)

	s := string(out)
	assert.Contains(t, s, "BEGIN:VCALENDAR")
	assert.Contains(t, s, "END:VCALENDAR")
	assert.Equal(t, 2, strings.Count(s, "BEGIN:VEVENT"), "expected 2 VEVENT blocks; got: %s", s)
	assert.Contains(t, s, "Event Alpha")
	assert.Contains(t, s, "Event Beta")
	// Sanity: event UIDs surface
	assert.Contains(t, s, eventA.ID.String())
	assert.Contains(t, s, eventB.ID.String())
}

func TestExportSingleEvent_ReturnsOneVEVENT(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)

	in := sampleManualInput(creator, true)
	in.Title = "Solo Event"
	evt, err := svc.CreateManualEvent(ctx, in)
	require.NoError(t, err)

	out, err := svc.ExportSingleEvent(ctx, evt.ID)
	require.NoError(t, err)

	s := strings.TrimSpace(string(out))
	assert.Contains(t, s, "BEGIN:VCALENDAR")
	assert.True(t, strings.HasSuffix(s, "END:VCALENDAR"), "expected output to end with END:VCALENDAR; got: %q", s)
	assert.Equal(t, 1, strings.Count(s, "BEGIN:VEVENT"))
	assert.Equal(t, 1, strings.Count(s, "END:VEVENT"))
	assert.Contains(t, s, "Solo Event")
}

func TestExportICalForUser_RrulePassesThrough(t *testing.T) {
	svc, _, pool := newCalendarSvc(t)
	ctx := context.Background()
	creator := createUser(t, pool)
	user := createUser(t, pool)

	rrule := "FREQ=WEEKLY;COUNT=10"
	start := time.Now().Add(time.Hour).UTC().Truncate(time.Second)
	in := platform.CreateManualEventInput{
		Title:     "Recurring",
		StartAt:   start,
		EndAt:     start.Add(time.Hour),
		Rrule:     &rrule,
		CreatorID: creator,
		Internal:  true,
	}
	evt, err := svc.CreateManualEvent(ctx, in)
	require.NoError(t, err)

	_, err = svc.AddAttendee(ctx, evt.ID, user, "attendee")
	require.NoError(t, err)

	out, err := svc.ExportICalForUser(ctx, user)
	require.NoError(t, err)

	s := string(out)
	assert.Contains(t, s, "RRULE:FREQ=WEEKLY;COUNT=10", "RRULE should pass through; got: %s", s)
	assert.NotEqual(t, uuid.Nil, evt.ID)
}
