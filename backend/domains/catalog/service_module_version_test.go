package catalog

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// TestCreateModule_RejectsDuplicateOrderInCourse verifies that the (course_id,
// order) uniqueness contract is surfaced as ErrConflict by the service layer.
func TestCreateModule_RejectsDuplicateOrderInCourse(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	courseID := uuid.New()
	creator := uuid.New()

	if _, err := svc.CreateModule(ctx, CreateModuleInput{
		CourseID: courseID, Title: "Intro", Order: 1, CreatedBy: creator,
	}); err != nil {
		t.Fatalf("first CreateModule: unexpected error: %v", err)
	}

	_, err := svc.CreateModule(ctx, CreateModuleInput{
		CourseID: courseID, Title: "Other", Order: 1, CreatedBy: creator,
	})
	if !errors.Is(err, apperrors.ErrConflict) {
		t.Fatalf("expected ErrConflict on duplicate (course_id, order), got %v", err)
	}
}

// TestPublishVersion_ArchivesPreviousPublished verifies that publishing v2
// atomically archives v1 when v1 was already 'published' for the same module.
func TestPublishVersion_ArchivesPreviousPublished(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	moduleID := uuid.New()
	creator := uuid.New()

	v1 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModulePublished, CreatedBy: creator,
	})
	v2 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 2, Title: "v2",
		Status: ModuleDraft, CreatedBy: creator,
	})

	if err := svc.PublishModuleVersion(ctx, v2.ID, creator); err != nil {
		t.Fatalf("PublishModuleVersion: %v", err)
	}

	got1, err := repo.GetModuleVersionByID(ctx, v1.ID)
	if err != nil {
		t.Fatalf("get v1: %v", err)
	}
	if got1.Status != ModuleArchived {
		t.Fatalf("v1 status: want %q, got %q", ModuleArchived, got1.Status)
	}

	got2, err := repo.GetModuleVersionByID(ctx, v2.ID)
	if err != nil {
		t.Fatalf("get v2: %v", err)
	}
	if got2.Status != ModulePublished {
		t.Fatalf("v2 status: want %q, got %q", ModulePublished, got2.Status)
	}
	if got2.PublishedAt == nil || got2.PublishedBy == nil {
		t.Fatalf("v2 should record published_at and published_by")
	}
	if *got2.PublishedBy != creator {
		t.Fatalf("v2 published_by mismatch: %v", *got2.PublishedBy)
	}
}

// TestPublishVersion_FirstPublish_NoArchive verifies that publishing the very
// first version (no prior 'published') leaves no other version touched.
func TestPublishVersion_FirstPublish_NoArchive(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	moduleID := uuid.New()
	creator := uuid.New()

	v1 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModuleDraft, CreatedBy: creator,
	})

	// Unrelated module's published version must not be touched.
	otherModule := uuid.New()
	other := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: otherModule, VersionNumber: 1, Title: "other",
		Status: ModulePublished, CreatedBy: creator,
	})

	if err := svc.PublishModuleVersion(ctx, v1.ID, creator); err != nil {
		t.Fatalf("PublishModuleVersion: %v", err)
	}

	got, err := repo.GetModuleVersionByID(ctx, v1.ID)
	if err != nil {
		t.Fatalf("get v1: %v", err)
	}
	if got.Status != ModulePublished {
		t.Fatalf("v1 status: want %q, got %q", ModulePublished, got.Status)
	}

	gotOther, err := repo.GetModuleVersionByID(ctx, other.ID)
	if err != nil {
		t.Fatalf("get other: %v", err)
	}
	if gotOther.Status != ModulePublished {
		t.Fatalf("unrelated module's published version was modified: status=%q", gotOther.Status)
	}
}

// TestPublishVersion_ConcurrentRespectsUnique sequentially publishes two
// versions of the same module to verify the auto-archive invariant: at any
// point in time at most one version is 'published' per module. Real DB-level
// concurrency is enforced by the partial unique index
// uq_module_one_published; this test exercises the service contract that
// holds true under that invariant.
func TestPublishVersion_ConcurrentRespectsUnique(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	moduleID := uuid.New()
	creator := uuid.New()

	v1 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 1, Title: "v1",
		Status: ModuleDraft, CreatedBy: creator,
	})
	v2 := repo.SeedModuleVersion(&ModuleVersion{
		ModuleID: moduleID, VersionNumber: 2, Title: "v2",
		Status: ModuleDraft, CreatedBy: creator,
	})

	if err := svc.PublishModuleVersion(ctx, v1.ID, creator); err != nil {
		t.Fatalf("publish v1: %v", err)
	}
	if err := svc.PublishModuleVersion(ctx, v2.ID, creator); err != nil {
		t.Fatalf("publish v2: %v", err)
	}

	publishedCount := 0
	for _, mv := range repo.moduleVersions {
		if mv.ModuleID == moduleID && mv.Status == ModulePublished {
			publishedCount++
		}
	}
	if publishedCount != 1 {
		t.Fatalf("at-most-one published invariant violated: count=%d", publishedCount)
	}
}

// TestModuleVersion_DraftHidden is a placeholder for Task 9 (ResolveModuleVersion).
// It documents the expectation that draft versions are not returned to learners.
func TestModuleVersion_DraftHidden(t *testing.T) {
	t.Skip("TODO: enable when ResolveModuleVersion (Task 9) is implemented")
}
