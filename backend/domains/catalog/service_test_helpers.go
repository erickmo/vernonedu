package catalog

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// fakeCatalogRepo is an in-memory Repository for service tests.
type fakeCatalogRepo struct {
	mu             sync.Mutex
	courses        map[uuid.UUID]*Course
	batches        map[uuid.UUID]*CourseBatch
	classes        map[uuid.UUID]*Class
	modules        map[uuid.UUID]*CourseModule
	moduleVersions map[uuid.UUID]*ModuleVersion
}

var _ Repository = (*fakeCatalogRepo)(nil)

func newFakeCatalogRepo() *fakeCatalogRepo {
	return &fakeCatalogRepo{
		courses:        map[uuid.UUID]*Course{},
		batches:        map[uuid.UUID]*CourseBatch{},
		classes:        map[uuid.UUID]*Class{},
		modules:        map[uuid.UUID]*CourseModule{},
		moduleVersions: map[uuid.UUID]*ModuleVersion{},
	}
}

// SeedCourse inserts a fully-formed course for tests.
func (r *fakeCatalogRepo) SeedCourse(c *Course) *Course {
	r.mu.Lock()
	defer r.mu.Unlock()
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	now := time.Now()
	if c.CreatedAt.IsZero() {
		c.CreatedAt = now
	}
	c.UpdatedAt = now
	r.courses[c.ID] = c
	return c
}

// SeedBatch inserts a fully-formed batch for tests.
func (r *fakeCatalogRepo) SeedBatch(b *CourseBatch) *CourseBatch {
	r.mu.Lock()
	defer r.mu.Unlock()
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	now := time.Now()
	if b.CreatedAt.IsZero() {
		b.CreatedAt = now
	}
	b.UpdatedAt = now
	r.batches[b.ID] = b
	return b
}

func (r *fakeCatalogRepo) CreateCourse(ctx context.Context, c *Course) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	c.CreatedAt = now
	c.UpdatedAt = now
	r.courses[c.ID] = c
	return nil
}

func (r *fakeCatalogRepo) GetCourseByID(ctx context.Context, id uuid.UUID) (*Course, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if c, ok := r.courses[id]; ok {
		return c, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCatalogRepo) UpdateCourse(ctx context.Context, c *Course) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.courses[c.ID]; !ok {
		return apperrors.ErrNotFound
	}
	c.UpdatedAt = time.Now()
	r.courses[c.ID] = c
	return nil
}

func (r *fakeCatalogRepo) ListCoursesByDepartment(ctx context.Context, deptID uuid.UUID) ([]*Course, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*Course, 0)
	for _, c := range r.courses {
		if c.DepartmentID == deptID {
			out = append(out, c)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) CreateBatch(ctx context.Context, b *CourseBatch) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	b.CreatedAt = now
	b.UpdatedAt = now
	r.batches[b.ID] = b
	return nil
}

func (r *fakeCatalogRepo) GetBatchByID(ctx context.Context, id uuid.UUID) (*CourseBatch, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if b, ok := r.batches[id]; ok {
		return b, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCatalogRepo) UpdateBatchStatus(ctx context.Context, id uuid.UUID, status BatchStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	b, ok := r.batches[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	b.Status = status
	return nil
}

func (r *fakeCatalogRepo) ListBatchesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseBatch, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*CourseBatch, 0)
	for _, b := range r.batches {
		if b.CourseID == courseID {
			out = append(out, b)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) CreateClass(ctx context.Context, cl *Class) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.classes[cl.ID] = cl
	return nil
}

func (r *fakeCatalogRepo) GetClassByID(ctx context.Context, id uuid.UUID) (*Class, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if cl, ok := r.classes[id]; ok {
		return cl, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCatalogRepo) ListClassesByBatch(ctx context.Context, batchID uuid.UUID) ([]*Class, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*Class, 0)
	for _, cl := range r.classes {
		if cl.CourseBatchID == batchID {
			out = append(out, cl)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) CreateModule(ctx context.Context, m *CourseModule) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.modules[m.ID] = m
	return nil
}

func (r *fakeCatalogRepo) GetModuleByID(ctx context.Context, id uuid.UUID) (*CourseModule, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if m, ok := r.modules[id]; ok {
		return m, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCatalogRepo) ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*CourseModule, 0)
	for _, m := range r.modules {
		if m.CourseID == courseID && m.IsActive {
			out = append(out, m)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.moduleVersions[mv.ID] = mv
	return nil
}

func (r *fakeCatalogRepo) GetModuleVersionByID(ctx context.Context, id uuid.UUID) (*ModuleVersion, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if mv, ok := r.moduleVersions[id]; ok {
		return mv, nil
	}
	return nil, apperrors.ErrNotFound
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

func (b *fakeBus) Subscribe(t events.EventType, h events.HandlerFunc) {}

// Fired reports whether any event of the given type was published.
func (b *fakeBus) Fired(typ events.EventType) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.fired[typ] > 0
}

func testLogger() *zap.Logger { return zap.NewNop() }
