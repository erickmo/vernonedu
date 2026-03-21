package create_room_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	create_room "github.com/vernonedu/entrepreneurship-api/internal/command/create_room"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ─── Fakes ───────────────────────────────────────────────────────────────────

type fakeRoomWriteRepo struct {
	savedRoom *room.Room
	saveErr   error
}

func (f *fakeRoomWriteRepo) Save(_ context.Context, r *room.Room) error {
	f.savedRoom = r
	return f.saveErr
}
func (f *fakeRoomWriteRepo) Update(_ context.Context, _ *room.Room) error { return nil }
func (f *fakeRoomWriteRepo) Delete(_ context.Context, _ uuid.UUID) error  { return nil }
func (f *fakeRoomWriteRepo) GetByID(_ context.Context, _ uuid.UUID) (*room.Room, error) {
	return nil, nil
}
func (f *fakeRoomWriteRepo) List(_ context.Context, _ string, _, _ int) ([]*room.Room, int, error) {
	return nil, 0, nil
}
func (f *fakeRoomWriteRepo) CheckAvailability(_ context.Context, _ uuid.UUID, _, _ time.Time) ([]*room.ScheduleConflict, error) {
	return nil, nil
}

type fakeEventBus struct{ published int }

func (f *fakeEventBus) Publish(_ context.Context, _ eventbus.DomainEvent) error {
	f.published++
	return nil
}
func (f *fakeEventBus) Subscribe(_ context.Context, _ string, _ eventbus.MessageHandler) error {
	return nil
}
func (f *fakeEventBus) Close() error { return nil }

// ─── Tests ────────────────────────────────────────────────────────────────────

func TestCreateRoomHandler_Success(t *testing.T) {
	repo := &fakeRoomWriteRepo{}
	bus := &fakeEventBus{}
	h := create_room.NewHandler(repo, bus)

	buildingID := uuid.New()
	cap := 25
	floor := "Lantai 1"
	cmd := &create_room.CreateRoomCommand{
		BuildingID:  buildingID,
		Name:        "Ruang Kelas A",
		Capacity:    &cap,
		Floor:       &floor,
		Facilities:  []string{"projector", "whiteboard"},
		Description: "Ruang kelas standar",
	}

	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if repo.savedRoom == nil {
		t.Fatal("expected room to be saved")
	}
	if repo.savedRoom.Name != "Ruang Kelas A" {
		t.Errorf("expected name 'Ruang Kelas A', got '%s'", repo.savedRoom.Name)
	}
	if repo.savedRoom.BuildingID != buildingID {
		t.Errorf("expected buildingID %s, got %s", buildingID, repo.savedRoom.BuildingID)
	}
	if bus.published != 1 {
		t.Errorf("expected 1 event published, got %d", bus.published)
	}
}

func TestCreateRoomHandler_InvalidCommand(t *testing.T) {
	h := create_room.NewHandler(&fakeRoomWriteRepo{}, &fakeEventBus{})
	if err := h.Handle(context.Background(), nil); err == nil {
		t.Fatal("expected error for invalid command")
	}
}

func TestCreateRoomHandler_EmptyName(t *testing.T) {
	h := create_room.NewHandler(&fakeRoomWriteRepo{}, &fakeEventBus{})
	cmd := &create_room.CreateRoomCommand{
		BuildingID: uuid.New(),
		Name:       "",
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for empty name")
	}
}

func TestCreateRoomHandler_RepoError(t *testing.T) {
	repo := &fakeRoomWriteRepo{saveErr: errors.New("db error")}
	h := create_room.NewHandler(repo, &fakeEventBus{})
	cmd := &create_room.CreateRoomCommand{
		BuildingID: uuid.New(),
		Name:       "Ruang B",
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error when repo fails")
	}
}

func TestCreateRoomHandler_NilFacilitiesHandled(t *testing.T) {
	repo := &fakeRoomWriteRepo{}
	h := create_room.NewHandler(repo, &fakeEventBus{})
	cmd := &create_room.CreateRoomCommand{
		BuildingID: uuid.New(),
		Name:       "Ruang C",
		Facilities: nil,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if repo.savedRoom.Facilities == nil {
		t.Error("expected non-nil facilities slice")
	}
}
