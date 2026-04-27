package credentialing

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// seedVerifyFixture installs a certificate type, certificate row, and the
// matching cross-domain context on the fake catalog reader. It returns the
// certificate so individual tests can mutate fields (status, expires_at, etc).
func seedVerifyFixture(t *testing.T, repo *fakeCredRepo, cat *fakeCatalogReader, partnerName *string) *Certificate {
	t.Helper()
	ctx := context.Background()

	ct := &CertificateType{
		ID:        uuid.New(),
		Name:      "Vernon Edu Competence",
		Category:  CertVernonEduCompetence,
		IsActive:  true,
		CreatedBy: uuid.New(),
	}
	require.NoError(t, repo.CreateCertificateType(ctx, ct))

	enrollmentID := uuid.New()
	cert := &Certificate{
		ID:                  uuid.New(),
		EnrollmentID:        enrollmentID,
		CertificateTypeID:   ct.ID,
		CertificateConfigID: uuid.New(),
		CertificateNumber:   "VE-2026-00042",
		IssuedAt:            time.Now().UTC().Add(-30 * 24 * time.Hour),
		Status:              CertIssued,
	}
	require.NoError(t, repo.CreateCertificate(ctx, cert))

	cat.SeedCertContext(enrollmentID, &CertContextInfo{
		StudentName: "Alice Student",
		CourseTitle: "Intro to Things",
		PartnerName: partnerName,
	})

	return cert
}

func newVerifyService() (*Service, *fakeCredRepo, *fakeCatalogReader) {
	repo := newFakeCredRepo()
	cat := newFakeCatalogReader()
	svc := NewService(repo, newFakeBus(), testLogger(), cat)
	return svc, repo, cat
}

func TestVerify_ReturnsFullData(t *testing.T) {
	svc, repo, cat := newVerifyService()
	partner := "Acme Partner"
	cert := seedVerifyFixture(t, repo, cat, &partner)

	res, err := svc.Verify(context.Background(), cert.CertificateNumber)
	require.NoError(t, err)
	require.NotNil(t, res)

	require.Equal(t, cert.CertificateNumber, res.CertificateNumber)
	require.Equal(t, "Alice Student", res.StudentName)
	require.Equal(t, "Intro to Things", res.CourseTitle)
	require.Equal(t, "Vernon Edu Competence", res.CertificateType)
	require.NotNil(t, res.PartnerName)
	require.Equal(t, "Acme Partner", *res.PartnerName)
	require.Equal(t, cert.IssuedAt, res.IssuedAt)
	require.Equal(t, VerifyStatusIssued, res.Status)
	require.Nil(t, res.RevokedAt)
}

func TestVerify_DerivedExpired(t *testing.T) {
	svc, repo, cat := newVerifyService()
	cert := seedVerifyFixture(t, repo, cat, nil)

	// Mutate expires_at to a past date; status remains issued in the row.
	past := time.Now().UTC().Add(-24 * time.Hour)
	cert.ExpiresAt = &past

	res, err := svc.Verify(context.Background(), cert.CertificateNumber)
	require.NoError(t, err)
	require.Equal(t, VerifyStatusExpired, res.Status, "expired must be derived from expires_at < now")

	// Persisted row must still report issued (derived, not persisted).
	stored, err := repo.GetCertificateByNumber(context.Background(), cert.CertificateNumber)
	require.NoError(t, err)
	require.Equal(t, CertIssued, stored.Status)
}

func TestVerify_Revoked_StatusRevoked(t *testing.T) {
	svc, repo, cat := newVerifyService()
	cert := seedVerifyFixture(t, repo, cat, nil)

	revokedAt := time.Now().UTC().Add(-1 * time.Hour)
	cert.Status = CertRevoked
	cert.RevokedAt = &revokedAt

	res, err := svc.Verify(context.Background(), cert.CertificateNumber)
	require.NoError(t, err)
	require.Equal(t, VerifyStatusRevoked, res.Status)
	require.NotNil(t, res.RevokedAt)
	require.Equal(t, revokedAt, *res.RevokedAt)
}

func TestVerify_UnknownNumber_NotFound(t *testing.T) {
	svc, _, _ := newVerifyService()

	res, err := svc.Verify(context.Background(), "VE-2026-99999")
	require.Error(t, err)
	require.Nil(t, res)
	require.True(t, errors.Is(err, apperrors.ErrNotFound),
		"unknown cert number must return ErrNotFound, got %v", err)
}
