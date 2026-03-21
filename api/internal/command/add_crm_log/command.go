package add_crm_log

import (
	"time"

	"github.com/google/uuid"
)

type AddCrmLogCommand struct {
	LeadID        uuid.UUID  `validate:"required"`
	ContactedByID uuid.UUID  `validate:"required"`
	ContactMethod string     `validate:"required"`
	Response      string     `validate:"required"`
	FollowUpDate  *time.Time
}
