package delete_room

import "github.com/google/uuid"

type DeleteRoomCommand struct {
	ID uuid.UUID `validate:"required"`
}
