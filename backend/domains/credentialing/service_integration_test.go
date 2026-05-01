//go:build integration

package credentialing_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"github.com/vernonedu/vernonedu2/backend/domains/enrollment"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/worker"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	// Use a single TRUNCATE with the broadest reasonable set; CASCADE drops
	// dependents in finance/partnerships/platform automatically.
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			credentialing.certificate_action_requests,
			credentialing.student_certificates,
			credentialing.certificate_configs,
			credentialing.certificate_types,
			catalog.course_batches,
			catalog.courses,
			identity.students,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

type credFixture struct {
	creatorID    uuid.UUID
	studentID    uuid.UUID
	enrollmentID uuid.UUID
	configID     uuid.UUID
	typeID       uuid.UUID
}

func seedCredFixture(t *testing.T, pool *pgxpool.Pool) credFixture {
	t.Helper()
	ctx := context.Background()
	var f credFixture

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin@t.local','x','course_creator')
		RETURNING id`).Scan(&f.creatorID))

	var studentUserID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('s@t.local','x','student')
		RETURNING id`).Scan(&studentUserID))

	var deptID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('Dept', $1, $1) RETURNING id`, f.creatorID).Scan(&deptID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.students (user_id, name, email, phone, source)
		VALUES ($1, 'Jane Doe', 's@t.local', '08', 'b2c') RETURNING id`,
		studentUserID).Scan(&f.studentID))

	var courseID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.courses (name, department_id, course_creator_id, base_price, min_price, created_by)
		VALUES ('Intro to Go', $1, $2, 1000000, 800000, $2) RETURNING id`,
		deptID, f.creatorID).Scan(&courseID))

	var batchID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'B1', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2) RETURNING id`,
		courseID, f.creatorID).Scan(&batchID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO enrollment.enrollments
		  (student_id, course_batch_id, format, mode, payer, price, final_price, source)
		VALUES ($1, $2, 'regular', 'online', 'student', 1200000, 1200000, 'b2c')
		RETURNING id`, f.studentID, batchID).Scan(&f.enrollmentID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO credentialing.certificate_types (name, category, is_active, created_by)
		VALUES ('Completion', 'vernonedu_competence', TRUE, $1) RETURNING id`,
		f.creatorID).Scan(&f.typeID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO credentialing.certificate_configs (course_id, certificate_type_id, issued_on)
		VALUES ($1, $2, 'completion') RETURNING id`,
		courseID, f.typeID).Scan(&f.configID))

	return f
}

func newCredService(t *testing.T, pool *pgxpool.Pool, storageRoot string) (*credentialing.Service, events.Bus) {
	t.Helper()
	log := zap.NewNop()
	bus := events.NewBus(log)
	repo := credentialing.NewRepository(pool)
	pdfGen := worker.NewRendererAdapter(worker.NewPDFGenerator())
	storage := worker.NewStorageAdapter(worker.NewFSCertStorage(storageRoot))
	svc := credentialing.NewService(repo, bus, log, pdfGen, storage, "http://localhost:8080")
	credentialing.RegisterSubscriptions(bus, svc, log)
	return svc, bus
}

func TestIssueForEnrollment_GeneratesPDFAndPersistsHash(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedCredFixture(t, pool)

	storageRoot := t.TempDir()
	svc, _ := newCredService(t, pool, storageRoot)

	cert, err := svc.IssueForEnrollment(context.Background(), f.enrollmentID)
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, cert.ID)
	require.Equal(t, credentialing.CertIssued, cert.Status)
	require.NotNil(t, cert.PDFPath)
	require.NotNil(t, cert.PDFHash)
	require.Len(t, *cert.PDFHash, 64) // sha256 hex

	// File on disk
	info, err := os.Stat(*cert.PDFPath)
	require.NoError(t, err)
	require.Greater(t, info.Size(), int64(100))
	require.Equal(t, storageRoot, filepath.Dir(*cert.PDFPath))
}

func TestIssueForEnrollment_Idempotent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedCredFixture(t, pool)

	svc, _ := newCredService(t, pool, t.TempDir())
	ctx := context.Background()

	first, err := svc.IssueForEnrollment(ctx, f.enrollmentID)
	require.NoError(t, err)

	second, err := svc.IssueForEnrollment(ctx, f.enrollmentID)
	require.NoError(t, err)
	require.Equal(t, first.ID, second.ID, "duplicate issuance must return same cert")
}

func TestVerifyByHash_ReturnsCertWhenValid(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedCredFixture(t, pool)

	svc, _ := newCredService(t, pool, t.TempDir())
	ctx := context.Background()

	cert, err := svc.IssueForEnrollment(ctx, f.enrollmentID)
	require.NoError(t, err)
	require.NotNil(t, cert.PDFHash)

	res, err := svc.VerifyByHash(ctx, *cert.PDFHash)
	require.NoError(t, err)
	require.True(t, res.Valid)
	require.Equal(t, cert.ID, res.CertificateID)
	require.Equal(t, "Jane Doe", res.StudentName)
	require.Equal(t, "Intro to Go", res.CourseName)
}

func TestVerifyByHash_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	_ = seedCredFixture(t, pool)

	svc, _ := newCredService(t, pool, t.TempDir())
	_, err := svc.VerifyByHash(context.Background(), "0000000000000000000000000000000000000000000000000000000000000000")
	require.Error(t, err)
}

func TestEnrollmentCompletedEvent_TriggersIssuance(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedCredFixture(t, pool)

	svc, bus := newCredService(t, pool, t.TempDir())

	err := bus.Publish(context.Background(), events.Event{
		Type:    events.EnrollmentCompleted,
		Payload: enrollment.EnrollmentCompletedPayload{EnrollmentID: f.enrollmentID},
	})
	require.NoError(t, err)

	// Subscription is async (goroutine). Poll up to ~2s.
	deadline := time.Now().Add(2 * time.Second)
	var got *credentialing.Certificate
	for time.Now().Before(deadline) {
		certs, _ := svc.ListCertificatesByEnrollment(context.Background(), f.enrollmentID)
		if len(certs) == 1 && certs[0].PDFHash != nil {
			got = certs[0]
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	require.NotNil(t, got, "certificate not issued from event")
	require.NotNil(t, got.PDFHash)
	require.Equal(t, credentialing.CertIssued, got.Status)
}
