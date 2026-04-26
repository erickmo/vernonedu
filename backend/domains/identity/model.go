package identity

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type UserRole string

const (
	RoleCEO             UserRole = "ceo"
	RoleFinance         UserRole = "finance"
	RoleAcademicLeader  UserRole = "academic_leader"
	RoleDeptLeader      UserRole = "dept_leader"
	RoleCourseCreator   UserRole = "course_creator"
	RoleVernonEduAdmin  UserRole = "vernonedu_admin"
	RoleAdmin           UserRole = "admin"
	RoleStudent         UserRole = "student"
	RoleFranchisee      UserRole = "franchisee"
)

type StudentSource string

const (
	SourceB2B StudentSource = "b2b"
	SourceB2C StudentSource = "b2c"
)

type EmploymentStatus string

const (
	StatusActive   EmploymentStatus = "active"
	StatusInactive EmploymentStatus = "inactive"
	StatusOnLeave  EmploymentStatus = "on_leave"
)

type ProposalStatus string

const (
	ProposalPending  ProposalStatus = "pending"
	ProposalApproved ProposalStatus = "approved"
	ProposalRejected ProposalStatus = "rejected"
)

type FeeBasis string

const (
	FeePerClass  FeeBasis = "per_class"
	FeePerCourse FeeBasis = "per_course"
	FeeBoth      FeeBasis = "both"
)

type User struct {
	ID              uuid.UUID `json:"id"`
	Email           string    `json:"email"`
	PasswordHash    string    `json:"-"`
	Role            UserRole  `json:"role"`
	IsActive        bool      `json:"is_active"`
	DevicePushToken *string   `json:"device_push_token,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type Student struct {
	ID        uuid.UUID     `json:"id"`
	UserID    uuid.UUID     `json:"user_id"`
	Name      string        `json:"name"`
	Email     string        `json:"email"`
	Phone     string        `json:"phone"`
	Source    StudentSource `json:"source"`
	PartnerID *uuid.UUID    `json:"partner_id,omitempty"`
	CreatedAt time.Time     `json:"created_at"`
	UpdatedAt time.Time     `json:"updated_at"`
}

type StudentProfile struct {
	ID              uuid.UUID  `json:"id"`
	StudentID       uuid.UUID  `json:"student_id"`
	DateOfBirth     *time.Time `json:"date_of_birth,omitempty"`
	Gender          *string    `json:"gender,omitempty"`
	IDType          *string    `json:"id_type,omitempty"`
	IDNumber        *string    `json:"id_number,omitempty"`
	Address         *string    `json:"address,omitempty"`
	City            *string    `json:"city,omitempty"`
	Province        *string    `json:"province,omitempty"`
	PostalCode      *string    `json:"postal_code,omitempty"`
	ProfileComplete bool       `json:"profile_complete"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

type Department struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	LeaderID  uuid.UUID `json:"leader_id"`
	IsActive  bool      `json:"is_active"`
	CreatedBy uuid.UUID `json:"created_by"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type TeamMember struct {
	ID               uuid.UUID        `json:"id"`
	UserID           uuid.UUID        `json:"user_id"`
	FullName         string           `json:"full_name"`
	Phone            string           `json:"phone"`
	DepartmentID     *uuid.UUID       `json:"department_id,omitempty"`
	Role             UserRole         `json:"role"`
	EmploymentStatus EmploymentStatus `json:"employment_status"`
	JoinedAt         time.Time        `json:"joined_at"`
	IsFacilitator    bool             `json:"is_facilitator"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

type FacilitatorProfile struct {
	ID             uuid.UUID `json:"id"`
	TeamMemberID   uuid.UUID `json:"team_member_id"`
	Specialization string    `json:"specialization"`
	Bio            *string   `json:"bio,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type FeeTier struct {
	ID               uuid.UUID        `json:"id"`
	Name             string           `json:"name"`
	AmountPerClass   *decimal.Decimal `json:"amount_per_class,omitempty"`
	AmountPerCourse  *decimal.Decimal `json:"amount_per_course,omitempty"`
	CreatedBy        uuid.UUID        `json:"created_by"`
	IsActive         bool             `json:"is_active"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

type FacilitatorProposal struct {
	ID                       uuid.UUID      `json:"id"`
	CourseID                 uuid.UUID      `json:"course_id"`
	ProposedBy               uuid.UUID      `json:"proposed_by"`
	FacilitatorID            uuid.UUID      `json:"facilitator_id"`
	FeeTierID                uuid.UUID      `json:"fee_tier_id"`
	FeeBasis                 FeeBasis       `json:"fee_basis"`
	DeptLeaderStatus         ProposalStatus `json:"dept_leader_status"`
	DeptLeaderReviewedAt     *time.Time     `json:"dept_leader_reviewed_at,omitempty"`
	DeptLeaderNote           *string        `json:"dept_leader_note,omitempty"`
	AcademicLeaderStatus     ProposalStatus `json:"academic_leader_status"`
	AcademicLeaderReviewedAt *time.Time     `json:"academic_leader_reviewed_at,omitempty"`
	AcademicLeaderNote       *string        `json:"academic_leader_note,omitempty"`
	FinalStatus              ProposalStatus `json:"final_status"`
	CreatedAt                time.Time      `json:"created_at"`
	UpdatedAt                time.Time      `json:"updated_at"`
}
