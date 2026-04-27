package credentialing

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

func TestCreateCertificateType_OK(t *testing.T) {
	svc, _, _ := newIssueService()
	creator := uuid.New()
	twelve := 12

	ct, err := svc.CreateCertificateType(context.Background(), CreateCertificateTypeInput{
		Name:           "Completion Certificate",
		Category:       CertVernonEduCompetence,
		ValidityMonths: &twelve,
		CreatedBy:      creator,
	})
	require.NoError(t, err)
	require.NotNil(t, ct)
	require.NotEqual(t, uuid.Nil, ct.ID)
	require.Equal(t, "Completion Certificate", ct.Name)
	require.True(t, ct.IsActive, "new certificate type must default to active")
	require.Equal(t, creator, ct.CreatedBy)
	require.NotNil(t, ct.ValidityMonths)
	require.Equal(t, 12, *ct.ValidityMonths)
}

func TestCreateCertificateType_ValidityNegative_Rejected(t *testing.T) {
	svc, _, _ := newIssueService()
	bad := -1

	_, err := svc.CreateCertificateType(context.Background(), CreateCertificateTypeInput{
		Name:           "Bad Cert",
		Category:       CertVernonEduCompetence,
		ValidityMonths: &bad,
		CreatedBy:      uuid.New(),
	})
	require.Error(t, err)

	zero := 0
	_, err = svc.CreateCertificateType(context.Background(), CreateCertificateTypeInput{
		Name:           "Bad Cert",
		Category:       CertVernonEduCompetence,
		ValidityMonths: &zero,
		CreatedBy:      uuid.New(),
	})
	require.Error(t, err)
}

func TestDeactivateCertificateType_SetsFlagFalse_ExistingCertsUnaffected(t *testing.T) {
	svc, repo, _ := newIssueService()

	// Issue a real cert via the service (this will create cert type + config + cert).
	cert := issueSeedCert(t, svc, repo)
	originalStatus := cert.Status

	// Find the underlying cert type (only one is seeded by issueSeedCert).
	var typeID uuid.UUID
	for id := range repo.certTypes {
		typeID = id
		break
	}
	require.NotEqual(t, uuid.Nil, typeID)

	require.NoError(t, svc.DeactivateCertificateType(context.Background(), typeID))

	ct, err := repo.GetCertificateTypeByID(context.Background(), typeID)
	require.NoError(t, err)
	require.False(t, ct.IsActive)

	// Existing certificate's status remains unchanged.
	got, err := repo.GetCertificateByID(context.Background(), cert.ID)
	require.NoError(t, err)
	require.Equal(t, originalStatus, got.Status)
}

func TestAddCertificateConfig_LinksCourseToType_OK(t *testing.T) {
	svc, _, _ := newIssueService()

	ct, err := svc.CreateCertificateType(context.Background(), CreateCertificateTypeInput{
		Name:      "Achievement",
		Category:  CertVernonEduCompetence,
		CreatedBy: uuid.New(),
	})
	require.NoError(t, err)

	courseID := uuid.New()
	cfg, err := svc.AddCertificateConfig(context.Background(), AddCertificateConfigInput{
		CourseID:          courseID,
		CertificateTypeID: ct.ID,
		IssuedOn:          IssuedOnCompletion,
	})
	require.NoError(t, err)
	require.NotNil(t, cfg)
	require.Equal(t, courseID, cfg.CourseID)
	require.Equal(t, ct.ID, cfg.CertificateTypeID)
	require.Equal(t, IssuedOnCompletion, cfg.IssuedOn)
}

func TestAddCertificateConfig_DuplicateCourseTypePair_Rejected(t *testing.T) {
	svc, _, _ := newIssueService()

	ct, err := svc.CreateCertificateType(context.Background(), CreateCertificateTypeInput{
		Name:      "Dup Cert",
		Category:  CertVernonEduCompetence,
		CreatedBy: uuid.New(),
	})
	require.NoError(t, err)
	courseID := uuid.New()

	_, err = svc.AddCertificateConfig(context.Background(), AddCertificateConfigInput{
		CourseID:          courseID,
		CertificateTypeID: ct.ID,
		IssuedOn:          IssuedOnCompletion,
	})
	require.NoError(t, err)

	_, err = svc.AddCertificateConfig(context.Background(), AddCertificateConfigInput{
		CourseID:          courseID,
		CertificateTypeID: ct.ID,
		IssuedOn:          IssuedOnManual,
	})
	require.Error(t, err)
	require.True(t, errors.Is(err, apperrors.ErrConflict), "expected ErrConflict, got %v", err)
}

func TestListCertificateConfigsByCourse_OK(t *testing.T) {
	svc, _, _ := newIssueService()
	ctx := context.Background()

	courseID := uuid.New()
	otherCourse := uuid.New()

	t1, err := svc.CreateCertificateType(ctx, CreateCertificateTypeInput{
		Name: "Type 1", Category: CertVernonEduCompetence, CreatedBy: uuid.New(),
	})
	require.NoError(t, err)
	t2, err := svc.CreateCertificateType(ctx, CreateCertificateTypeInput{
		Name: "Type 2", Category: CertVernonEduParticipation, CreatedBy: uuid.New(),
	})
	require.NoError(t, err)
	t3, err := svc.CreateCertificateType(ctx, CreateCertificateTypeInput{
		Name: "Type 3", Category: CertPartner, CreatedBy: uuid.New(),
	})
	require.NoError(t, err)

	_, err = svc.AddCertificateConfig(ctx, AddCertificateConfigInput{
		CourseID: courseID, CertificateTypeID: t1.ID, IssuedOn: IssuedOnCompletion,
	})
	require.NoError(t, err)
	_, err = svc.AddCertificateConfig(ctx, AddCertificateConfigInput{
		CourseID: courseID, CertificateTypeID: t2.ID, IssuedOn: IssuedOnManual,
	})
	require.NoError(t, err)
	_, err = svc.AddCertificateConfig(ctx, AddCertificateConfigInput{
		CourseID: otherCourse, CertificateTypeID: t3.ID, IssuedOn: IssuedOnCompletion,
	})
	require.NoError(t, err)

	got, err := svc.ListCertificateConfigsByCourse(ctx, courseID)
	require.NoError(t, err)
	require.Len(t, got, 2)
	for _, c := range got {
		require.Equal(t, courseID, c.CourseID)
	}
}
