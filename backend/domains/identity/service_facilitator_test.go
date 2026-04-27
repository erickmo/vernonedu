package identity

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

func newFacilitatorSvc(t *testing.T) (*Service, *fakeRepo, *fakeBus) {
	t.Helper()
	repo := newFakeRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)
	return svc, repo, bus
}

// seedProposer creates a course_creator team member.
func seedProposer(repo *fakeRepo) *TeamMember {
	return repo.SeedTeamMember(RoleCourseCreator, StatusActive)
}

// seedFacilitator creates a team member + a facilitator profile attached.
func seedFacilitator(repo *fakeRepo) *TeamMember {
	tm := repo.SeedTeamMember(RoleAdmin, StatusActive)
	tm.IsFacilitator = true
	repo.SeedFacilitatorProfile(tm.ID, "Mathematics")
	return tm
}

func proposeInput(proposerID, facilitatorID uuid.UUID) ProposeFacilitatorInput {
	return ProposeFacilitatorInput{
		ProposedByTeamMemberID:  proposerID,
		CourseID:                uuid.New(),
		FacilitatorTeamMemberID: facilitatorID,
		FeeTierID:               uuid.New(),
		FeeBasis:                FeePerClass,
	}
}

func TestProposeFacilitator_CreatesPendingAndFiresEvent(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newFacilitatorSvc(t)

	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)

	p, err := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))
	if err != nil {
		t.Fatalf("ProposeFacilitator: %v", err)
	}
	if p.FinalStatus != ProposalPending || p.DeptLeaderStatus != ProposalPending || p.AcademicLeaderStatus != ProposalPending {
		t.Fatalf("expected all-pending statuses, got %+v", p)
	}
	if !bus.Fired(string(events.FacilitatorProposed)) {
		t.Fatal("expected facilitator.proposed event")
	}
	payload, ok := bus.LastPayload(events.FacilitatorProposed).(events.FacilitatorProposedPayload)
	if !ok {
		t.Fatalf("expected events.FacilitatorProposedPayload, got %T", bus.LastPayload(events.FacilitatorProposed))
	}
	if payload.ProposalID != p.ID || payload.FacilitatorID != fac.ID || payload.ProposedBy != proposer.ID {
		t.Fatalf("unexpected payload: %+v", payload)
	}
}

func TestApproveByDeptLeader_OnPending_AdvancesStage(t *testing.T) {
	ctx := context.Background()
	svc, repo, _ := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, err := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))
	if err != nil {
		t.Fatalf("propose: %v", err)
	}

	deptLeader := uuid.New()
	if err := svc.ApproveProposalDeptLeader(ctx, p.ID, deptLeader, nil); err != nil {
		t.Fatalf("approve dept: %v", err)
	}
	got := repo.proposals[p.ID]
	if got.DeptLeaderStatus != ProposalApproved {
		t.Fatalf("expected dept_leader_status=approved, got %s", got.DeptLeaderStatus)
	}
	if got.DeptLeaderReviewedAt == nil {
		t.Fatal("expected dept_leader_reviewed_at set")
	}
	if got.AcademicLeaderStatus != ProposalPending {
		t.Fatalf("expected academic_leader_status=pending, got %s", got.AcademicLeaderStatus)
	}
	if got.FinalStatus != ProposalPending {
		t.Fatalf("expected final_status=pending, got %s", got.FinalStatus)
	}
}

func TestApproveByDeptLeader_Twice_Errors(t *testing.T) {
	ctx := context.Background()
	svc, repo, _ := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, _ := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))

	leader := uuid.New()
	if err := svc.ApproveProposalDeptLeader(ctx, p.ID, leader, nil); err != nil {
		t.Fatalf("first approve: %v", err)
	}
	err := svc.ApproveProposalDeptLeader(ctx, p.ID, leader, nil)
	if err == nil {
		t.Fatal("expected error on second approval")
	}
	if !strings.Contains(err.Error(), "already reviewed") {
		t.Fatalf("expected 'already reviewed' error, got: %v", err)
	}
}

func TestApproveByAcademicLeader_BeforeDeptLeader_Errors(t *testing.T) {
	ctx := context.Background()
	svc, repo, _ := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, _ := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))

	err := svc.ApproveProposalAcademicLeader(ctx, p.ID, uuid.New(), nil)
	if err == nil {
		t.Fatal("expected error: dept leader has not approved")
	}
	if !strings.Contains(err.Error(), "dept leader") {
		t.Fatalf("expected dept-leader error, got: %v", err)
	}
}

func TestApproveByAcademicLeader_AfterDeptLeader_Approves(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, _ := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))

	if err := svc.ApproveProposalDeptLeader(ctx, p.ID, uuid.New(), nil); err != nil {
		t.Fatalf("dept approve: %v", err)
	}
	academic := uuid.New()
	if err := svc.ApproveProposalAcademicLeader(ctx, p.ID, academic, nil); err != nil {
		t.Fatalf("academic approve: %v", err)
	}
	got := repo.proposals[p.ID]
	if got.AcademicLeaderStatus != ProposalApproved {
		t.Fatalf("expected academic approved, got %s", got.AcademicLeaderStatus)
	}
	if got.FinalStatus != ProposalApproved {
		t.Fatalf("expected final approved, got %s", got.FinalStatus)
	}
	if !bus.Fired(string(events.FacilitatorApproved)) {
		t.Fatal("expected facilitator.approved event")
	}
	payload, ok := bus.LastPayload(events.FacilitatorApproved).(events.FacilitatorApprovedPayload)
	if !ok {
		t.Fatalf("expected FacilitatorApprovedPayload, got %T", bus.LastPayload(events.FacilitatorApproved))
	}
	if payload.ApprovedBy != academic {
		t.Fatalf("expected approved_by=%s, got %s", academic, payload.ApprovedBy)
	}
}

func TestRejectByDeptLeader_FinalRejected(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, _ := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))

	dept := uuid.New()
	note := "not qualified"
	if err := svc.RejectProposalDeptLeader(ctx, p.ID, dept, &note); err != nil {
		t.Fatalf("reject dept: %v", err)
	}
	got := repo.proposals[p.ID]
	if got.DeptLeaderStatus != ProposalRejected {
		t.Fatalf("expected dept rejected, got %s", got.DeptLeaderStatus)
	}
	if got.FinalStatus != ProposalRejected {
		t.Fatalf("expected final rejected, got %s", got.FinalStatus)
	}
	if !bus.Fired(string(events.FacilitatorRejected)) {
		t.Fatal("expected facilitator.rejected event")
	}
	payload, ok := bus.LastPayload(events.FacilitatorRejected).(events.FacilitatorRejectedPayload)
	if !ok {
		t.Fatalf("unexpected payload type: %T", bus.LastPayload(events.FacilitatorRejected))
	}
	if payload.Stage != StageDeptLeader {
		t.Fatalf("expected stage=dept_leader, got %s", payload.Stage)
	}
}

func TestRejectByAcademicLeader_AfterDeptApproval_FinalRejected(t *testing.T) {
	ctx := context.Background()
	svc, repo, bus := newFacilitatorSvc(t)
	proposer := seedProposer(repo)
	fac := seedFacilitator(repo)
	p, _ := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))

	if err := svc.ApproveProposalDeptLeader(ctx, p.ID, uuid.New(), nil); err != nil {
		t.Fatalf("dept approve: %v", err)
	}
	academic := uuid.New()
	if err := svc.RejectProposalAcademicLeader(ctx, p.ID, academic, nil); err != nil {
		t.Fatalf("reject academic: %v", err)
	}
	got := repo.proposals[p.ID]
	if got.FinalStatus != ProposalRejected {
		t.Fatalf("expected final rejected, got %s", got.FinalStatus)
	}
	payload, ok := bus.LastPayload(events.FacilitatorRejected).(events.FacilitatorRejectedPayload)
	if !ok {
		t.Fatalf("unexpected payload type")
	}
	if payload.Stage != StageAcademicLeader {
		t.Fatalf("expected stage=academic_leader, got %s", payload.Stage)
	}
}

func TestProposeFacilitator_NonCourseCreator_Errors(t *testing.T) {
	ctx := context.Background()
	svc, repo, _ := newFacilitatorSvc(t)

	// Proposer is a regular admin team member, not a course_creator.
	proposer := repo.SeedTeamMember(RoleAdmin, StatusActive)
	fac := seedFacilitator(repo)

	_, err := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))
	if err == nil {
		t.Fatal("expected error for non-course-creator proposer")
	}
	if !strings.Contains(err.Error(), "course_creator") {
		t.Fatalf("expected course_creator error, got: %v", err)
	}
}

func TestProposeFacilitator_NoFacilitatorProfile_Errors(t *testing.T) {
	ctx := context.Background()
	svc, repo, _ := newFacilitatorSvc(t)

	proposer := seedProposer(repo)
	// Facilitator team member exists but has NO FacilitatorProfile row.
	fac := repo.SeedTeamMember(RoleAdmin, StatusActive)

	_, err := svc.ProposeFacilitator(ctx, proposeInput(proposer.ID, fac.ID))
	if err == nil {
		t.Fatal("expected error for missing facilitator profile")
	}
	if !strings.Contains(err.Error(), "facilitator profile") {
		t.Fatalf("expected facilitator-profile error, got: %v", err)
	}
	// Sanity: not a generic NotFound surfaced upward.
	if errors.Is(err, apperrors.ErrNotFound) {
		t.Fatalf("expected validation error, not NotFound")
	}
}
