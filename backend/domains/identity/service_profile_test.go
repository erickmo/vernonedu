package identity

import (
	"context"
	"testing"
	"time"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

func dateMust(s string) *time.Time {
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		panic(err)
	}
	return &t
}

func strPtr(s string) *string { return &s }

func fullProfileInput() ProfileInput {
	return ProfileInput{
		DateOfBirth: dateMust("2000-01-01"),
		Gender:      strPtr(GenderMale),
		IDType:      strPtr(IDTypeKTP),
		IDNumber:    strPtr("320123"),
		Address:     strPtr("Jl 1"),
		City:        strPtr("Jkt"),
		Province:    strPtr("DKI"),
		PostalCode:  strPtr("12000"),
	}
}

func TestUpdateProfile_SetsCompleteFlag(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	stu := repo.SeedStudent("a@example.com", SourceB2C)
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)

	_, err := svc.UpdateStudentProfile(ctx, stu.ID, fullProfileInput())
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if !repo.GetProfile(stu.ID).ProfileComplete {
		t.Fatal("expected profile_complete = true")
	}
	if !bus.Fired("student.profile_completed") {
		t.Fatal("expected student.profile_completed event")
	}
}

func TestUpdateProfile_PartialFields_NotComplete_NoEvent(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	stu := repo.SeedStudent("b@example.com", SourceB2C)
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)

	_, err := svc.UpdateStudentProfile(ctx, stu.ID, ProfileInput{
		Gender: strPtr(GenderMale),
		City:   strPtr("Jkt"),
	})
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if repo.GetProfile(stu.ID).ProfileComplete {
		t.Fatal("expected profile_complete = false")
	}
	if bus.Fired("student.profile_completed") {
		t.Fatal("did not expect student.profile_completed event for partial profile")
	}
}

func TestUpdateProfile_AlreadyComplete_NoSecondEvent(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	stu := repo.SeedStudent("c@example.com", SourceB2C)
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)

	if _, err := svc.UpdateStudentProfile(ctx, stu.ID, fullProfileInput()); err != nil {
		t.Fatalf("first update: %v", err)
	}
	if _, err := svc.UpdateStudentProfile(ctx, stu.ID, fullProfileInput()); err != nil {
		t.Fatalf("second update: %v", err)
	}

	bus.mu.Lock()
	count := bus.fired[events.StudentProfileCompleted]
	bus.mu.Unlock()
	if count != 1 {
		t.Fatalf("expected event fired exactly once, got %d", count)
	}
}
