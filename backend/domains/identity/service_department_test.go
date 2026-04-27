package identity

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

func newDepartmentService(repo *fakeRepo) *Service {
	return NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)
}

func TestCreateDepartment_OK(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newDepartmentService(repo)

	createdBy := uuid.New()
	leader := uuid.New()
	dept, err := svc.CreateDepartment(ctx, CreateDepartmentInput{
		Name:      "Mathematics",
		LeaderID:  leader,
		CreatedBy: createdBy,
	})
	if err != nil {
		t.Fatalf("CreateDepartment: %v", err)
	}
	if dept.ID == uuid.Nil {
		t.Fatal("expected department ID")
	}
	if dept.Name != "Mathematics" {
		t.Fatalf("name=%q, want Mathematics", dept.Name)
	}
	if !dept.IsActive {
		t.Fatal("expected new department to be active")
	}
	if dept.LeaderID != leader {
		t.Fatalf("leader_id mismatch: got %s, want %s", dept.LeaderID, leader)
	}
	if dept.CreatedBy != createdBy {
		t.Fatalf("created_by mismatch")
	}

	got, err := repo.GetDepartmentByID(ctx, dept.ID)
	if err != nil {
		t.Fatalf("GetDepartmentByID: %v", err)
	}
	if got.Name != "Mathematics" {
		t.Fatalf("persisted name=%q, want Mathematics", got.Name)
	}
}

func TestCreateDepartment_EmptyName_Rejected(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newDepartmentService(repo)

	_, err := svc.CreateDepartment(ctx, CreateDepartmentInput{
		Name:      "   ",
		LeaderID:  uuid.New(),
		CreatedBy: uuid.New(),
	})
	if err == nil {
		t.Fatal("expected error for empty name")
	}
}

func TestDeactivateDepartment_SetsFlagFalse(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newDepartmentService(repo)

	dept, err := svc.CreateDepartment(ctx, CreateDepartmentInput{
		Name:      "Physics",
		LeaderID:  uuid.New(),
		CreatedBy: uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateDepartment: %v", err)
	}
	if !dept.IsActive {
		t.Fatal("expected created department active")
	}

	if err := svc.DeactivateDepartment(ctx, dept.ID); err != nil {
		t.Fatalf("DeactivateDepartment: %v", err)
	}

	got, err := repo.GetDepartmentByID(ctx, dept.ID)
	if err != nil {
		t.Fatalf("GetDepartmentByID: %v", err)
	}
	if got.IsActive {
		t.Fatal("expected IsActive=false after deactivation")
	}
}

func TestListActiveDepartments_OnlyActive(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	svc := newDepartmentService(repo)

	repo.SeedDepartment("Active1", true)
	repo.SeedDepartment("Active2", true)
	repo.SeedDepartment("Inactive", false)

	out, err := svc.ListActiveDepartments(ctx)
	if err != nil {
		t.Fatalf("ListActiveDepartments: %v", err)
	}
	if len(out) != 2 {
		t.Fatalf("len=%d, want 2", len(out))
	}
	for _, d := range out {
		if !d.IsActive {
			t.Fatalf("expected only active, got inactive %q", d.Name)
		}
	}
}
