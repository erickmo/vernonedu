package upsert_facilitator_levels_test

import (
	"context"
	"errors"
	"testing"

	"github.com/vernonedu/entrepreneurship-api/internal/command/upsert_facilitator_levels"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

type mockFacilitatorWriteRepo struct {
	capturedLevels []*settings.FacilitatorLevel
	returnErr      error
}

func (m *mockFacilitatorWriteRepo) ReplaceAll(_ context.Context, levels []*settings.FacilitatorLevel) error {
	m.capturedLevels = levels
	return m.returnErr
}

func TestHandler_Handle_Success(t *testing.T) {
	repo := &mockFacilitatorWriteRepo{}
	h := upsert_facilitator_levels.NewHandler(repo)

	cmd := &upsert_facilitator_levels.UpsertFacilitatorLevelsCommand{
		Levels: []upsert_facilitator_levels.FacilitatorLevelInput{
			{Level: 1, Name: "Junior", FeePerSession: 200000},
			{Level: 2, Name: "Senior", FeePerSession: 350000},
		},
	}

	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(repo.capturedLevels) != 2 {
		t.Fatalf("expected 2 levels, got %d", len(repo.capturedLevels))
	}
	if repo.capturedLevels[0].Level != 1 {
		t.Errorf("expected level=1, got %d", repo.capturedLevels[0].Level)
	}
	if repo.capturedLevels[0].FeePerSession != 200000 {
		t.Errorf("expected fee=200000, got %d", repo.capturedLevels[0].FeePerSession)
	}
	if repo.capturedLevels[0].ID.String() == "" {
		t.Error("expected ID to be generated")
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockFacilitatorWriteRepo{}
	h := upsert_facilitator_levels.NewHandler(repo)

	err := h.Handle(context.Background(), nil)
	if !errors.Is(err, upsert_facilitator_levels.ErrInvalidCommand) {
		t.Errorf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestHandler_Handle_RepoError(t *testing.T) {
	repoErr := errors.New("db error")
	repo := &mockFacilitatorWriteRepo{returnErr: repoErr}
	h := upsert_facilitator_levels.NewHandler(repo)

	cmd := &upsert_facilitator_levels.UpsertFacilitatorLevelsCommand{
		Levels: []upsert_facilitator_levels.FacilitatorLevelInput{
			{Level: 1, Name: "Junior", FeePerSession: 200000},
		},
	}

	if err := h.Handle(context.Background(), cmd); !errors.Is(err, repoErr) {
		t.Errorf("expected repo error, got %v", err)
	}
}
