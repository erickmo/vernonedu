package catalog

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// fakeCatalogRepo is an in-memory Repository for service tests.
type fakeCatalogRepo struct {
	mu                 sync.Mutex
	courses            map[uuid.UUID]*Course
	batches            map[uuid.UUID]*CourseBatch
	classes            map[uuid.UUID]*Class
	modules            map[uuid.UUID]*CourseModule
	moduleVersions     map[uuid.UUID]*ModuleVersion
	formatConfigs      map[uuid.UUID]*CourseFormatConfig
	costTemplates      map[uuid.UUID]*CourseCostTemplate
	batchCostLineItems    map[uuid.UUID]*BatchCostLineItem
	enrollmentCounts      map[uuid.UUID]int
	approvedFacilitators  map[uuid.UUID]bool
	batchModuleConfigs    map[string]*BatchModuleConfig
	studentModuleAccess   map[string]*StudentModuleAccess
}

// smaKey builds the composite key for studentModuleAccess.
func smaKey(studentID, moduleID uuid.UUID) string {
	return studentID.String() + "|" + moduleID.String()
}

// bmcKey builds the composite key for batchModuleConfigs.
func bmcKey(batchID, moduleID uuid.UUID) string {
	return batchID.String() + "|" + moduleID.String()
}

var _ Repository = (*fakeCatalogRepo)(nil)

func newFakeCatalogRepo() *fakeCatalogRepo {
	return &fakeCatalogRepo{
		courses:        map[uuid.UUID]*Course{},
		batches:        map[uuid.UUID]*CourseBatch{},
		classes:        map[uuid.UUID]*Class{},
		modules:        map[uuid.UUID]*CourseModule{},
		moduleVersions: map[uuid.UUID]*ModuleVersion{},
		formatConfigs:      map[uuid.UUID]*CourseFormatConfig{},
		costTemplates:      map[uuid.UUID]*CourseCostTemplate{},
		batchCostLineItems:   map[uuid.UUID]*BatchCostLineItem{},
		enrollmentCounts:     map[uuid.UUID]int{},
		approvedFacilitators: map[uuid.UUID]bool{},
		batchModuleConfigs:   map[string]*BatchModuleConfig{},
		studentModuleAccess:  map[string]*StudentModuleAccess{},
	}
}

// GrantModuleAccess inserts a module-access row idempotently (no-op on dup).
func (r *fakeCatalogRepo) GrantModuleAccess(ctx context.Context, studentID, moduleID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	key := smaKey(studentID, moduleID)
	if _, ok := r.studentModuleAccess[key]; ok {
		return nil
	}
	r.studentModuleAccess[key] = &StudentModuleAccess{
		ID:        uuid.New(),
		StudentID: studentID,
		ModuleID:  moduleID,
		GrantedAt: time.Now(),
	}
	return nil
}

// ListActiveModulesByBatch resolves batch.course_id then filters active modules.
func (r *fakeCatalogRepo) ListActiveModulesByBatch(ctx context.Context, batchID uuid.UUID) ([]*CourseModule, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	b, ok := r.batches[batchID]
	if !ok {
		return []*CourseModule{}, nil
	}
	out := make([]*CourseModule, 0)
	for _, m := range r.modules {
		if m.CourseID == b.CourseID && m.IsActive {
			out = append(out, m)
		}
	}
	return out, nil
}

// ListModuleAccessForStudent returns all access rows for a student.
func (r *fakeCatalogRepo) ListModuleAccessForStudent(ctx context.Context, studentID uuid.UUID) ([]*StudentModuleAccess, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*StudentModuleAccess, 0)
	for _, a := range r.studentModuleAccess {
		if a.StudentID == studentID {
			out = append(out, a)
		}
	}
	return out, nil
}

// SeedBatchModuleConfig inserts a fully-formed BMC for tests.
func (r *fakeCatalogRepo) SeedBatchModuleConfig(batchID, moduleID uuid.UUID, policy VersionPolicy, lockedVersionID *uuid.UUID, setBy uuid.UUID) *BatchModuleConfig {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	cfg := &BatchModuleConfig{
		ID:              uuid.New(),
		CourseBatchID:   batchID,
		ModuleID:        moduleID,
		VersionPolicy:   policy,
		LockedVersionID: lockedVersionID,
		SetBy:           setBy,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	r.batchModuleConfigs[bmcKey(batchID, moduleID)] = cfg
	return cfg
}

func (r *fakeCatalogRepo) GetBatchModuleConfig(ctx context.Context, batchID, moduleID uuid.UUID) (*BatchModuleConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if cfg, ok := r.batchModuleConfigs[bmcKey(batchID, moduleID)]; ok {
		return cfg, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCatalogRepo) UpsertBatchModuleConfig(ctx context.Context, cfg *BatchModuleConfig) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	key := bmcKey(cfg.CourseBatchID, cfg.ModuleID)
	if existing, ok := r.batchModuleConfigs[key]; ok {
		existing.VersionPolicy = cfg.VersionPolicy
		existing.LockedVersionID = cfg.LockedVersionID
		existing.SetBy = cfg.SetBy
		existing.UpdatedAt = now
		// Preserve original ID/CreatedAt; reflect back to caller.
		cfg.ID = existing.ID
		cfg.CreatedAt = existing.CreatedAt
		cfg.UpdatedAt = now
		return nil
	}
	if cfg.ID == uuid.Nil {
		cfg.ID = uuid.New()
	}
	cfg.CreatedAt = now
	cfg.UpdatedAt = now
	r.batchModuleConfigs[key] = cfg
	return nil
}

func (r *fakeCatalogRepo) GetLatestPublishedVersion(ctx context.Context, moduleID uuid.UUID) (*ModuleVersion, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var best *ModuleVersion
	for _, mv := range r.moduleVersions {
		if mv.ModuleID != moduleID || mv.Status != ModulePublished {
			continue
		}
		if best == nil || mv.VersionNumber > best.VersionNumber {
			best = mv
		}
	}
	if best == nil {
		return nil, apperrors.ErrNotFound
	}
	return best, nil
}

// SeedApprovedFacilitator marks userID as having an approved FacilitatorProposal.
func (r *fakeCatalogRepo) SeedApprovedFacilitator(userID uuid.UUID) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.approvedFacilitators[userID] = true
}

// IsApprovedFacilitator returns the seeded flag (false by default).
func (r *fakeCatalogRepo) IsApprovedFacilitator(ctx context.Context, userID uuid.UUID) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.approvedFacilitators[userID], nil
}

func (r *fakeCatalogRepo) UpdateClassInstructor(ctx context.Context, classID, instructorID uuid.UUID, instructorType InstructorType, assignedBy AssignedByType) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cl, ok := r.classes[classID]
	if !ok {
		return apperrors.ErrNotFound
	}
	cl.InstructorID = instructorID
	cl.InstructorType = instructorType
	cl.AssignedBy = assignedBy
	cl.UpdatedAt = time.Now()
	return nil
}

func (r *fakeCatalogRepo) UpdateClassSchedule(ctx context.Context, classID uuid.UUID, sessionDate time.Time, startTime, endTime string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cl, ok := r.classes[classID]
	if !ok {
		return apperrors.ErrNotFound
	}
	cl.SessionDate = sessionDate
	cl.StartTime = startTime
	cl.EndTime = endTime
	cl.UpdatedAt = time.Now()
	return nil
}

func (r *fakeCatalogRepo) DeleteClass(ctx context.Context, classID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.classes[classID]; !ok {
		return apperrors.ErrNotFound
	}
	delete(r.classes, classID)
	return nil
}

// SeedEnrollmentCount sets the confirmed enrollment count for a batch.
func (r *fakeCatalogRepo) SeedEnrollmentCount(batchID uuid.UUID, n int) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.enrollmentCounts[batchID] = n
}

// CountEnrollmentsByBatch returns the seeded count (zero if unseeded).
func (r *fakeCatalogRepo) CountEnrollmentsByBatch(ctx context.Context, batchID uuid.UUID) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.enrollmentCounts[batchID], nil
}

// SeedCostTemplate inserts a cost template directly for tests.
func (r *fakeCatalogRepo) SeedCostTemplate(courseID uuid.UUID, label string, amount decimal.Decimal) *CourseCostTemplate {
	r.mu.Lock()
	defer r.mu.Unlock()
	t := &CourseCostTemplate{
		ID:        uuid.New(),
		CourseID:  courseID,
		Label:     label,
		Amount:    amount,
		CostType:  CostFixed,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	r.costTemplates[t.ID] = t
	return t
}

func (r *fakeCatalogRepo) CreateCourseCostTemplate(ctx context.Context, t *CourseCostTemplate) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	t.CreatedAt = now
	t.UpdatedAt = now
	r.costTemplates[t.ID] = t
	return nil
}

func (r *fakeCatalogRepo) ListCourseCostTemplates(ctx context.Context, courseID uuid.UUID) ([]*CourseCostTemplate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*CourseCostTemplate, 0)
	for _, t := range r.costTemplates {
		if t.CourseID == courseID {
			out = append(out, t)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) CreateBatchWithCostsCopy(ctx context.Context, b *CourseBatch, createdBy uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	b.CreatedAt = now
	b.UpdatedAt = now
	r.batches[b.ID] = b
	for _, t := range r.costTemplates {
		if t.CourseID != b.CourseID {
			continue
		}
		tplID := t.ID
		li := &BatchCostLineItem{
			ID:            uuid.New(),
			CourseBatchID: b.ID,
			TemplateRefID: &tplID,
			Label:         t.Label,
			Amount:        t.Amount,
			CostType:      t.CostType,
			IsRemoved:     false,
			ReferenceType: CostRefManual,
			CreatedBy:     createdBy,
			CreatedAt:     now,
			UpdatedAt:     now,
		}
		r.batchCostLineItems[li.ID] = li
	}
	return nil
}

func (r *fakeCatalogRepo) CreateBatchCostLineItem(ctx context.Context, li *BatchCostLineItem) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	li.CreatedAt = now
	li.UpdatedAt = now
	r.batchCostLineItems[li.ID] = li
	return nil
}

func (r *fakeCatalogRepo) UpdateBatchCostLineItem(ctx context.Context, li *BatchCostLineItem) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.batchCostLineItems[li.ID]; !ok {
		return apperrors.ErrNotFound
	}
	li.UpdatedAt = time.Now()
	r.batchCostLineItems[li.ID] = li
	return nil
}

func (r *fakeCatalogRepo) ListBatchCostLineItems(ctx context.Context, batchID uuid.UUID) ([]*BatchCostLineItem, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*BatchCostLineItem, 0)
	for _, li := range r.batchCostLineItems {
		if li.CourseBatchID == batchID {
			out = append(out, li)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) AddFormatConfig(ctx context.Context, cfg *CourseFormatConfig) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, existing := range r.formatConfigs {
		if existing.CourseID == cfg.CourseID && existing.Format == cfg.Format {
			return apperrors.ErrConflict
		}
	}
	now := time.Now()
	cfg.CreatedAt = now
	cfg.UpdatedAt = now
	r.formatConfigs[cfg.ID] = cfg
	return nil
}

func (r *fakeCatalogRepo) DisableFormat(ctx context.Context, configID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cfg, ok := r.formatConfigs[configID]
	if !ok {
		return apperrors.ErrNotFound
	}
	cfg.IsEnabled = false
	cfg.UpdatedAt = time.Now()
	return nil
}

func (r *fakeCatalogRepo) ListFormatConfigsByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseFormatConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*CourseFormatConfig, 0)
	for _, cfg := range r.formatConfigs {
		if cfg.CourseID == courseID {
			out = append(out, cfg)
		}
	}
	return out, nil
}

func (r *fakeCatalogRepo) GetFormatConfig(ctx context.Context, id uuid.UUID) (*CourseFormatConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if cfg, ok := r.formatConfigs[id]; ok {
		return cfg, nil
	}
	return nil, apperrors.ErrNotFound
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
	for _, existing := range r.modules {
		if existing.CourseID == m.CourseID && existing.Order == m.Order {
			return apperrors.ErrConflict
		}
	}
	now := time.Now()
	m.CreatedAt = now
	m.UpdatedAt = now
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

// PublishModuleVersionAtomic mirrors the SQL transaction: archive any
// currently-published version of the same module, then mark the target
// 'published'. The mutex provides the atomicity that the real DB gives via
// the partial unique index uq_module_one_published.
func (r *fakeCatalogRepo) PublishModuleVersionAtomic(ctx context.Context, versionID, publishedBy uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	target, ok := r.moduleVersions[versionID]
	if !ok {
		return apperrors.ErrNotFound
	}
	now := time.Now()
	for _, mv := range r.moduleVersions {
		if mv.ID == versionID {
			continue
		}
		if mv.ModuleID == target.ModuleID && mv.Status == ModulePublished {
			mv.Status = ModuleArchived
			mv.UpdatedAt = now
		}
	}
	target.Status = ModulePublished
	target.PublishedAt = &now
	pb := publishedBy
	target.PublishedBy = &pb
	target.UpdatedAt = now
	return nil
}

// SeedModule inserts a fully-formed module for tests (no constraint checks).
func (r *fakeCatalogRepo) SeedModule(m *CourseModule) *CourseModule {
	r.mu.Lock()
	defer r.mu.Unlock()
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	now := time.Now()
	if m.CreatedAt.IsZero() {
		m.CreatedAt = now
	}
	m.UpdatedAt = now
	r.modules[m.ID] = m
	return m
}

// SeedModuleVersion inserts a fully-formed module version for tests.
func (r *fakeCatalogRepo) SeedModuleVersion(mv *ModuleVersion) *ModuleVersion {
	r.mu.Lock()
	defer r.mu.Unlock()
	if mv.ID == uuid.Nil {
		mv.ID = uuid.New()
	}
	now := time.Now()
	if mv.CreatedAt.IsZero() {
		mv.CreatedAt = now
	}
	mv.UpdatedAt = now
	r.moduleVersions[mv.ID] = mv
	return mv
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
