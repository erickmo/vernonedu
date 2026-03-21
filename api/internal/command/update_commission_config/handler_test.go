package update_commission_config_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/command/update_commission_config"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// mockCommissionWriteRepo is a test double for settings.CommissionWriteRepository.
type mockCommissionWriteRepo struct {
	capturedCfg *settings.CommissionConfig
	returnErr   error
}

func (m *mockCommissionWriteRepo) Upsert(_ context.Context, cfg *settings.CommissionConfig) error {
	m.capturedCfg = cfg
	return m.returnErr
}

func TestHandler_Handle_Success(t *testing.T) {
	repo := &mockCommissionWriteRepo{}
	h := update_commission_config.NewHandler(repo)

	cmd := &update_commission_config.UpdateCommissionConfigCommand{
		OpLeaderPct:        5.0,
		OpLeaderBasis:      "profit",
		DeptLeaderPct:      3.0,
		DeptLeaderBasis:    "revenue",
		CourseCreatorPct:   2.5,
		CourseCreatorBasis: "profit",
	}

	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if repo.capturedCfg == nil {
		t.Fatal("expected cfg to be captured")
	}
	if repo.capturedCfg.OpLeaderPct != 5.0 {
		t.Errorf("expected OpLeaderPct=5.0, got %v", repo.capturedCfg.OpLeaderPct)
	}
	if repo.capturedCfg.OpLeaderBasis != "profit" {
		t.Errorf("expected OpLeaderBasis=profit, got %v", repo.capturedCfg.OpLeaderBasis)
	}
	if repo.capturedCfg.UpdatedAt.IsZero() {
		t.Error("expected UpdatedAt to be set")
	}
	if repo.capturedCfg.UpdatedAt.After(time.Now().Add(time.Second)) {
		t.Error("UpdatedAt is too far in the future")
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockCommissionWriteRepo{}
	h := update_commission_config.NewHandler(repo)

	err := h.Handle(context.Background(), nil)
	if !errors.Is(err, update_commission_config.ErrInvalidCommand) {
		t.Errorf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestHandler_Handle_RepoError(t *testing.T) {
	repoErr := errors.New("db error")
	repo := &mockCommissionWriteRepo{returnErr: repoErr}
	h := update_commission_config.NewHandler(repo)

	cmd := &update_commission_config.UpdateCommissionConfigCommand{
		OpLeaderBasis:      "profit",
		DeptLeaderBasis:    "profit",
		CourseCreatorBasis: "profit",
	}

	err := h.Handle(context.Background(), cmd)
	if !errors.Is(err, repoErr) {
		t.Errorf("expected repo error, got %v", err)
	}
}
