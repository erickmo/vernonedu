package room_test

import (
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
)

func TestNewRoom_Success(t *testing.T) {
	buildingID := uuid.New()
	cap := 30
	floor := "Lantai 2"
	facilities := []string{"projector", "whiteboard", "AC"}

	r, err := room.NewRoom(buildingID, "Ruang A101", &cap, &floor, facilities, "Ruang teori utama")
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if r.Name != "Ruang A101" {
		t.Errorf("expected name 'Ruang A101', got '%s'", r.Name)
	}
	if r.BuildingID != buildingID {
		t.Errorf("expected buildingID %s, got %s", buildingID, r.BuildingID)
	}
	if *r.Capacity != 30 {
		t.Errorf("expected capacity 30, got %d", *r.Capacity)
	}
	if *r.Floor != "Lantai 2" {
		t.Errorf("expected floor 'Lantai 2', got '%s'", *r.Floor)
	}
	if len(r.Facilities) != 3 {
		t.Errorf("expected 3 facilities, got %d", len(r.Facilities))
	}
}

func TestNewRoom_EmptyName(t *testing.T) {
	buildingID := uuid.New()
	_, err := room.NewRoom(buildingID, "", nil, nil, nil, "")
	if err == nil {
		t.Fatal("expected error for empty name, got nil")
	}
	if err != room.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got: %v", err)
	}
}

func TestNewRoom_NilFacilitiesDefaultsToEmpty(t *testing.T) {
	buildingID := uuid.New()
	r, err := room.NewRoom(buildingID, "Ruang B", nil, nil, nil, "")
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if r.Facilities == nil {
		t.Error("expected non-nil facilities slice")
	}
	if len(r.Facilities) != 0 {
		t.Errorf("expected empty facilities, got %d items", len(r.Facilities))
	}
}

func TestNewRoom_OptionalNilFields(t *testing.T) {
	buildingID := uuid.New()
	r, err := room.NewRoom(buildingID, "Ruang C", nil, nil, []string{}, "")
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if r.Capacity != nil {
		t.Error("expected nil capacity")
	}
	if r.Floor != nil {
		t.Error("expected nil floor")
	}
}

func TestNewRoom_IDIsUnique(t *testing.T) {
	buildingID := uuid.New()
	r1, _ := room.NewRoom(buildingID, "Ruang A", nil, nil, nil, "")
	r2, _ := room.NewRoom(buildingID, "Ruang B", nil, nil, nil, "")
	if r1.ID == r2.ID {
		t.Error("expected unique IDs for different rooms")
	}
}
