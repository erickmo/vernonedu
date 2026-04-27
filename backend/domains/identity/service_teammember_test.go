package identity

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

func newTeamMemberSvc(t *testing.T) (*Service, *fakeRepo, *fakeBus) {
	t.Helper()
	repo := newFakeRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)
	return svc, repo, bus
}

func TestCreateTeamMember_FiresEvent(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newTeamMemberSvc(t)

	deptID := uuid.New()
	tm, err := svc.CreateTeamMember(ctx, CreateTeamMemberInput{
		UserID:           uuid.New(),
		FullName:         "Bob Member",
		Phone:            "+62800",
		Role:             RoleCourseCreator,
		DepartmentID:     &deptID,
		EmploymentStatus: StatusActive,
	})
	if err != nil {
		t.Fatalf("CreateTeamMember: %v", err)
	}
	if tm.ID == uuid.Nil {
		t.Fatal("expected team member ID")
	}
	if got := repo.teamMembers[tm.ID]; got == nil {
		t.Fatal("expected team member persisted in repo")
	}
	if !bus.Fired("team_member.created") {
		t.Fatal("expected team_member.created event")
	}

	payload, ok := bus.LastPayload(events.TeamMemberCreated).(events.TeamMemberCreatedPayload)
	if !ok {
		t.Fatalf("unexpected payload type: %T", bus.LastPayload(events.TeamMemberCreated))
	}
	if payload.TeamMemberID != tm.ID {
		t.Fatalf("payload.TeamMemberID=%v want %v", payload.TeamMemberID, tm.ID)
	}
	if payload.Role != string(RoleCourseCreator) {
		t.Fatalf("payload.Role=%q want %q", payload.Role, RoleCourseCreator)
	}
	if payload.Status != string(StatusActive) {
		t.Fatalf("payload.Status=%q want %q", payload.Status, StatusActive)
	}
}

func TestUpdateTeamMemberStatus_FiresEvent(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newTeamMemberSvc(t)

	tm := repo.SeedTeamMember(RoleCourseCreator, StatusActive)

	if err := svc.UpdateTeamMemberStatus(ctx, tm.ID, StatusOnLeave); err != nil {
		t.Fatalf("UpdateTeamMemberStatus: %v", err)
	}

	if repo.teamMembers[tm.ID].EmploymentStatus != StatusOnLeave {
		t.Fatalf("status not persisted: got %q", repo.teamMembers[tm.ID].EmploymentStatus)
	}
	if !bus.Fired("team_member.status_changed") {
		t.Fatal("expected team_member.status_changed event")
	}

	payload, ok := bus.LastPayload(events.TeamMemberStatusChanged).(events.TeamMemberStatusChangedPayload)
	if !ok {
		t.Fatalf("unexpected payload type: %T", bus.LastPayload(events.TeamMemberStatusChanged))
	}
	if payload.OldStatus != string(StatusActive) {
		t.Fatalf("OldStatus=%q want %q", payload.OldStatus, StatusActive)
	}
	if payload.NewStatus != string(StatusOnLeave) {
		t.Fatalf("NewStatus=%q want %q", payload.NewStatus, StatusOnLeave)
	}
	if payload.TeamMemberID != tm.ID {
		t.Fatalf("TeamMemberID=%v want %v", payload.TeamMemberID, tm.ID)
	}
}

func TestUpdateTeamMemberStatus_SameStatus_NoEvent(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newTeamMemberSvc(t)

	tm := repo.SeedTeamMember(RoleCourseCreator, StatusActive)

	if err := svc.UpdateTeamMemberStatus(ctx, tm.ID, StatusActive); err != nil {
		t.Fatalf("UpdateTeamMemberStatus same: %v", err)
	}

	if bus.Fired("team_member.status_changed") {
		t.Fatal("expected no status_changed event for same-status update")
	}
}

func TestDeactivateTeamMember_SetsStatus(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newTeamMemberSvc(t)

	tm := repo.SeedTeamMember(RoleCourseCreator, StatusActive)

	if err := svc.DeactivateTeamMember(ctx, tm.ID); err != nil {
		t.Fatalf("DeactivateTeamMember: %v", err)
	}

	if got := repo.teamMembers[tm.ID].EmploymentStatus; got != StatusInactive {
		t.Fatalf("status=%q want %q", got, StatusInactive)
	}
	if !bus.Fired("team_member.status_changed") {
		t.Fatal("expected team_member.status_changed event")
	}

	payload, ok := bus.LastPayload(events.TeamMemberStatusChanged).(events.TeamMemberStatusChangedPayload)
	if !ok {
		t.Fatalf("unexpected payload type: %T", bus.LastPayload(events.TeamMemberStatusChanged))
	}
	if payload.NewStatus != string(StatusInactive) {
		t.Fatalf("NewStatus=%q want %q", payload.NewStatus, StatusInactive)
	}
	if payload.OldStatus != string(StatusActive) {
		t.Fatalf("OldStatus=%q want %q", payload.OldStatus, StatusActive)
	}
}
