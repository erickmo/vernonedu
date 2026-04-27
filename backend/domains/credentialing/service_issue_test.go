package credentialing

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// seedCertConfig inserts a certificate type and a config tied to it into the
// fake repo, returning the config id and the expected validity (months).
func seedCertConfig(t *testing.T, repo *fakeCredRepo, validityMonths *int) (configID uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	ct := &CertificateType{
		ID:             uuid.New(),
		Name:           "Test Cert",
		Category:       CertVernonEduCompetence,
		ValidityMonths: validityMonths,
		IsActive:       true,
		CreatedBy:      uuid.New(),
	}
	require.NoError(t, repo.CreateCertificateType(ctx, ct))

	cc := &CertificateConfig{
		ID:                uuid.New(),
		CourseID:          uuid.New(),
		CertificateTypeID: ct.ID,
		IssuedOn:          IssuedOnCompletion,
	}
	require.NoError(t, repo.CreateCertificateConfig(ctx, cc))
	return cc.ID
}

func newIssueService() (*Service, *fakeCredRepo, *fakeBus) {
	repo := newFakeCredRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), nil, nil)
	return svc, repo, bus
}

func TestIssueCertificate_CreatesIssuedRecord(t *testing.T) {
	svc, repo, _ := newIssueService()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)

	in := IssueCertificateInput{
		EnrollmentID:        uuid.New(),
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Intro to X",
	}
	cert, err := svc.IssueCertificate(context.Background(), in)
	require.NoError(t, err)
	require.NotNil(t, cert)

	require.False(t, cert.IssuedAt.IsZero(), "issued_at must be set")
	require.Equal(t, CertIssued, cert.Status)
	expected := fmt.Sprintf("VE-%d-00001", time.Now().UTC().Year())
	require.Equal(t, expected, cert.CertificateNumber)
}

func TestIssueCertificate_DerivesExpiresAtFromValidityMonths(t *testing.T) {
	svc, repo, _ := newIssueService()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)

	cert, err := svc.IssueCertificate(context.Background(), IssueCertificateInput{
		EnrollmentID:        uuid.New(),
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Course",
	})
	require.NoError(t, err)
	require.NotNil(t, cert.ExpiresAt)

	want := cert.IssuedAt.AddDate(0, 12, 0)
	// Allow a small delta because IssuedAt comes from the repo (DB-side now())
	// while in the fake it is set on insert. Within the fake repo IssuedAt
	// remains the zero value of time.Time after insert (it is RETURNING'd in
	// the real impl); compare against the expires_at directly.
	delta := cert.ExpiresAt.Sub(want)
	if delta < 0 {
		delta = -delta
	}
	require.LessOrEqual(t, delta, 2*time.Second, "expires_at should equal issued_at + 12 months")
}

func TestIssueCertificate_ValidityNull_ExpiresAtNull(t *testing.T) {
	svc, repo, _ := newIssueService()
	configID := seedCertConfig(t, repo, nil)

	cert, err := svc.IssueCertificate(context.Background(), IssueCertificateInput{
		EnrollmentID:        uuid.New(),
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Course",
	})
	require.NoError(t, err)
	require.Nil(t, cert.ExpiresAt, "expires_at must be nil when validity_months is nil")
}

func TestIssueCertificate_FiresEvent(t *testing.T) {
	svc, repo, bus := newIssueService()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)

	studentID := uuid.New()
	enrollmentID := uuid.New()
	cert, err := svc.IssueCertificate(context.Background(), IssueCertificateInput{
		EnrollmentID:        enrollmentID,
		CertificateConfigID: configID,
		StudentID:           studentID,
		CourseTitle:         "Advanced Topic",
	})
	require.NoError(t, err)

	require.True(t, bus.Fired(string(events.CertificateIssued)))
	last := bus.LastPayload(events.CertificateIssued)
	payload, ok := last.(events.CertificateIssuedPayload)
	require.True(t, ok, "expected canonical events.CertificateIssuedPayload, got %T", last)

	require.Equal(t, cert.ID, payload.CertificateID)
	require.Equal(t, cert.CertificateNumber, payload.CertificateNumber)
	require.Equal(t, studentID, payload.StudentID)
	require.Equal(t, enrollmentID, payload.EnrollmentID)
	require.Equal(t, "Advanced Topic", payload.CourseTitle)
}

func TestIssueCertificate_QRCodeURL_PointsToVerifyEndpoint(t *testing.T) {
	svc, repo, _ := newIssueService()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)

	cert, err := svc.IssueCertificate(context.Background(), IssueCertificateInput{
		EnrollmentID:        uuid.New(),
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Course",
	})
	require.NoError(t, err)
	require.NotNil(t, cert.QRCodeURL)
	require.Equal(t, "/cert/verify/"+cert.CertificateNumber, *cert.QRCodeURL)
}

func TestIssueCertificate_DuplicateEnrollmentConfig_Rejected(t *testing.T) {
	svc, repo, _ := newIssueService()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)

	enrollmentID := uuid.New()
	in := IssueCertificateInput{
		EnrollmentID:        enrollmentID,
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Course",
	}
	_, err := svc.IssueCertificate(context.Background(), in)
	require.NoError(t, err)

	_, err = svc.IssueCertificate(context.Background(), in)
	require.Error(t, err)
	require.True(t, errors.Is(err, apperrors.ErrConflict),
		"second issue with same (enrollment, config) must return ErrConflict, got %v", err)
}
