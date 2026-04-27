package platform

import (
	"time"

	"github.com/google/uuid"
)

// paymentDueWindow is the calendar block size for a payment_due event.
const paymentDueWindow = time.Hour

// zeroUUID is the canonical zero value used to detect optional UUID fields on payloads.
var zeroUUID = uuid.UUID{}

// parseDueDate accepts either RFC3339 or YYYY-MM-DD strings as used in payment payloads.
func parseDueDate(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t.UTC(), nil
	}
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		return time.Time{}, err
	}
	return t.UTC(), nil
}
