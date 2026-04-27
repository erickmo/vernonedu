package credentialing

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// newDownloadService wires a Service with a fake IdentityReader so the
// download gate (ownership + profile completion) can be exercised end-to-end.
func newDownloadService() (*Service, *fakeCredRepo, *fakeIdentityReader) {
	repo := newFakeCredRepo()
	id := newFakeIdentityReader()
	svc := NewService(repo, newFakeBus(), testLogger(), nil, id)
	return svc, repo, id
}

// seedDownloadCert installs a minimal certificate row directly via the fake
// repo. It bypasses IssueCertificate to keep download tests focused on the
// gate, not on issuance side effects.
func seedDownloadCert(t *testing.T, repo *fakeCredRepo) *Certificate {
	t.Helper()
	cert := &Certificate{
		ID:                  uuid.New(),
		EnrollmentID:        uuid.New(),
		CertificateTypeID:   uuid.New(),
		CertificateConfigID: uuid.New(),
		CertificateNumber:   "VE-2026-00777",
		Status:              CertIssued,
	}
	require.NoError(t, repo.CreateCertificate(context.Background(), cert))
	return cert
}

func TestDownload_ProfileNotComplete_403(t *testing.T) {
	svc, repo, id := newDownloadService()
	cert := seedDownloadCert(t, repo)
	userID := uuid.New()
	id.Seed(cert.EnrollmentID, &StudentDownloadInfo{
		StudentID:       uuid.New(),
		UserID:          userID,
		ProfileComplete: false,
	})

	_, err := svc.DownloadCertificate(context.Background(), cert.ID, userID)
	require.Error(t, err)
	require.True(t, errors.Is(err, apperrors.ErrForbidden),
		"profile_complete=false must yield ErrForbidden, got %v", err)
}

func TestDownload_ProfileComplete_ReturnsPDFStub(t *testing.T) {
	svc, repo, id := newDownloadService()
	cert := seedDownloadCert(t, repo)
	userID := uuid.New()
	id.Seed(cert.EnrollmentID, &StudentDownloadInfo{
		StudentID:       uuid.New(),
		UserID:          userID,
		ProfileComplete: true,
	})

	res, err := svc.DownloadCertificate(context.Background(), cert.ID, userID)
	require.NoError(t, err)
	require.NotNil(t, res)
	require.Equal(t, cert.CertificateNumber+".pdf", res.Filename)
	require.NotEmpty(t, res.Content, "stub PDF body must be non-empty")
}

func TestDownload_StudentNotFound_404(t *testing.T) {
	svc, repo, _ := newDownloadService()
	cert := seedDownloadCert(t, repo)

	// Identity reader has no mapping for this enrollment.
	_, err := svc.DownloadCertificate(context.Background(), cert.ID, uuid.New())
	require.Error(t, err)
	require.True(t, errors.Is(err, apperrors.ErrNotFound),
		"missing student mapping must yield ErrNotFound, got %v", err)
}

func TestDownload_CertificateNotFound_404(t *testing.T) {
	svc, _, _ := newDownloadService()

	_, err := svc.DownloadCertificate(context.Background(), uuid.New(), uuid.New())
	require.Error(t, err)
	require.True(t, errors.Is(err, apperrors.ErrNotFound),
		"unknown certificate id must yield ErrNotFound, got %v", err)
}
