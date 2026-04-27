package credentialing

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// newListenerService returns a Service wired with a fake CatalogReader so
// AutoIssueOnCompletion can resolve the course from a batch id.
func newListenerService() (*Service, *fakeCredRepo, *fakeBus, *fakeCatalogReader) {
	repo := newFakeCredRepo()
	bus := newFakeBus()
	cat := newFakeCatalogReader()
	svc := NewService(repo, bus, testLogger(), cat, nil)
	return svc, repo, bus, cat
}

// seedTwoConfigsForCourse seeds two cert types plus two configs on the same
// course: one issued_on=completion, one issued_on=manual. Each config uses a
// distinct cert type to satisfy the DB-level UNIQUE (course_id,
// certificate_type_id) constraint. Returns the completion config id (the only
// one the listener should auto-issue).
func seedTwoConfigsForCourse(t *testing.T, repo *fakeCredRepo, courseID uuid.UUID) (completionConfigID uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	twelve := 12
	ctCompletion := &CertificateType{
		ID:             uuid.New(),
		Name:           "Auto Issue Cert (completion)",
		Category:       CertVernonEduCompetence,
		ValidityMonths: &twelve,
		IsActive:       true,
		CreatedBy:      uuid.New(),
	}
	require.NoError(t, repo.CreateCertificateType(ctx, ctCompletion))

	ctManual := &CertificateType{
		ID:             uuid.New(),
		Name:           "Auto Issue Cert (manual)",
		Category:       CertVernonEduParticipation,
		ValidityMonths: &twelve,
		IsActive:       true,
		CreatedBy:      uuid.New(),
	}
	require.NoError(t, repo.CreateCertificateType(ctx, ctManual))

	cfgCompletion := &CertificateConfig{
		ID:                uuid.New(),
		CourseID:          courseID,
		CertificateTypeID: ctCompletion.ID,
		IssuedOn:          IssuedOnCompletion,
	}
	require.NoError(t, repo.CreateCertificateConfig(ctx, cfgCompletion))

	cfgManual := &CertificateConfig{
		ID:                uuid.New(),
		CourseID:          courseID,
		CertificateTypeID: ctManual.ID,
		IssuedOn:          IssuedOnManual,
	}
	require.NoError(t, repo.CreateCertificateConfig(ctx, cfgManual))

	return cfgCompletion.ID
}

func TestOnEnrollmentCompleted_AutoIssuesCompletionConfigs(t *testing.T) {
	svc, repo, _, cat := newListenerService()

	courseID := uuid.New()
	batchID := uuid.New()
	enrollmentID := uuid.New()
	studentID := uuid.New()

	completionCfgID := seedTwoConfigsForCourse(t, repo, courseID)
	cat.SeedBatch(batchID, courseID, "Intro to Auto-Issue")

	err := svc.handleEnrollmentCompleted(context.Background(), events.Event{
		Type: events.EnrollmentCompleted,
		Payload: events.EnrollmentCompletedPayload{
			EnrollmentID: enrollmentID,
			StudentID:    studentID,
			BatchID:      batchID,
		},
	})
	require.NoError(t, err)

	certs, err := repo.ListCertificatesByEnrollment(context.Background(), enrollmentID)
	require.NoError(t, err)
	require.Len(t, certs, 1, "only completion config should auto-issue")
	require.Equal(t, completionCfgID, certs[0].CertificateConfigID)
}

func TestOnEnrollmentCompleted_NoConfigs_NoOp(t *testing.T) {
	svc, repo, _, cat := newListenerService()

	courseID := uuid.New()
	batchID := uuid.New()
	enrollmentID := uuid.New()

	cat.SeedBatch(batchID, courseID, "Empty Course")

	err := svc.handleEnrollmentCompleted(context.Background(), events.Event{
		Type: events.EnrollmentCompleted,
		Payload: events.EnrollmentCompletedPayload{
			EnrollmentID: enrollmentID,
			StudentID:    uuid.New(),
			BatchID:      batchID,
		},
	})
	require.NoError(t, err)

	certs, err := repo.ListCertificatesByEnrollment(context.Background(), enrollmentID)
	require.NoError(t, err)
	require.Len(t, certs, 0)
}

func TestOnEnrollmentCompleted_BadPayload_NoCrash(t *testing.T) {
	svc, _, _, _ := newListenerService()

	// Wrong payload type — handler must absorb and return nil.
	err := svc.handleEnrollmentCompleted(context.Background(), events.Event{
		Type:    events.EnrollmentCompleted,
		Payload: "not-a-payload",
	})
	require.NoError(t, err)

	// Nil payload — same.
	err = svc.handleEnrollmentCompleted(context.Background(), events.Event{
		Type:    events.EnrollmentCompleted,
		Payload: nil,
	})
	require.NoError(t, err)
}

func TestOnEnrollmentCompleted_AlreadyIssued_Idempotent(t *testing.T) {
	svc, repo, _, cat := newListenerService()

	courseID := uuid.New()
	batchID := uuid.New()
	enrollmentID := uuid.New()
	studentID := uuid.New()

	seedTwoConfigsForCourse(t, repo, courseID)
	cat.SeedBatch(batchID, courseID, "Idempotent Course")

	evt := events.Event{
		Type: events.EnrollmentCompleted,
		Payload: events.EnrollmentCompletedPayload{
			EnrollmentID: enrollmentID,
			StudentID:    studentID,
			BatchID:      batchID,
		},
	}
	require.NoError(t, svc.handleEnrollmentCompleted(context.Background(), evt))
	require.NoError(t, svc.handleEnrollmentCompleted(context.Background(), evt))

	certs, err := repo.ListCertificatesByEnrollment(context.Background(), enrollmentID)
	require.NoError(t, err)
	require.Len(t, certs, 1, "second firing must not duplicate the cert")
}
