package identity

import (
	"context"
	"sync"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// fakeRepo is an in-memory Repository implementation for service tests.
type fakeRepo struct {
	mu          sync.Mutex
	users       map[uuid.UUID]*User
	byEmail     map[string]*User
	students    map[uuid.UUID]*Student
	studentByU  map[uuid.UUID]*Student
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

// fakeBus is an in-memory events.Bus that records published event types.
type fakeBus struct {
	mu    sync.Mutex
	fired map[events.EventType]int
}

var _ events.Bus = (*fakeBus)(nil)

func newFakeBus() *fakeBus {
	return &fakeBus{fired: map[events.EventType]int{}}
}

func (b *fakeBus) Publish(ctx context.Context, e events.Event) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.fired[e.Type]++
	return nil
}

func (b *fakeBus) Subscribe(t events.EventType, h events.HandlerFunc) {}

// Fired reports whether at least one event of the given type was published.
func (b *fakeBus) Fired(typ string) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.fired[events.EventType(typ)] > 0
}

func testLogger() *zap.Logger { return zap.NewNop() }
