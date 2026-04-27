package enrollment

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

// fakeEnrollmentRepo is an in-memory Repository implementation for service tests.
type fakeEnrollmentRepo struct {
	mu             sync.Mutex
	enrollments    map[uuid.UUID]*Enrollment
	byStudentBatch map[string]*Enrollment
	vouchers       map[uuid.UUID]*Voucher
	vouchersByCode map[string]*Voucher
	usagesByEnroll map[uuid.UUID]*VoucherUsage
}

var _ Repository = (*fakeEnrollmentRepo)(nil)

func newFakeEnrollmentRepo() *fakeEnrollmentRepo {
	return &fakeEnrollmentRepo{
		enrollments:    map[uuid.UUID]*Enrollment{},
		byStudentBatch: map[string]*Enrollment{},
		vouchers:       map[uuid.UUID]*Voucher{},
		vouchersByCode: map[string]*Voucher{},
		usagesByEnroll: map[uuid.UUID]*VoucherUsage{},
	}
}

func sbKey(s, b uuid.UUID) string { return s.String() + "|" + b.String() }

// SeedVoucher inserts a voucher for tests.
func (r *fakeEnrollmentRepo) SeedVoucher(v *Voucher) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *v
	r.vouchers[v.ID] = &cp
	if v.Code != "" {
		r.vouchersByCode[v.Code] = &cp
	}
}

// SeedEnrollment inserts an enrollment for tests.
func (r *fakeEnrollmentRepo) SeedEnrollment(e *Enrollment) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *e
	r.enrollments[e.ID] = &cp
	r.byStudentBatch[sbKey(e.StudentID, e.CourseBatchID)] = &cp
}

// --- Repository implementation ---

func (r *fakeEnrollmentRepo) CreateEnrollment(ctx context.Context, e *Enrollment) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.byStudentBatch[sbKey(e.StudentID, e.CourseBatchID)]; ok {
		return apperrors.Conflictf("duplicate enrollment")
	}
	now := time.Now()
	e.CreatedAt = now
	e.UpdatedAt = now
	cp := *e
	r.enrollments[e.ID] = &cp
	r.byStudentBatch[sbKey(e.StudentID, e.CourseBatchID)] = &cp
	return nil
}

func (r *fakeEnrollmentRepo) GetEnrollmentByID(ctx context.Context, id uuid.UUID) (*Enrollment, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	e, ok := r.enrollments[id]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *e
	return &cp, nil
}

func (r *fakeEnrollmentRepo) GetEnrollmentByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*Enrollment, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	e, ok := r.byStudentBatch[sbKey(studentID, batchID)]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *e
	return &cp, nil
}

func (r *fakeEnrollmentRepo) UpdateEnrollmentStatus(ctx context.Context, id uuid.UUID, payStatus PaymentStatus, compStatus CompletionStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	e, ok := r.enrollments[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	e.PaymentStatus = payStatus
	e.CompletionStatus = compStatus
	e.UpdatedAt = time.Now()
	return nil
}

func (r *fakeEnrollmentRepo) UpdateEnrollmentCompletion(ctx context.Context, id uuid.UUID, compStatus CompletionStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	e, ok := r.enrollments[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	e.CompletionStatus = compStatus
	e.UpdatedAt = time.Now()
	return nil
}

func (r *fakeEnrollmentRepo) ListEnrollmentsByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []*Enrollment
	for _, e := range r.enrollments {
		if e.StudentID == studentID {
			cp := *e
			out = append(out, &cp)
		}
	}
	return out, nil
}

func (r *fakeEnrollmentRepo) CountEnrollmentsByBatchAndFormat(ctx context.Context, batchID uuid.UUID, format EnrollmentFormat) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	count := 0
	for _, e := range r.enrollments {
		if e.CourseBatchID == batchID && e.Format == format && e.CompletionStatus != CompletionDropped {
			count++
		}
	}
	return count, nil
}

func (r *fakeEnrollmentRepo) ListEnrollmentsByBatch(ctx context.Context, batchID uuid.UUID) ([]*Enrollment, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []*Enrollment
	for _, e := range r.enrollments {
		if e.CourseBatchID == batchID {
			cp := *e
			out = append(out, &cp)
		}
	}
	return out, nil
}

func (r *fakeEnrollmentRepo) GetVoucherByCode(ctx context.Context, code string) (*Voucher, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.vouchersByCode[code]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *v
	return &cp, nil
}

func (r *fakeEnrollmentRepo) CreateVoucher(ctx context.Context, v *Voucher) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.vouchersByCode[v.Code]; ok {
		return apperrors.Conflictf("voucher code exists")
	}
	now := time.Now()
	v.CreatedAt = now
	v.UpdatedAt = now
	cp := *v
	r.vouchers[v.ID] = &cp
	r.vouchersByCode[v.Code] = &cp
	return nil
}

func (r *fakeEnrollmentRepo) ConsumeVoucher(ctx context.Context, p ConsumeVoucherParams) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.vouchers[p.VoucherID]
	if !ok {
		return apperrors.ErrNotFound
	}
	if !v.IsActive {
		return apperrors.Validationf("voucher inactive")
	}
	if v.AssignedTo != nil && *v.AssignedTo != p.StudentID {
		return apperrors.ErrForbidden
	}
	if v.ValidUntil != nil && v.ValidUntil.Before(time.Now()) {
		return apperrors.Validationf("voucher expired")
	}
	if v.MaxUses != nil && v.UsedCount >= *v.MaxUses {
		return apperrors.Validationf("voucher max uses reached")
	}
	if _, dup := r.usagesByEnroll[p.EnrollmentID]; dup {
		return apperrors.Conflictf("voucher already used for this enrollment")
	}
	v.UsedCount++
	v.UpdatedAt = time.Now()
	r.usagesByEnroll[p.EnrollmentID] = &VoucherUsage{
		ID:            uuid.New(),
		VoucherID:     p.VoucherID,
		EnrollmentID:  p.EnrollmentID,
		OriginalPrice: p.OriginalPrice,
		FinalPrice:    p.FinalPrice,
		UsedAt:        time.Now(),
		CreatedBy:     p.CreatedBy,
	}
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

func (b *fakeBus) Subscribe(t events.EventType, h events.HandlerFunc) {}

// Fired reports whether at least one event of the given type was published.
func (b *fakeBus) Fired(typ events.EventType) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.fired[typ] > 0
}

func testLogger() *zap.Logger { return zap.NewNop() }

// --- fakeCatalogReader --------------------------------------------------

type fakeCatalogReader struct {
	mu            sync.Mutex
	batches       map[uuid.UUID]*CatalogBatch
	formatConfigs map[string]*CatalogFormatConfig
}

var _ CatalogReader = (*fakeCatalogReader)(nil)

func newFakeCatalogReader() *fakeCatalogReader {
	return &fakeCatalogReader{
		batches:       map[uuid.UUID]*CatalogBatch{},
		formatConfigs: map[string]*CatalogFormatConfig{},
	}
}

func formatCfgKey(courseID uuid.UUID, f EnrollmentFormat) string {
	return courseID.String() + "|" + string(f)
}

func (r *fakeCatalogReader) SeedBatch(b *CatalogBatch) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *b
	r.batches[b.ID] = &cp
}

func (r *fakeCatalogReader) SeedFormatConfig(courseID uuid.UUID, fc *CatalogFormatConfig) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *fc
	r.formatConfigs[formatCfgKey(courseID, fc.Format)] = &cp
}

func (r *fakeCatalogReader) GetBatch(_ context.Context, id uuid.UUID) (*CatalogBatch, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	b, ok := r.batches[id]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *b
	return &cp, nil
}

func (r *fakeCatalogReader) GetFormatConfig(_ context.Context, courseID uuid.UUID, f EnrollmentFormat) (*CatalogFormatConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cfg, ok := r.formatConfigs[formatCfgKey(courseID, f)]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *cfg
	return &cp, nil
}

func (r *fakeCatalogReader) CountEnrollments(_ context.Context, _ uuid.UUID, _ EnrollmentFormat) (int, error) {
	return 0, nil
}

// --- fakePartnershipsReader ---------------------------------------------

type fakePartnershipsReader struct {
	mu         sync.Mutex
	agreements map[uuid.UUID]*Agreement
}

var _ PartnershipsReader = (*fakePartnershipsReader)(nil)

func newFakePartnershipsReader() *fakePartnershipsReader {
	return &fakePartnershipsReader{agreements: map[uuid.UUID]*Agreement{}}
}

func (r *fakePartnershipsReader) SeedAgreement(a *Agreement) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *a
	r.agreements[a.PartnerID] = &cp
}

func (r *fakePartnershipsReader) GetActiveAgreement(_ context.Context, partnerID uuid.UUID) (*Agreement, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	a, ok := r.agreements[partnerID]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *a
	return &cp, nil
}

// --- fakeFinanceReader --------------------------------------------------

type debitRecord struct {
	CreditID     uuid.UUID
	Amount       decimal.Decimal
	EnrollmentID uuid.UUID
}

type fakeFinanceReader struct {
	mu      sync.Mutex
	credits map[uuid.UUID]*StudentCredit
	debits  []debitRecord
}

var _ FinanceReader = (*fakeFinanceReader)(nil)

func newFakeFinanceReader() *fakeFinanceReader {
	return &fakeFinanceReader{credits: map[uuid.UUID]*StudentCredit{}}
}

func (r *fakeFinanceReader) SeedCredit(c *StudentCredit) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *c
	r.credits[c.ID] = &cp
}

func (r *fakeFinanceReader) GetStudentCredit(_ context.Context, id uuid.UUID) (*StudentCredit, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	c, ok := r.credits[id]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	cp := *c
	return &cp, nil
}

func (r *fakeFinanceReader) DebitStudentCredit(_ context.Context, id uuid.UUID, amount decimal.Decimal, enrollID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	c, ok := r.credits[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	if amount.GreaterThan(c.Balance) {
		return apperrors.Validationf("insufficient credit balance")
	}
	c.Balance = c.Balance.Sub(amount)
	r.debits = append(r.debits, debitRecord{CreditID: id, Amount: amount, EnrollmentID: enrollID})
	return nil
}

func (r *fakeFinanceReader) Debits() []debitRecord {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]debitRecord, len(r.debits))
	copy(out, r.debits)
	return out
}
