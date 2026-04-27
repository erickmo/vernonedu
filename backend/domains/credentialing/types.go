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
