package credentialing

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// fakeCredRepo is an in-memory Repository implementation for service tests.
type fakeCredRepo struct {
	mu           sync.Mutex
	seqs         map[int]int // year -> last_value
	certTypes    map[uuid.UUID]*CertificateType
	certConfigs  map[uuid.UUID]*CertificateConfig
	certificates map[uuid.UUID]*Certificate
	certByNumber map[string]*Certificate
	actionReqs   map[uuid.UUID]*CertificateActionRequest
}

var _ Repository = (*fakeCredRepo)(nil)

func newFakeCredRepo() *fakeCredRepo {
	return &fakeCredRepo{
		seqs:         map[int]int{},
		certTypes:    map[uuid.UUID]*CertificateType{},
		certConfigs:  map[uuid.UUID]*CertificateConfig{},
		certificates: map[uuid.UUID]*Certificate{},
		certByNumber: map[string]*Certificate{},
		actionReqs:   map[uuid.UUID]*CertificateActionRequest{},
	}
}

func (r *fakeCredRepo) NextCertificateNumber(ctx context.Context, year int) (string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.seqs[year]++
	return fmt.Sprintf("VE-%d-%05d", year, r.seqs[year]), nil
}

func (r *fakeCredRepo) CreateCertificateType(ctx context.Context, ct *CertificateType) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.certTypes[ct.ID] = ct
	return nil
}

func (r *fakeCredRepo) GetCertificateTypeByID(ctx context.Context, id uuid.UUID) (*CertificateType, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if ct, ok := r.certTypes[id]; ok {
		return ct, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCredRepo) ListActiveCertificateTypes(ctx context.Context) ([]*CertificateType, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]*CertificateType, 0, len(r.certTypes))
	for _, ct := range r.certTypes {
		if ct.IsActive {
			out = append(out, ct)
		}
	}
	return out, nil
}

func (r *fakeCredRepo) CreateCertificateConfig(ctx context.Context, cc *CertificateConfig) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.certConfigs[cc.ID] = cc
	return nil
}

func (r *fakeCredRepo) GetCertificateConfigByID(ctx context.Context, id uuid.UUID) (*CertificateConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if cc, ok := r.certConfigs[id]; ok {
		return cc, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCredRepo) GetCertificateConfigByCourse(ctx context.Context, courseID uuid.UUID) ([]*CertificateConfig, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := []*CertificateConfig{}
	for _, cc := range r.certConfigs {
		if cc.CourseID == courseID {
			out = append(out, cc)
		}
	}
	return out, nil
}

func (r *fakeCredRepo) CreateCertificate(ctx context.Context, c *Certificate) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	// Mirror the DB-level partial unique index uq_student_cert_active:
	// at most one non-revoked row per (enrollment_id, certificate_config_id).
	for _, existing := range r.certificates {
		if existing.EnrollmentID == c.EnrollmentID &&
			existing.CertificateConfigID == c.CertificateConfigID &&
			existing.Status != CertRevoked {
			return apperrors.ErrConflict
		}
	}
	if c.IssuedAt.IsZero() {
		c.IssuedAt = time.Now().UTC()
	}
	r.certificates[c.ID] = c
	r.certByNumber[c.CertificateNumber] = c
	return nil
}

func (r *fakeCredRepo) GetCertificateByID(ctx context.Context, id uuid.UUID) (*Certificate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if c, ok := r.certificates[id]; ok {
		return c, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCredRepo) GetCertificateByNumber(ctx context.Context, number string) (*Certificate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if c, ok := r.certByNumber[number]; ok {
		return c, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCredRepo) UpdateCertificateStatus(ctx context.Context, id uuid.UUID, status CertStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	c, ok := r.certificates[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	c.Status = status
	return nil
}

func (r *fakeCredRepo) ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := []*Certificate{}
	for _, c := range r.certificates {
		if c.EnrollmentID == enrollmentID {
			out = append(out, c)
		}
	}
	return out, nil
}

func (r *fakeCredRepo) ListExpiringCertificates(ctx context.Context, days int) ([]*Certificate, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now().UTC()
	cutoff := now.AddDate(0, 0, days)
	out := []*Certificate{}
	for _, c := range r.certificates {
		if c.Status != CertIssued {
			continue
		}
		if c.ExpiresAt == nil {
			continue
		}
		if c.ExpiresAt.Before(now) || c.ExpiresAt.After(cutoff) {
			continue
		}
		out = append(out, c)
	}
	return out, nil
}

func (r *fakeCredRepo) CreateActionRequest(ctx context.Context, req *CertificateActionRequest) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.actionReqs[req.ID] = req
	return nil
}

func (r *fakeCredRepo) GetActionRequestByID(ctx context.Context, id uuid.UUID) (*CertificateActionRequest, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if req, ok := r.actionReqs[id]; ok {
		return req, nil
	}
	return nil, apperrors.ErrNotFound
}

func (r *fakeCredRepo) UpdateActionRequestStatus(ctx context.Context, id uuid.UUID, status ActionStatus, approvedBy *uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	req, ok := r.actionReqs[id]
	if !ok {
		return apperrors.ErrNotFound
	}
	req.Status = status
	req.ApprovedBy = approvedBy
	now := time.Now().UTC()
	req.ResolvedAt = &now
	req.UpdatedAt = now
	return nil
}

func (r *fakeCredRepo) RevokeCertificate(ctx context.Context, certID, revokerID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	c, ok := r.certificates[certID]
	if !ok {
		return apperrors.ErrNotFound
	}
	now := time.Now().UTC()
	c.Status = CertRevoked
	c.RevokedAt = &now
	revoker := revokerID
	c.RevokedBy = &revoker
	c.UpdatedAt = now
	return nil
}

func (r *fakeCredRepo) ReissueCertificate(ctx context.Context, oldCertID, approverID uuid.UUID) (*Certificate, error) {
	r.mu.Lock()
	old, ok := r.certificates[oldCertID]
	if !ok {
		r.mu.Unlock()
		return nil, apperrors.ErrNotFound
	}
	// Revoke old
	now := time.Now().UTC()
	old.Status = CertRevoked
	old.RevokedAt = &now
	revoker := approverID
	old.RevokedBy = &revoker
	old.UpdatedAt = now

	// Allocate new number
	year := now.Year()
	r.seqs[year]++
	number := fmt.Sprintf("VE-%d-%05d", year, r.seqs[year])
	qrURL := verifyEndpointPrefix + number

	newCert := &Certificate{
		ID:                  uuid.New(),
		EnrollmentID:        old.EnrollmentID,
		CertificateTypeID:   old.CertificateTypeID,
		CertificateConfigID: old.CertificateConfigID,
		CertificateNumber:   number,
		IssuedAt:            now,
		Status:              CertIssued,
		QRCodeURL:           &qrURL,
		ExpiresAt:           old.ExpiresAt,
		ReissuedFrom:        &oldCertID,
		CreatedAt:           now,
		UpdatedAt:           now,
	}
	r.certificates[newCert.ID] = newCert
	r.certByNumber[newCert.CertificateNumber] = newCert
	r.mu.Unlock()
	return newCert, nil
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

func (b *fakeBus) LastPayload(typ events.EventType) any {
	b.mu.Lock()
	defer b.mu.Unlock()
	list := b.payloads[typ]
	if len(list) == 0 {
		return nil
	}
	return list[len(list)-1]
}

func (b *fakeBus) Fired(typ string) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.fired[events.EventType(typ)] > 0
}

func testLogger() *zap.Logger { return zap.NewNop() }

// fakeCatalogReader is an in-memory CatalogReader for credentialing tests.
type fakeCatalogReader struct {
	mu          sync.Mutex
	batches     map[uuid.UUID]fakeCatalogBatch
	certContext map[uuid.UUID]*CertContextInfo
}

type fakeCatalogBatch struct {
	CourseID uuid.UUID
	Title    string
}

var _ CatalogReader = (*fakeCatalogReader)(nil)

func newFakeCatalogReader() *fakeCatalogReader {
	return &fakeCatalogReader{
		batches:     map[uuid.UUID]fakeCatalogBatch{},
		certContext: map[uuid.UUID]*CertContextInfo{},
	}
}

// SeedCertContext registers an enrollment -> cert-context mapping used by the
// public verify endpoint.
func (r *fakeCatalogReader) SeedCertContext(enrollmentID uuid.UUID, info *CertContextInfo) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.certContext[enrollmentID] = info
}

func (r *fakeCatalogReader) ResolveCertContext(_ context.Context, enrollmentID uuid.UUID) (*CertContextInfo, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	info, ok := r.certContext[enrollmentID]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	return info, nil
}

// SeedBatch registers a batch -> course mapping with its course title.
func (r *fakeCatalogReader) SeedBatch(batchID, courseID uuid.UUID, title string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.batches[batchID] = fakeCatalogBatch{CourseID: courseID, Title: title}
}

func (r *fakeCatalogReader) GetBatchCourse(_ context.Context, batchID uuid.UUID) (uuid.UUID, string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	b, ok := r.batches[batchID]
	if !ok {
		return uuid.Nil, "", apperrors.ErrNotFound
	}
	return b.CourseID, b.Title, nil
}

// fakeIdentityReader is an in-memory IdentityReader for credentialing tests.
// It maps an enrollment id to the student/user info needed by the download
// gate (ownership check + profile completion flag).
type fakeIdentityReader struct {
	mu       sync.Mutex
	students map[uuid.UUID]*StudentDownloadInfo // keyed by enrollmentID
}

var _ IdentityReader = (*fakeIdentityReader)(nil)

func newFakeIdentityReader() *fakeIdentityReader {
	return &fakeIdentityReader{
		students: map[uuid.UUID]*StudentDownloadInfo{},
	}
}

// Seed registers an enrollment -> student/user/profile-complete mapping.
func (r *fakeIdentityReader) Seed(enrollmentID uuid.UUID, info *StudentDownloadInfo) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.students[enrollmentID] = info
}

func (r *fakeIdentityReader) GetStudentForCertDownload(_ context.Context, enrollmentID uuid.UUID) (*StudentDownloadInfo, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	info, ok := r.students[enrollmentID]
	if !ok {
		return nil, apperrors.ErrNotFound
	}
	return info, nil
}
