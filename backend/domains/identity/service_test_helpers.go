package identity

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

const (
	testJWTSecret = "test-secret-do-not-use-in-prod"
	testJWTExpiry = 24 * time.Hour
)

// fakeRepo is an in-memory Repository implementation for service tests.
type fakeRepo struct {
	mu          sync.Mutex
	users       map[uuid.UUID]*User
	byEmail     map[string]*User
	students    map[uuid.UUID]*Student
	studentByU  map[uuid.UUID]*Student
	profiles    map[uuid.UUID]*StudentProfile
	teamMembers map[uuid.UUID]*TeamMember
	departments map[uuid.UUID]*Department
	proposals   map[uuid.UUID]*FacilitatorProposal
}

var _ Repository = (*fakeRepo)(nil)

func newFakeRepo() *fakeRepo {
	return &fakeRepo{
		users:       map[uuid.UUID]*User{},
		byEmail:     map[string]*User{},
		students:    map[uuid.UUID]*Student{},
		studentByU:  map[uuid.UUID]*Student{},
		profiles:    map[uuid.UUID]*StudentProfile{},
		teamMembers: map[uuid.UUID]*TeamMember{},
		departments: map[uuid.UUID]*Department{},
		proposals:   map[uuid.UUID]*FacilitatorProposal{},
	}
}

// SeedUserEmail inserts a placeholder user for the given email.
func (r *fakeRepo) SeedUserEmail(email string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	u := &User{ID: uuid.New(), Email: email, IsActive: true, Role: RoleStudent}
	r.users[u.ID] = u
	r.byEmail[email] = u
}

// SeedUser inserts a fully-formed user with the given password hash and role.
func (r *fakeRepo) SeedUser(email, hash string, role UserRole) *User {
	r.mu.Lock()
	defer r.mu.Unlock()
	u := &User{
		ID:           uuid.New(),
		Email:        email,
		PasswordHash: hash,
		Role:         role,
		IsActive:     true,
	}
	r.users[u.ID] = u
	r.byEmail[email] = u
	return u
}

func (r *fakeRepo) CreateUser(ctx context.Context, user *User) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.byEmail[user.Email]; ok {
		return apperrors.Conflictf("email already registered")
	}
	r.users[user.ID] = user
	r.byEmail[user.Email] = user
	return nil
}

func (r *fakeRepo) GetUserByID(ctx context.Context, id uuid.UUID) (*User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if u, ok := r.users[id]; ok {
		return u, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if u, ok := r.byEmail[email]; ok {
		return u, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) UpdateUser(ctx context.Context, user *User) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.users[user.ID]; !ok {
		return apperrors.ErrNotFound
	}
	r.users[user.ID] = user
	r.byEmail[user.Email] = user
	return nil
}

func (r *fakeRepo) DeactivateUser(ctx context.Context, id uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	u, ok := r.users[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	u.IsActive = false
	return nil
}

// SeedStudent inserts a minimal student record (and matching user) for tests.
func (r *fakeRepo) SeedStudent(email string, source StudentSource) *Student {
	r.mu.Lock()
	defer r.mu.Unlock()
	u := &User{ID: uuid.New(), Email: email, IsActive: true, Role: RoleStudent}
	r.users[u.ID] = u
	r.byEmail[email] = u
	s := &Student{
		ID:     uuid.New(),
		UserID: u.ID,
		Email:  email,
		Source: source,
	}
	r.students[s.ID] = s
	r.studentByU[u.ID] = s
	return s
}

// GetProfile returns the seeded/upserted student profile for inspection.
func (r *fakeRepo) GetProfile(studentID uuid.UUID) *StudentProfile {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.profiles[studentID]
}

func (r *fakeRepo) GetStudentProfileByStudentID(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if p, ok := r.profiles[studentID]; ok {
		return p, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) UpsertStudentProfile(ctx context.Context, studentID uuid.UUID, in ProfileInput, complete bool) (*StudentProfile, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	p, ok := r.profiles[studentID]
	if !ok {
		p = &StudentProfile{
			ID:        uuid.New(),
			StudentID: studentID,
			CreatedAt: now,
		}
	}
	if in.DateOfBirth != nil {
		p.DateOfBirth = in.DateOfBirth
	}
	if in.Gender != nil {
		p.Gender = in.Gender
	}
	if in.IDType != nil {
		p.IDType = in.IDType
	}
	if in.IDNumber != nil {
		p.IDNumber = in.IDNumber
	}
	if in.Address != nil {
		p.Address = in.Address
	}
	if in.City != nil {
		p.City = in.City
	}
	if in.Province != nil {
		p.Province = in.Province
	}
	if in.PostalCode != nil {
		p.PostalCode = in.PostalCode
	}
	p.ProfileComplete = complete
	p.UpdatedAt = now
	r.profiles[studentID] = p
	return p, nil
}

func (r *fakeRepo) CreateStudent(ctx context.Context, s *Student) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.students[s.ID] = s
	r.studentByU[s.UserID] = s
	return nil
}

func (r *fakeRepo) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if s, ok := r.students[id]; ok {
		return s, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if s, ok := r.studentByU[userID]; ok {
		return s, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) ListStudents(ctx context.Context, limit, offset int) ([]*Student, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*Student, 0, len(r.students))
	for _, s := range r.students {
		out = append(out, s)
	}
	return out, nil
}

// SeedTeamMember inserts a team member with the given role + status for tests.
func (r *fakeRepo) SeedTeamMember(role UserRole, status EmploymentStatus) *TeamMember {
	r.mu.Lock()
	defer r.mu.Unlock()
	tm := &TeamMember{
		ID:               uuid.New(),
		UserID:           uuid.New(),
		Role:             role,
		EmploymentStatus: status,
		JoinedAt:         time.Now(),
	}
	r.teamMembers[tm.ID] = tm
	return tm
}

func (r *fakeRepo) CreateTeamMember(ctx context.Context, tm *TeamMember) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.teamMembers[tm.ID] = tm
	return nil
}

func (r *fakeRepo) GetTeamMemberByID(ctx context.Context, id uuid.UUID) (*TeamMember, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if tm, ok := r.teamMembers[id]; ok {
		return tm, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, status EmploymentStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	tm, ok := r.teamMembers[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	tm.EmploymentStatus = status
	return nil
}

func (r *fakeRepo) CreateDepartment(ctx context.Context, dept *Department) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.departments[dept.ID] = dept
	return nil
}

func (r *fakeRepo) GetDepartmentByID(ctx context.Context, id uuid.UUID) (*Department, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if d, ok := r.departments[id]; ok {
		return d, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) ListDepartments(ctx context.Context) ([]*Department, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*Department, 0, len(r.departments))
	for _, d := range r.departments {
		out = append(out, d)
	}
	return out, nil
}

func (r *fakeRepo) CreateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.proposals[p.ID] = p
	return nil
}

func (r *fakeRepo) GetFacilitatorProposalByID(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if p, ok := r.proposals[id]; ok {
		return p, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeRepo) UpdateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.proposals[p.ID]; !ok {
		return apperrors.ErrNotFound
	}
	r.proposals[p.ID] = p
	return nil
}

// fakeBus is an in-memory events.Bus that records published events.
type fakeBus struct {
	mu       sync.Mutex
	fired    map[events.EventType]int
	payloads map[events.EventType][]any
}

var _ events.Bus = (*fakeBus)(nil)

func newFakeBus() *fakeBus {
	return &fakeBus{
		fired:    map[events.EventType]int{},
		payloads: map[events.EventType][]any{},
	}
}

func (b *fakeBus) Publish(ctx context.Context, e events.Event) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.fired[e.Type]++
	b.payloads[e.Type] = append(b.payloads[e.Type], e.Payload)
	return nil
}

// LastPayload returns the most recent payload for the given event type.
func (b *fakeBus) LastPayload(typ events.EventType) any {
	b.mu.Lock()
	defer b.mu.Unlock()
	list := b.payloads[typ]
	if len(list) == 0 {
		return nil
	}
	return list[len(list)-1]
}

func (b *fakeBus) Subscribe(t events.EventType, h events.HandlerFunc) {}

// Fired reports whether at least one event of the given type was published.
func (b *fakeBus) Fired(typ string) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.fired[events.EventType(typ)] > 0
}

func testLogger() *zap.Logger { return zap.NewNop() }
