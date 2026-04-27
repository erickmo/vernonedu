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
}
