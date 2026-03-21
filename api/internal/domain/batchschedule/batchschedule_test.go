package batchschedule_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/batchschedule"
)

func TestNewBatchSchedule_Success(t *testing.T) {
	batchID := uuid.New()
	at := time.Now().Add(24 * time.Hour)
	s, err := batchschedule.NewBatchSchedule(batchID, nil, nil, at, 90, "notes")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if s.CourseBatchID != batchID {
		t.Error("batch ID mismatch")
	}
	if s.DurationMinutes != 90 {
		t.Errorf("expected 90 minutes, got %d", s.DurationMinutes)
	}
	if s.Status != batchschedule.StatusScheduled {
		t.Errorf("expected status %q, got %q", batchschedule.StatusScheduled, s.Status)
	}
}

func TestNewBatchSchedule_InvalidDuration(t *testing.T) {
	_, err := batchschedule.NewBatchSchedule(uuid.New(), nil, nil, time.Now().Add(time.Hour), 0, "")
	if err == nil || err != batchschedule.ErrInvalidDuration {
		t.Errorf("expected ErrInvalidDuration, got %v", err)
	}
}

func TestBatchSchedule_EndTime(t *testing.T) {
	at := time.Date(2026, 1, 1, 9, 0, 0, 0, time.UTC)
	s := &batchschedule.BatchSchedule{ScheduledAt: at, DurationMinutes: 120}
	expected := time.Date(2026, 1, 1, 11, 0, 0, 0, time.UTC)
	if !s.EndTime().Equal(expected) {
		t.Errorf("expected end time %v, got %v", expected, s.EndTime())
	}
}

func TestBatchSchedule_ConflictsWith_SameRoom(t *testing.T) {
	roomID := uuid.New()
	batchID := uuid.New()
	at := time.Date(2026, 1, 1, 9, 0, 0, 0, time.UTC)

	s1 := &batchschedule.BatchSchedule{RoomID: &roomID, CourseBatchID: batchID, ScheduledAt: at, DurationMinutes: 120}
	// s2 overlaps: starts at 10:00, s1 ends at 11:00
	at2 := at.Add(time.Hour)
	s2 := &batchschedule.BatchSchedule{RoomID: &roomID, CourseBatchID: batchID, ScheduledAt: at2, DurationMinutes: 120}

	if !s1.ConflictsWith(s2) {
		t.Error("expected conflict, got none")
	}
}

func TestBatchSchedule_ConflictsWith_NoConflict(t *testing.T) {
	roomID := uuid.New()
	batchID := uuid.New()
	at := time.Date(2026, 1, 1, 9, 0, 0, 0, time.UTC)

	s1 := &batchschedule.BatchSchedule{RoomID: &roomID, CourseBatchID: batchID, ScheduledAt: at, DurationMinutes: 60}
	// s2 starts after s1 ends (at 10:01)
	at2 := at.Add(time.Hour + time.Minute)
	s2 := &batchschedule.BatchSchedule{RoomID: &roomID, CourseBatchID: batchID, ScheduledAt: at2, DurationMinutes: 60}

	if s1.ConflictsWith(s2) {
		t.Error("expected no conflict")
	}
}

func TestBatchSchedule_ConflictsWith_DifferentRoom(t *testing.T) {
	roomID1 := uuid.New()
	roomID2 := uuid.New()
	batchID := uuid.New()
	at := time.Now()

	s1 := &batchschedule.BatchSchedule{RoomID: &roomID1, CourseBatchID: batchID, ScheduledAt: at, DurationMinutes: 120}
	s2 := &batchschedule.BatchSchedule{RoomID: &roomID2, CourseBatchID: batchID, ScheduledAt: at, DurationMinutes: 120}

	if s1.ConflictsWith(s2) {
		t.Error("expected no conflict for different rooms")
	}
}
