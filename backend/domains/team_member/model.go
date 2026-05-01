package team_member

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// EmploymentStatus represents a team member's employment state.
type EmploymentStatus string

const (
	StatusActive   EmploymentStatus = "active"
	StatusInactive EmploymentStatus = "inactive"
	StatusOnLeave  EmploymentStatus = "on_leave"
)

// ReviewStatus is used for proposal approval stages.
type ReviewStatus string

const (
	ReviewPending  ReviewStatus = "pending"
	ReviewApproved ReviewStatus = "approved"
	ReviewRejected ReviewStatus = "rejected"
)

// FeeBasis defines how a facilitator is compensated.
type FeeBasis string

const (
	FeeBasisPerClass  FeeBasis = "per_class"
	FeeBasisPerCourse FeeBasis = "per_course"
	FeeBasisBoth      FeeBasis = "both"
)

// TeamMember is the central entity for internal VernonEdu employees.
type TeamMember struct {
	ID               uuid.UUID        `json:"id"`
	UserID           uuid.UUID        `json:"user_id"`
	FullName         string           `json:"full_name"`
	Phone            string           `json:"phone"`
	DepartmentID     *uuid.UUID       `json:"department_id,omitempty"`
	EmploymentStatus EmploymentStatus `json:"employment_status"`
	JoinedAt         time.Time        `json:"joined_at"`
	IsFacilitator    bool             `json:"is_facilitator"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

// FacilitatorProfile holds extra info when TeamMember.IsFacilitator = true.
type FacilitatorProfile struct {
	ID             uuid.UUID `json:"id"`
	TeamMemberID   uuid.UUID `json:"team_member_id"`
	Specialization string    `json:"specialization"`
	Bio            string    `json:"bio"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// FeeTier defines a named compensation bracket for facilitators.
type FeeTier struct {
	ID               uuid.UUID        `json:"id"`
	Name             string           `json:"name"`
	AmountPerClass   *decimal.Decimal `json:"amount_per_class,omitempty"`
	AmountPerCourse  *decimal.Decimal `json:"amount_per_course,omitempty"`
	IsActive         bool             `json:"is_active"`
	CreatedBy        uuid.UUID        `json:"created_by"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

// FacilitatorProposal records a course-creator's request to assign a facilitator.
type FacilitatorProposal struct {
	ID                       uuid.UUID    `json:"id"`
	CourseID                 uuid.UUID    `json:"course_id"`
	ProposedBy               uuid.UUID    `json:"proposed_by"`
	FacilitatorID            uuid.UUID    `json:"facilitator_id"`
	FeeTierID                uuid.UUID    `json:"fee_tier_id"`
	FeeBasis                 FeeBasis     `json:"fee_basis"`
	DeptLeaderStatus         ReviewStatus `json:"dept_leader_status"`
	DeptLeaderReviewedAt     *time.Time   `json:"dept_leader_reviewed_at,omitempty"`
	DeptLeaderNote           *string      `json:"dept_leader_note,omitempty"`
	AcademicLeaderStatus     ReviewStatus `json:"academic_leader_status"`
	AcademicLeaderReviewedAt *time.Time   `json:"academic_leader_reviewed_at,omitempty"`
	AcademicLeaderNote       *string      `json:"academic_leader_note,omitempty"`
	FinalStatus              ReviewStatus `json:"final_status"`
	CreatedAt                time.Time    `json:"created_at"`
	UpdatedAt                time.Time    `json:"updated_at"`
}
