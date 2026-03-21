package update_post

import "github.com/google/uuid"

type UpdatePostCommand struct {
	ID          uuid.UUID  `validate:"required"`
	Platforms   []string
	ScheduledAt string
	ContentType string
	Caption     string
	MediaURL    string
	BatchID     *uuid.UUID
	Status      string
}
