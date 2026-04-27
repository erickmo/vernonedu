package credentialing

import (
	"context"

	"github.com/google/uuid"
)

// CatalogReader exposes read-only catalog data the credentialing service needs
// when auto-issuing certificates on enrollment.completed. The listener resolves
// the course (id + title) from the batch carried by the event payload.
//
// Production wiring connects this to the catalog domain; tests use a fake.
// May be nil — handler treats absence as "skip auto-issue".
type CatalogReader interface {
	GetBatchCourse(ctx context.Context, batchID uuid.UUID) (courseID uuid.UUID, courseTitle string, err error)
	// ResolveCertContext returns the human-readable context for a certificate
	// associated with the given enrollment id: student name, course title, and
	// optional partner name. Used by the public verify endpoint to render
	// authoritative data without leaking internal identifiers.
	ResolveCertContext(ctx context.Context, enrollmentID uuid.UUID) (*CertContextInfo, error)
}

// CertContextInfo carries the cross-domain display data needed to render a
// public certificate verification response.
type CertContextInfo struct {
	StudentName string
	CourseTitle string
	PartnerName *string
}

// IdentityReader exposes read-only identity data that the credentialing
// service needs to gate certificate downloads. The download endpoint must
// confirm both ownership (caller is the certificate owner) and profile
// completion (the student has filled all required profile fields) before
// rendering a PDF.
//
// Production wiring connects this to the identity/student domain; tests use a
// fake. May be nil — handler treats absence as "download disabled".
type IdentityReader interface {
	// GetStudentForCertDownload resolves the student bound to an enrollment,
	// returning the user_id (for ownership check) and profile_complete flag
	// (for the gate).
	GetStudentForCertDownload(ctx context.Context, enrollmentID uuid.UUID) (*StudentDownloadInfo, error)

	// GetStudentByUserID resolves the student id for the given authenticated
	// user id. Used by the "list my certificates" endpoint to scope the query
	// to certificates belonging to the caller.
	GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*StudentRef, error)
}

// StudentRef carries the minimum identity reference needed by credentialing
// to scope queries to a single student.
type StudentRef struct {
	StudentID uuid.UUID
}

// StudentDownloadInfo carries the cross-domain identity data needed to
// authorize a certificate download.
type StudentDownloadInfo struct {
	StudentID       uuid.UUID
	UserID          uuid.UUID
	ProfileComplete bool
}
