package list_buildings_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_buildings"
)

type mockBuildingRepo struct {
	listWithRoomsFunc func(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error)
	getByIDFunc       func(ctx context.Context, id uuid.UUID) (*building.Building, error)
}

func (m *mockBuildingRepo) GetByID(ctx context.Context, id uuid.UUID) (*building.Building, error) {
	if m.getByIDFunc != nil {
		return m.getByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *mockBuildingRepo) List(ctx context.Context, offset, limit int) ([]*building.Building, int, error) {
	return nil, 0, nil
}

func (m *mockBuildingRepo) ListWithRooms(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
	if m.listWithRoomsFunc != nil {
		return m.listWithRoomsFunc(ctx, offset, limit, search)
	}
	return nil, 0, nil
}

func (m *mockBuildingRepo) GetByIDWithPartner(ctx context.Context, id uuid.UUID) (*building.BuildingWithPartner, error) {
	return nil, nil
}

func TestHandle_ValidQuery_ReturnsBuildingsWithRooms(t *testing.T) {
	id := uuid.New()
	roomID := uuid.New()
	now := time.Now()

	repo := &mockBuildingRepo{
		listWithRoomsFunc: func(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
			return []building.BuildingWithRooms{
				{
					Building: building.Building{
						ID:        id,
						Name:      "Gedung A",
						Address:   "Jl. Test",
						CreatedAt: now,
						UpdatedAt: now,
					},
					RoomCount:     1,
					TotalCapacity: 20,
					Rooms: []building.RoomSummary{
						{ID: roomID, Name: "R.101", Capacity: 20},
					},
				},
			}, 1, nil
		},
	}

	h := list_buildings.NewHandler(repo)
	result, err := h.Handle(context.Background(), &list_buildings.ListBuildingsQuery{
		Offset: 0,
		Limit:  10,
		Search: "",
	})

	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	res, ok := result.(*list_buildings.ListBuildingsResult)
	if !ok {
		t.Fatal("expected *ListBuildingsResult")
	}
	if res.Total != 1 {
		t.Errorf("expected total 1, got %d", res.Total)
	}
	if len(res.Data) != 1 {
		t.Fatalf("expected 1 item, got %d", len(res.Data))
	}
	item := res.Data[0]
	if item.Name != "Gedung A" {
		t.Errorf("expected Gedung A, got %s", item.Name)
	}
	if item.RoomCount != 1 {
		t.Errorf("expected RoomCount 1, got %d", item.RoomCount)
	}
	if item.TotalCapacity != 20 {
		t.Errorf("expected TotalCapacity 20, got %d", item.TotalCapacity)
	}
	if len(item.Rooms) != 1 {
		t.Fatalf("expected 1 room, got %d", len(item.Rooms))
	}
	if item.Rooms[0].Name != "R.101" {
		t.Errorf("expected R.101, got %s", item.Rooms[0].Name)
	}
	if item.Rooms[0].ID != roomID.String() {
		t.Errorf("expected room ID %s, got %s", roomID.String(), item.Rooms[0].ID)
	}
}

func TestHandle_InvalidQueryType_ReturnsError(t *testing.T) {
	h := list_buildings.NewHandler(&mockBuildingRepo{})
	_, err := h.Handle(context.Background(), "not a query")
	if err == nil {
		t.Fatal("expected error for invalid query type")
	}
	if !errors.Is(err, list_buildings.ErrInvalidQuery) {
		t.Errorf("expected ErrInvalidQuery, got: %v", err)
	}
}

func TestHandle_RepositoryError_PropagatesError(t *testing.T) {
	repoErr := errors.New("db connection failed")
	repo := &mockBuildingRepo{
		listWithRoomsFunc: func(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
			return nil, 0, repoErr
		},
	}
	h := list_buildings.NewHandler(repo)
	_, err := h.Handle(context.Background(), &list_buildings.ListBuildingsQuery{Limit: 10})
	if err == nil {
		t.Fatal("expected error from repository")
	}
	if !errors.Is(err, repoErr) {
		t.Errorf("expected repoErr, got: %v", err)
	}
}

func TestHandle_ZeroLimit_UsesDefault20(t *testing.T) {
	var capturedLimit int
	repo := &mockBuildingRepo{
		listWithRoomsFunc: func(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
			capturedLimit = limit
			return nil, 0, nil
		},
	}
	h := list_buildings.NewHandler(repo)
	_, err := h.Handle(context.Background(), &list_buildings.ListBuildingsQuery{Limit: 0})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if capturedLimit != 20 {
		t.Errorf("expected default limit 20, got %d", capturedLimit)
	}
}
