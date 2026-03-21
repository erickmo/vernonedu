package check_room_availability

import (
	"time"

	"github.com/google/uuid"
)

type CheckRoomAvailabilityQuery struct {
	RoomID uuid.UUID
	From   time.Time
	To     time.Time
}
