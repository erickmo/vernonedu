package create_pr

import "github.com/google/uuid"

type CreatePrCommand struct {
	Title       string     `validate:"required"`
	Type        string     `validate:"required"`
	ScheduledAt string     `validate:"required"`
	MediaVenue  string
	PicID       *uuid.UUID
	PicName     string
	Notes       string
}
