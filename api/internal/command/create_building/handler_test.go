package create_building_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	create_building "github.com/vernonedu/entrepreneurship-api/internal/command/create_building"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ─── Fakes ───────────────────────────────────────────────────────────────────

type fakeBuildingWriteRepo struct {
	savedBuilding *building.Building
	saveErr       error
}

func (f *fakeBuildingWriteRepo) Save(_ context.Context, b *building.Building) error {
	f.savedBuilding = b
	return f.saveErr
}
func (f *fakeBuildingWriteRepo) Update(_ context.Context, _ *building.Building) error { return nil }
func (f *fakeBuildingWriteRepo) Delete(_ context.Context, _ uuid.UUID) error          { return nil }

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

func TestCreateBuildingHandler_Success(t *testing.T) {
	repo := &fakeBuildingWriteRepo{}
	bus := &fakeEventBus{}
	h := create_building.NewHandler(repo, bus)

	cmd := &create_building.CreateBuildingCommand{
		Name:        "Gedung Utama",
		Address:     "Jl. Contoh No. 1",
		Description: "Gedung administrasi",
	}

	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if repo.savedBuilding == nil {
		t.Fatal("expected building to be saved")
	}
	if repo.savedBuilding.Name != "Gedung Utama" {
		t.Errorf("expected name 'Gedung Utama', got '%s'", repo.savedBuilding.Name)
	}
	if bus.published != 1 {
		t.Errorf("expected 1 event published, got %d", bus.published)
	}
}

func TestCreateBuildingHandler_InvalidCommand(t *testing.T) {
	h := create_building.NewHandler(&fakeBuildingWriteRepo{}, &fakeEventBus{})
	if err := h.Handle(context.Background(), nil); err == nil {
		t.Fatal("expected error for invalid command")
	}
}

func TestCreateBuildingHandler_EmptyName(t *testing.T) {
	repo := &fakeBuildingWriteRepo{}
	h := create_building.NewHandler(repo, &fakeEventBus{})

	cmd := &create_building.CreateBuildingCommand{Name: ""}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for empty name")
	}
}

func TestCreateBuildingHandler_RepoError(t *testing.T) {
	repo := &fakeBuildingWriteRepo{saveErr: errors.New("db error")}
	h := create_building.NewHandler(repo, &fakeEventBus{})

	cmd := &create_building.CreateBuildingCommand{Name: "Gedung B"}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error when repo fails")
	}
}
