//go:build integration

package team_member_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/team_member"
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
			team_member.facilitator_proposals,
			team_member.facilitator_profiles,
			team_member.fee_tiers,
			team_member.team_members,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func newService(t *testing.T, pool *pgxpool.Pool) *team_member.Service {
	t.Helper()
	log := zap.NewNop()
	return team_member.NewService(team_member.NewRepository(pool), events.NewBus(log), log)
}

type fixture struct {
	adminUserID        uuid.UUID
	courseCreatorUserID uuid.UUID
	courseCreatorMemberID uuid.UUID
	facilitatorUserID  uuid.UUID
	facilitatorMemberID uuid.UUID
	feeTierID          uuid.UUID
	courseID           uuid.UUID
}

func seedFixture(t *testing.T, pool *pgxpool.Pool, svc *team_member.Service) fixture {
	t.Helper()
	ctx := context.Background()
	var f fixture

	// Seed admin user
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin@t.local','x','vernonedu_admin')
		RETURNING id`).Scan(&f.adminUserID))

	// Seed course_creator user
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('creator@t.local','x','course_creator')
		RETURNING id`).Scan(&f.courseCreatorUserID))

	// Seed facilitator user
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('facilitator@t.local','x','course_creator')
		RETURNING id`).Scan(&f.facilitatorUserID))

	// Create course creator as team member
	creator, err := svc.CreateTeamMember(ctx, team_member.CreateMemberInput{
		UserID:           f.courseCreatorUserID,
		FullName:         "Course Creator",
		Phone:            "081111111111",
		EmploymentStatus: team_member.StatusActive,
		JoinedAt:         time.Date(2023, 1, 1, 0, 0, 0, 0, time.UTC),
	})
	require.NoError(t, err)
	f.courseCreatorMemberID = creator.ID

	// Create facilitator as team member
	fac, err := svc.CreateTeamMember(ctx, team_member.CreateMemberInput{
		UserID:           f.facilitatorUserID,
		FullName:         "Dr. Facilitator",
		Phone:            "082222222222",
		EmploymentStatus: team_member.StatusActive,
		JoinedAt:         time.Date(2022, 6, 15, 0, 0, 0, 0, time.UTC),
		IsFacilitator:    true,
		Specialization:   "Data Science",
		Bio:              "Expert in ML and data analysis.",
	})
	require.NoError(t, err)
	f.facilitatorMemberID = fac.ID

	// Create fee tier
	amtPerClass := decimal.NewFromInt(500000)
	tier, err := svc.CreateFeeTier(ctx, team_member.CreateFeeTierInput{
		Name:           "Tier A",
		AmountPerClass: &amtPerClass,
		CreatedBy:      f.adminUserID,
	})
	require.NoError(t, err)
	f.feeTierID = tier.ID

	// Fake course ID (no FK constraint from team_member schema to catalog)
	f.courseID = uuid.New()

	return f
}

// TestCreateTeamMember_HappyPath verifies member creation and persistence.
func TestCreateTeamMember_HappyPath(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	var userID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('tm@t.local','x','course_creator') RETURNING id`).Scan(&userID))

	m, err := svc.CreateTeamMember(ctx, team_member.CreateMemberInput{
		UserID:   userID,
		FullName: "Alice Smith",
		Phone:    "081234567890",
		JoinedAt: time.Now(),
	})
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, m.ID)
	require.Equal(t, "Alice Smith", m.FullName)
	require.Equal(t, team_member.StatusActive, m.EmploymentStatus)
}

// TestCreateTeamMember_Facilitator verifies facilitator profile is created.
func TestCreateTeamMember_Facilitator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	var userID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('fac@t.local','x','course_creator') RETURNING id`).Scan(&userID))

	m, err := svc.CreateTeamMember(ctx, team_member.CreateMemberInput{
		UserID:         userID,
		FullName:       "Bob Facilitator",
		Phone:          "089876543210",
		JoinedAt:       time.Now(),
		IsFacilitator:  true,
		Specialization: "Backend Engineering",
		Bio:            "10 years Go.",
	})
	require.NoError(t, err)
	require.True(t, m.IsFacilitator)

	// Profile must exist in DB
	var profileID uuid.UUID
	err = pool.QueryRow(ctx, `SELECT id FROM team_member.facilitator_profiles WHERE team_member_id = $1`, m.ID).Scan(&profileID)
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, profileID)
}

// TestCreateFeeTier verifies fee tier persistence.
func TestCreateFeeTier(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	var adminID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin2@t.local','x','vernonedu_admin') RETURNING id`).Scan(&adminID))

	amt := decimal.NewFromInt(750000)
	tier, err := svc.CreateFeeTier(ctx, team_member.CreateFeeTierInput{
		Name:           "Senior",
		AmountPerClass: &amt,
		CreatedBy:      adminID,
	})
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, tier.ID)
	require.Equal(t, "Senior", tier.Name)
	require.True(t, tier.IsActive)
}

// TestProposalFullApprovalFlow verifies the full two-stage approval flow.
func TestProposalFullApprovalFlow(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	f := seedFixture(t, pool, svc)
	ctx := context.Background()

	// 1. Create proposal
	p, err := svc.CreateProposal(ctx, team_member.CreateProposalInput{
		CourseID:       f.courseID,
		ProposedByID:   f.courseCreatorMemberID,
		ProposerUserID: f.courseCreatorUserID,
		FacilitatorID:  f.facilitatorMemberID,
		FeeTierID:      f.feeTierID,
		FeeBasis:       team_member.FeeBasisPerClass,
	})
	require.NoError(t, err)
	require.Equal(t, team_member.ReviewPending, p.DeptLeaderStatus)
	require.Equal(t, team_member.ReviewPending, p.AcademicLeaderStatus)
	require.Equal(t, team_member.ReviewPending, p.FinalStatus)

	// 2. Dept leader cannot skip — academic review should fail if dept not approved
	err = svc.AcademicLeaderReview(ctx, team_member.ReviewInput{
		ProposalID: p.ID,
		Status:     team_member.ReviewApproved,
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "dept leader must approve")

	// 3. Dept leader approves
	note := "Looks good"
	err = svc.DeptLeaderReview(ctx, team_member.ReviewInput{
		ProposalID: p.ID,
		Status:     team_member.ReviewApproved,
		Note:       &note,
	})
	require.NoError(t, err)

	// 4. Academic leader approves → final_status = approved
	err = svc.AcademicLeaderReview(ctx, team_member.ReviewInput{
		ProposalID: p.ID,
		Status:     team_member.ReviewApproved,
	})
	require.NoError(t, err)

	// 5. Verify final state
	final, err := svc.GetProposal(ctx, p.ID)
	require.NoError(t, err)
	require.Equal(t, team_member.ReviewApproved, final.DeptLeaderStatus)
	require.Equal(t, team_member.ReviewApproved, final.AcademicLeaderStatus)
	require.Equal(t, team_member.ReviewApproved, final.FinalStatus)
}

// TestProposalDeptRejection verifies early rejection closes the flow.
func TestProposalDeptRejection(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	f := seedFixture(t, pool, svc)
	ctx := context.Background()

	p, err := svc.CreateProposal(ctx, team_member.CreateProposalInput{
		CourseID:       f.courseID,
		ProposedByID:   f.courseCreatorMemberID,
		ProposerUserID: f.courseCreatorUserID,
		FacilitatorID:  f.facilitatorMemberID,
		FeeTierID:      f.feeTierID,
		FeeBasis:       team_member.FeeBasisPerCourse,
	})
	require.NoError(t, err)

	reason := "Budget constraints"
	err = svc.DeptLeaderReview(ctx, team_member.ReviewInput{
		ProposalID: p.ID,
		Status:     team_member.ReviewRejected,
		Note:       &reason,
	})
	require.NoError(t, err)

	final, err := svc.GetProposal(ctx, p.ID)
	require.NoError(t, err)
	require.Equal(t, team_member.ReviewRejected, final.DeptLeaderStatus)
	require.Equal(t, team_member.ReviewRejected, final.FinalStatus)
}

// TestProposal_NonFacilitatorRejected verifies business rule enforcement.
func TestProposal_NonFacilitatorRejected(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	svc := newService(t, pool)
	f := seedFixture(t, pool, svc)
	ctx := context.Background()

	// Try to propose the course_creator (non-facilitator) as a facilitator
	_, err := svc.CreateProposal(ctx, team_member.CreateProposalInput{
		CourseID:       f.courseID,
		ProposedByID:   f.courseCreatorMemberID,
		ProposerUserID: f.courseCreatorUserID,
		FacilitatorID:  f.courseCreatorMemberID, // not a facilitator
		FeeTierID:      f.feeTierID,
		FeeBasis:       team_member.FeeBasisPerClass,
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "not a facilitator")
}
