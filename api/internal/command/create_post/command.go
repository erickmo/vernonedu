package create_post

import "github.com/google/uuid"

type CreatePostCommand struct {
	Platforms   []string   `validate:"required,min=1"`
	ScheduledAt string     `validate:"required"` // RFC3339
	ContentType string     `validate:"required"`
	Caption     string
	MediaURL    string
	BatchID     *uuid.UUID
	CreatedBy   uuid.UUID
}
