package building_test

import (
	"testing"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

func TestNewBuilding_Success(t *testing.T) {
	b, err := building.NewBuilding("Gedung A", "Jl. Contoh No. 1", "Gedung utama kampus", "self", nil)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if b.Name != "Gedung A" {
		t.Errorf("expected name 'Gedung A', got '%s'", b.Name)
	}
	if b.Address != "Jl. Contoh No. 1" {
		t.Errorf("expected address 'Jl. Contoh No. 1', got '%s'", b.Address)
	}
	if b.Description != "Gedung utama kampus" {
		t.Errorf("expected description 'Gedung utama kampus', got '%s'", b.Description)
	}
	if b.ID.String() == "" {
		t.Error("expected non-empty ID")
	}
}

func TestNewBuilding_EmptyName(t *testing.T) {
	_, err := building.NewBuilding("", "Jl. Contoh", "desc", "self", nil)
	if err == nil {
		t.Fatal("expected error for empty name, got nil")
	}
	if err != building.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got: %v", err)
	}
}

func TestNewBuilding_OptionalFields(t *testing.T) {
	b, err := building.NewBuilding("Gedung B", "", "", "self", nil)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if b.Address != "" {
		t.Errorf("expected empty address, got '%s'", b.Address)
	}
	if b.Description != "" {
		t.Errorf("expected empty description, got '%s'", b.Description)
	}
}

func TestNewBuilding_IDIsUnique(t *testing.T) {
	b1, _ := building.NewBuilding("Gedung A", "", "", "self", nil)
	b2, _ := building.NewBuilding("Gedung B", "", "", "self", nil)
	if b1.ID == b2.ID {
		t.Error("expected unique IDs for different buildings")
	}
}

func TestBuildingWithRooms_ZeroRooms(t *testing.T) {
	b := building.BuildingWithRooms{
		Building:      building.Building{Name: "Gedung A"},
		RoomCount:     0,
		TotalCapacity: 0,
		Rooms:         []building.RoomSummary{},
	}
	if b.RoomCount != 0 {
		t.Errorf("expected 0, got %d", b.RoomCount)
	}
	if len(b.Rooms) != 0 {
		t.Errorf("expected empty rooms, got %d", len(b.Rooms))
	}
}

func TestBuildingWithRooms_WithRooms(t *testing.T) {
	id := uuid.New()
	b := building.BuildingWithRooms{
		Building:      building.Building{Name: "Gedung B"},
		RoomCount:     2,
		TotalCapacity: 40,
		Rooms: []building.RoomSummary{
			{ID: id, Name: "R.101", Capacity: 20},
			{ID: uuid.New(), Name: "R.102", Capacity: 20},
		},
	}
	if b.RoomCount != 2 {
		t.Errorf("expected 2, got %d", b.RoomCount)
	}
	if b.TotalCapacity != 40 {
		t.Errorf("expected 40, got %d", b.TotalCapacity)
	}
	if b.Rooms[0].Name != "R.101" {
		t.Errorf("expected R.101, got %s", b.Rooms[0].Name)
	}
}
