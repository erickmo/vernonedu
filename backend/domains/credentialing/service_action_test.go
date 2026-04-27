package credentialing

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// issueSeedCert issues a real certificate via the service so the cert is
// persisted in the fake repo with full state (number, status, expires_at).
func issueSeedCert(t *testing.T, svc *Service, repo *fakeCredRepo) *Certificate {
	t.Helper()
	twelve := 12
	configID := seedCertConfig(t, repo, &twelve)
	cert, err := svc.IssueCertificate(context.Background(), IssueCertificateInput{
		EnrollmentID:        uuid.New(),
		CertificateConfigID: configID,
		StudentID:           uuid.New(),
		CourseTitle:         "Course",
	})
	require.NoError(t, err)
	return cert
}

func TestRequestAction_Revoke_CreatesPending(t *testing.T) {
	svc, repo, _ := newIssueService()
	cert := issueSeedCert(t, svc, repo)
	requester := uuid.New()

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: cert.ID,
		Action:               ActionRevoke,
		Reason:               "issued in error",
		RequestedBy:          requester,
	})
	require.NoError(t, err)
	require.NotNil(t, req)
	require.Equal(t, ActionRevoke, req.Action)
	require.Equal(t, ActionPending, req.Status)
	require.Equal(t, cert.ID, req.StudentCertificateID)
	require.Equal(t, requester, req.RequestedBy)
}

func TestRequestAction_Reissue_CreatesPending(t *testing.T) {
	svc, repo, _ := newIssueService()
	cert := issueSeedCert(t, svc, repo)

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: cert.ID,
		Action:               ActionReissue,
		Reason:               "name correction",
		RequestedBy:          uuid.New(),
	})
	require.NoError(t, err)
	require.Equal(t, ActionReissue, req.Action)
	require.Equal(t, ActionPending, req.Status)
}

func TestApproveAction_Revoke_SetsCertRevoked(t *testing.T) {
	svc, repo, _ := newIssueService()
	cert := issueSeedCert(t, svc, repo)
	approver := uuid.New()

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: cert.ID,
		Action:               ActionRevoke,
		Reason:               "compliance",
		RequestedBy:          uuid.New(),
	})
	require.NoError(t, err)

	require.NoError(t, svc.ApproveAction(context.Background(), req.ID, approver))

	got, err := repo.GetCertificateByID(context.Background(), cert.ID)
	require.NoError(t, err)
	require.Equal(t, CertRevoked, got.Status)
	require.NotNil(t, got.RevokedAt)
	require.NotNil(t, got.RevokedBy)
	require.Equal(t, approver, *got.RevokedBy)

	gotReq, err := repo.GetActionRequestByID(context.Background(), req.ID)
	require.NoError(t, err)
	require.Equal(t, ActionApproved, gotReq.Status)
	require.NotNil(t, gotReq.ResolvedAt)
}

func TestApproveAction_Reissue_RevokesOldAndIssuesNew(t *testing.T) {
	svc, repo, _ := newIssueService()
	old := issueSeedCert(t, svc, repo)
	approver := uuid.New()

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: old.ID,
		Action:               ActionReissue,
		Reason:               "typo in name",
		RequestedBy:          uuid.New(),
	})
	require.NoError(t, err)

	require.NoError(t, svc.ApproveAction(context.Background(), req.ID, approver))

	gotOld, err := repo.GetCertificateByID(context.Background(), old.ID)
	require.NoError(t, err)
	require.Equal(t, CertRevoked, gotOld.Status)
	require.NotNil(t, gotOld.RevokedBy)

	// Find the new cert (same enrollment, different ID, reissued_from=old.ID)
	certs, err := repo.ListCertificatesByEnrollment(context.Background(), old.EnrollmentID)
	require.NoError(t, err)
	require.Len(t, certs, 2)

	var newCert *Certificate
	for _, c := range certs {
		if c.ID != old.ID {
			newCert = c
		}
	}
	require.NotNil(t, newCert, "new certificate must exist after reissue")
	require.Equal(t, CertIssued, newCert.Status)
	require.NotEqual(t, old.CertificateNumber, newCert.CertificateNumber)
	require.NotNil(t, newCert.ReissuedFrom)
	require.Equal(t, old.ID, *newCert.ReissuedFrom)
}

func TestRejectAction_RequestStatusRejected_CertUnchanged(t *testing.T) {
	svc, repo, _ := newIssueService()
	cert := issueSeedCert(t, svc, repo)

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: cert.ID,
		Action:               ActionRevoke,
		Reason:               "review",
		RequestedBy:          uuid.New(),
	})
	require.NoError(t, err)

	require.NoError(t, svc.RejectAction(context.Background(), req.ID, uuid.New()))

	gotReq, err := repo.GetActionRequestByID(context.Background(), req.ID)
	require.NoError(t, err)
	require.Equal(t, ActionRejected, gotReq.Status)

	gotCert, err := repo.GetCertificateByID(context.Background(), cert.ID)
	require.NoError(t, err)
	require.Equal(t, CertIssued, gotCert.Status)
	require.Nil(t, gotCert.RevokedAt)
	require.Nil(t, gotCert.RevokedBy)
}

func TestApproveAction_AlreadyResolved_Rejected(t *testing.T) {
	svc, repo, _ := newIssueService()
	cert := issueSeedCert(t, svc, repo)

	req, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: cert.ID,
		Action:               ActionRevoke,
		Reason:               "first",
		RequestedBy:          uuid.New(),
	})
	require.NoError(t, err)

	require.NoError(t, svc.ApproveAction(context.Background(), req.ID, uuid.New()))

	err = svc.ApproveAction(context.Background(), req.ID, uuid.New())
	require.Error(t, err, "second approval must error")
}

func TestRequestAction_NonexistentCert_Rejected(t *testing.T) {
	svc, _, _ := newIssueService()

	_, err := svc.RequestAction(context.Background(), RequestActionInput{
		StudentCertificateID: uuid.New(),
		Action:               ActionRevoke,
		Reason:               "x",
		RequestedBy:          uuid.New(),
	})
	require.Error(t, err)
	require.ErrorIs(t, err, apperrors.ErrNotFound)
}
