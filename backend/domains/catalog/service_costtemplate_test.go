package catalog

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

func TestCreateBatch_CopiesCostTemplatesToBatch(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	courseID := uuid.New()
	repo.SeedCourse(&Course{ID: courseID, Name: "C1"})
	tpl1 := repo.SeedCostTemplate(courseID, "Venue", decimal.NewFromInt(500))
	tpl2 := repo.SeedCostTemplate(courseID, "Snacks", decimal.NewFromInt(100))

	createdBy := uuid.New()
	batch, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		CourseID:  courseID,
		Label:     "Batch A",
		StartDate: time.Now(),
		EndDate:   time.Now().Add(24 * time.Hour),
		Price:     decimal.NewFromInt(1000),
		CreatedBy: createdBy,
	})
	if err != nil {
		t.Fatalf("CreateBatch err: %v", err)
	}

	items, err := repo.ListBatchCostLineItems(context.Background(), batch.ID)
	if err != nil {
		t.Fatalf("list items: %v", err)
	}
	if len(items) != 2 {
		t.Fatalf("expected 2 line items, got %d", len(items))
	}
	seen := map[uuid.UUID]bool{}
	for _, li := range items {
		if li.TemplateRefID == nil {
			t.Errorf("expected template_ref_id set, got nil for label %s", li.Label)
			continue
		}
		seen[*li.TemplateRefID] = true
		if li.CreatedBy != createdBy {
			t.Errorf("CreatedBy = %v, want %v", li.CreatedBy, createdBy)
		}
		if li.CourseBatchID != batch.ID {
			t.Errorf("CourseBatchID mismatch")
		}
	}
	if !seen[tpl1.ID] || !seen[tpl2.ID] {
		t.Errorf("expected both template ids referenced; saw %v", seen)
	}
}

func TestCreateBatch_OverrideOnBatchLeavesTemplateUntouched(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	courseID := uuid.New()
	repo.SeedCourse(&Course{ID: courseID, Name: "C1"})
	originalAmount := decimal.NewFromInt(500)
	originalLabel := "Venue"
	tpl := repo.SeedCostTemplate(courseID, originalLabel, originalAmount)

	batch, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		CourseID:  courseID,
		Label:     "Batch A",
		StartDate: time.Now(),
		EndDate:   time.Now().Add(24 * time.Hour),
		Price:     decimal.NewFromInt(1000),
		CreatedBy: uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateBatch err: %v", err)
	}

	items, err := repo.ListBatchCostLineItems(context.Background(), batch.ID)
	if err != nil || len(items) != 1 {
		t.Fatalf("expected 1 item, got %d (err %v)", len(items), err)
	}
	li := items[0]
	li.Amount = decimal.NewFromInt(750)
	li.Label = "Venue (premium)"
	if err := repo.UpdateBatchCostLineItem(context.Background(), li); err != nil {
		t.Fatalf("update: %v", err)
	}

	// Verify template untouched.
	tpls, _ := repo.ListCourseCostTemplates(context.Background(), courseID)
	if len(tpls) != 1 {
		t.Fatalf("expected 1 template, got %d", len(tpls))
	}
	if !tpls[0].Amount.Equal(originalAmount) {
		t.Errorf("template amount = %s, want %s (unchanged)", tpls[0].Amount, originalAmount)
	}
	if tpls[0].Label != originalLabel {
		t.Errorf("template label = %s, want %s (unchanged)", tpls[0].Label, originalLabel)
	}
	if tpls[0].ID != tpl.ID {
		t.Errorf("template id changed")
	}
}

func TestBatchCostLineItem_NewWithoutTemplateRef_OK(t *testing.T) {
	repo := newFakeCatalogRepo()

	batchID := uuid.New()
	li := &BatchCostLineItem{
		ID:            uuid.New(),
		CourseBatchID: batchID,
		TemplateRefID: nil,
		Label:         "Manual Adjustment",
		Amount:        decimal.NewFromInt(50),
		CostType:      CostFixed,
		ReferenceType: CostRefManual,
		CreatedBy:     uuid.New(),
	}
	if err := repo.CreateBatchCostLineItem(context.Background(), li); err != nil {
		t.Fatalf("create: %v", err)
	}
	items, err := repo.ListBatchCostLineItems(context.Background(), batchID)
	if err != nil || len(items) != 1 {
		t.Fatalf("expected 1 item, got %d (err %v)", len(items), err)
	}
	if items[0].TemplateRefID != nil {
		t.Errorf("expected nil template_ref_id, got %v", *items[0].TemplateRefID)
	}
}

func TestBatchCostLineItem_IsRemovedFlag_Excluded(t *testing.T) {
	repo := newFakeCatalogRepo()

	batchID := uuid.New()
	li := &BatchCostLineItem{
		ID:            uuid.New(),
		CourseBatchID: batchID,
		Label:         "Test",
		Amount:        decimal.NewFromInt(10),
		CostType:      CostFixed,
		ReferenceType: CostRefManual,
		CreatedBy:     uuid.New(),
	}
	if err := repo.CreateBatchCostLineItem(context.Background(), li); err != nil {
		t.Fatalf("create: %v", err)
	}
	li.IsRemoved = true
	if err := repo.UpdateBatchCostLineItem(context.Background(), li); err != nil {
		t.Fatalf("update: %v", err)
	}

	items, err := repo.ListBatchCostLineItems(context.Background(), batchID)
	if err != nil || len(items) != 1 {
		t.Fatalf("expected 1 item, got %d (err %v)", len(items), err)
	}
	if !items[0].IsRemoved {
		t.Errorf("expected IsRemoved=true, got false")
	}
}
