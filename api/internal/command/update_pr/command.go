package update_pr

import "github.com/google/uuid"

type UpdatePrCommand struct {
	ID          uuid.UUID  `validate:"required"`
	Title       string
	Type        string
	ScheduledAt string
	MediaVenue  string
	PicID       *uuid.UUID
	PicName     string
	Status      string
	Notes       string
}
