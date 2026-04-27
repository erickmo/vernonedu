package identity

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

func newFeeTierService(repo *fakeRepo) *Service {
	return NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)
}

func TestCreateFeeTier_Persists(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newFeeTierService(repo)

	amount := decimal.NewFromInt(100000)
	ft, err := svc.CreateFeeTier(ctx, CreateFeeTierInput{
		Name:           "Standard",
		AmountPerClass: &amount,
		CreatedBy:      uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateFeeTier: %v", err)
	}
	if ft.ID == uuid.Nil {
		t.Fatal("expected fee tier ID")
	}
	if !ft.IsActive {
		t.Fatal("expected new fee tier to be active")
	}
	got, err := repo.GetFeeTierByID(ctx, ft.ID)
	if err != nil {
		t.Fatalf("GetFeeTierByID: %v", err)
	}
	if got.Name != "Standard" {
		t.Fatalf("name=%q, want Standard", got.Name)
	}
}

func TestListFeeTiers_DefaultActiveOnly(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newFeeTierService(repo)

	repo.SeedFeeTier("A", true)
	repo.SeedFeeTier("B", true)
	repo.SeedFeeTier("C", false)

	out, err := svc.ListFeeTiers(ctx, false)
	if err != nil {
		t.Fatalf("ListFeeTiers: %v", err)
	}
	if len(out) != 2 {
		t.Fatalf("len=%d, want 2", len(out))
	}
	for _, ft := range out {
		if !ft.IsActive {
			t.Fatalf("expected only active tiers, got inactive %q", ft.Name)
		}
	}
}

func TestListFeeTiers_IncludeInactive(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newFeeTierService(repo)

	repo.SeedFeeTier("A", true)
	repo.SeedFeeTier("B", true)
	repo.SeedFeeTier("C", false)

	out, err := svc.ListFeeTiers(ctx, true)
	if err != nil {
		t.Fatalf("ListFeeTiers: %v", err)
	}
	if len(out) != 3 {
		t.Fatalf("len=%d, want 3", len(out))
	}
}

func TestDeactivateFeeTier_SetsFlagFalse(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newFeeTierService(repo)

	ft, err := svc.CreateFeeTier(ctx, CreateFeeTierInput{
		Name:      "ToDeactivate",
		CreatedBy: uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateFeeTier: %v", err)
	}
	if !ft.IsActive {
		t.Fatal("expected created fee tier active")
	}

	if err := svc.DeactivateFeeTier(ctx, ft.ID); err != nil {
		t.Fatalf("DeactivateFeeTier: %v", err)
	}

	got, err := repo.GetFeeTierByID(ctx, ft.ID)
	if err != nil {
		t.Fatalf("GetFeeTierByID: %v", err)
	}
	if got.IsActive {
		t.Fatal("expected IsActive=false after deactivation")
	}
}
