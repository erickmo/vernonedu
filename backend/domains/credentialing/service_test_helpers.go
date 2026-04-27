package credentialing

import (
	"context"
	"fmt"
	"sync"

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
	// Mirror the DB-level uq_student_cert_enrollment_config constraint.
	for _, existing := range r.certificates {
		if existing.EnrollmentID == c.EnrollmentID && existing.CertificateConfigID == c.CertificateConfigID {
			return apperrors.ErrConflict
		}
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
