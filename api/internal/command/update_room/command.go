package update_room

import "github.com/google/uuid"

type UpdateRoomCommand struct {
	ID          uuid.UUID `validate:"required"`
	Name        string    `validate:"required"`
	Capacity    *int
	Floor       *string
	Facilities  []string
	Description string
}
