package list_rooms

type ListRoomsQuery struct {
	BuildingID string
	Offset     int
	Limit      int
}
