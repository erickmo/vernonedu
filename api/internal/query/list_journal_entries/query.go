package list_journal_entries

import (
	"time"

	"github.com/google/uuid"
)

type ListJournalEntriesQuery struct {
	Offset    int
	Limit     int
	Source    string
	AccountID *uuid.UUID
	DateFrom  *time.Time
	DateTo    *time.Time
}
