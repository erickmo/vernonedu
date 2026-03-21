package delete_post

import "github.com/google/uuid"

type DeletePostCommand struct {
	ID uuid.UUID
}
