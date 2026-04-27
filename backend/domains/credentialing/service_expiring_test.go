package credentialing

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

// seedCert inserts a certificate directly into the fake repo with the given
// expiry and status. Bypasses IssueCertificate so tests can construct
// out-of-window or revoked rows without relying on certificate type config.
func seedCert(t *testing.T, repo *fakeCredRepo, expiresAt *time.Time, status CertStatus) *Certificate {
	t.Helper()
	id := uuid.New()
	number := "VE-TEST-" + id.String()[:8]
	cert := &Certificate{
		ID:                  id,
		EnrollmentID:        uuid.New(),
		CertificateTypeID:   uuid.New(),
		CertificateConfigID: uuid.New(),
		CertificateNumber:   number,
		IssuedAt:            time.Now().UTC(),
		Status:              status,
		ExpiresAt:           expiresAt,
	}
	repo.certificates[cert.ID] = cert
	repo.certByNumber[cert.CertificateNumber] = cert
	return cert
}

func ptrTime(t time.Time) *time.Time { return &t }

func TestFlagExpiringCertificates_ReturnsCertsExpiringInWindow(t *testing.T) {
	svc, repo, _ := newIssueService()
	now := time.Now().UTC()

	cert1 := seedCert(t, repo, ptrTime(now.AddDate(0, 0, 15)), CertIssued) // INCLUDED
	_ = seedCert(t, repo, ptrTime(now.AddDate(0, 0, 60)), CertIssued)      // outside window
	_ = seedCert(t, repo, ptrTime(now.AddDate(0, 0, 10)), CertRevoked)     // revoked

	out, err := svc.FlagExpiringCertificates(context.Background(), 30)
	require.NoError(t, err)
	require.Len(t, out, 1)
	require.Equal(t, cert1.ID, out[0].ID)
}

func TestFlagExpiringCertificates_NoneInWindow_ReturnsEmpty(t *testing.T) {
	svc, repo, _ := newIssueService()
	now := time.Now().UTC()

	_ = seedCert(t, repo, ptrTime(now.AddDate(0, 0, 100)), CertIssued)
	_ = seedCert(t, repo, ptrTime(now.AddDate(0, 0, 200)), CertIssued)

	out, err := svc.FlagExpiringCertificates(context.Background(), 30)
	require.NoError(t, err)
	require.Empty(t, out)
}

func TestFlagExpiringCertificates_ZeroDays_NoCerts(t *testing.T) {
	svc, repo, _ := newIssueService()
	now := time.Now().UTC()
	_ = seedCert(t, repo, ptrTime(now.AddDate(0, 0, 5)), CertIssued)

	out, err := svc.FlagExpiringCertificates(context.Background(), 0)
	require.NoError(t, err)
	require.Empty(t, out)
}
