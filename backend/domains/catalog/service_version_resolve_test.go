package catalog

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

// TestResolve_NoBatchModuleConfig_ReturnsLatestPublished verifies the fallback
// path: when no BMC row exists for (batch, module), the resolver returns the
// latest 'published' ModuleVersion of that module.
func TestResolve_NoBatchModuleConfig_ReturnsLatestPublished(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModuleArchived, CreatedBy: creator,
	})
	v2 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 2, Title: "v2",
		Status: ModulePublished, CreatedBy: creator,
	})

	got, err := svc.ResolveModuleVersion(ctx, batchID, moduleID)
	if err != nil {
		t.Fatalf("ResolveModuleVersion: %v", err)
	}
	if got.ID != v2.ID {
		t.Fatalf("expected latest published v2 (%v), got %v", v2.ID, got.ID)
	}
}

// TestResolve_AutoLatestPolicy_ReturnsLatestPublished verifies that an
// explicit auto_latest BMC behaves like the fallback path.
func TestResolve_AutoLatestPolicy_ReturnsLatestPublished(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModulePublished, CreatedBy: creator,
	})
	v2 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 2, Title: "v2",
		Status: ModulePublished, CreatedBy: creator,
	})
	repo.SeedBatchModuleConfig(batchID, moduleID, PolicyAutoLatest, nil, creator)

	got, err := svc.ResolveModuleVersion(ctx, batchID, moduleID)
	if err != nil {
		t.Fatalf("ResolveModuleVersion: %v", err)
	}
	if got.ID != v2.ID {
		t.Fatalf("expected latest published v2 (%v), got %v", v2.ID, got.ID)
	}
}

// TestResolve_LockedPolicy_ReturnsLockedVersion verifies that a locked BMC
// returns the pinned version even when a newer published version exists.
func TestResolve_LockedPolicy_ReturnsLockedVersion(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	v1 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModulePublished, CreatedBy: creator,
	})
	repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 2, Title: "v2",
		Status: ModulePublished, CreatedBy: creator,
	})
	locked := v1.ID
	repo.SeedBatchModuleConfig(batchID, moduleID, PolicyLocked, &locked, creator)

	got, err := svc.ResolveModuleVersion(ctx, batchID, moduleID)
	if err != nil {
		t.Fatalf("ResolveModuleVersion: %v", err)
	}
	if got.ID != v1.ID {
		t.Fatalf("expected locked v1 (%v), got %v", v1.ID, got.ID)
	}
}

// TestResolve_LockedPolicy_LockedVersionMustBePublished verifies the
// lock-set-time check: LockBatchToVersion rejects locking to a draft version.
func TestResolve_LockedPolicy_LockedVersionMustBePublished(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	draft := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModuleDraft, CreatedBy: creator,
	})

	_, err := svc.LockBatchToVersion(ctx, batchID, moduleID, draft.ID, creator)
	if !isValidationErr(err) {
		t.Fatalf("expected validation error locking to draft, got %v", err)
	}
}

// TestLockBatchToVersion_OK verifies the happy path: locking to a published
// version writes a BMC with policy=locked and the supplied locked_version_id.
func TestLockBatchToVersion_OK(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	v := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 3, Title: "v3",
		Status: ModulePublished, CreatedBy: creator,
	})

	cfg, err := svc.LockBatchToVersion(ctx, batchID, moduleID, v.ID, creator)
	if err != nil {
		t.Fatalf("LockBatchToVersion: %v", err)
	}
	if cfg.VersionPolicy != PolicyLocked {
		t.Fatalf("policy: want %q, got %q", PolicyLocked, cfg.VersionPolicy)
	}
	if cfg.LockedVersionID == nil || *cfg.LockedVersionID != v.ID {
		t.Fatalf("locked_version_id mismatch: %v", cfg.LockedVersionID)
	}

	stored, err := repo.GetBatchModuleConfig(ctx, batchID, moduleID)
	if err != nil {
		t.Fatalf("GetBatchModuleConfig: %v", err)
	}
	if stored.VersionPolicy != PolicyLocked || stored.LockedVersionID == nil || *stored.LockedVersionID != v.ID {
		t.Fatalf("BMC not persisted correctly: %+v", stored)
	}
}

// TestLockBatchToVersion_RejectsNonPublishedVersion ensures archived versions
// are also rejected by LockBatchToVersion.
func TestLockBatchToVersion_RejectsNonPublishedVersion(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	creator := uuid.New()

	archived := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModuleArchived, CreatedBy: creator,
	})

	_, err := svc.LockBatchToVersion(ctx, batchID, moduleID, archived.ID, creator)
	if !isValidationErr(err) {
		t.Fatalf("expected validation error locking to archived, got %v", err)
	}
}

// TestLockBatchToVersion_RejectsVersionFromOtherModule ensures the version
// must belong to the same module.
func TestLockBatchToVersion_RejectsVersionFromOtherModule(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	batchID := uuid.New()
	moduleID := uuid.New()
	otherModuleID := uuid.New()
	creator := uuid.New()

	v := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: otherModuleID, VersionNumber: 1, Title: "v1",
		Status: ModulePublished, CreatedBy: creator,
	})

	_, err := svc.LockBatchToVersion(ctx, batchID, moduleID, v.ID, creator)
	if !isValidationErr(err) {
		t.Fatalf("expected validation error for cross-module lock, got %v", err)
	}
}
