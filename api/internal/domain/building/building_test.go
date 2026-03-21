package building_test

import (
	"testing"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

func TestNewBuilding_Success(t *testing.T) {
	b, err := building.NewBuilding("Gedung A", "Jl. Contoh No. 1", "Gedung utama kampus")
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
	_, err := building.NewBuilding("", "Jl. Contoh", "desc")
	if err == nil {
		t.Fatal("expected error for empty name, got nil")
	}
	if err != building.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got: %v", err)
	}
}

func TestNewBuilding_OptionalFields(t *testing.T) {
	b, err := building.NewBuilding("Gedung B", "", "")
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
	b1, _ := building.NewBuilding("Gedung A", "", "")
	b2, _ := building.NewBuilding("Gedung B", "", "")
	if b1.ID == b2.ID {
		t.Error("expected unique IDs for different buildings")
	}
}
