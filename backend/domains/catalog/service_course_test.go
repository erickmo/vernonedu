package catalog

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

func TestCreateCourse_RejectsMinPriceGreaterThanBasePrice(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	in := CreateCourseInput{
		Name:            "Algebra 101",
		DepartmentID:    uuid.New(),
		CourseCreatorID: uuid.New(),
		BasePrice:       decimal.NewFromInt(100),
		MinPrice:        decimal.NewFromInt(150),
		CreatedBy:       uuid.New(),
	}

	got, err := svc.CreateCourse(context.Background(), in)
	if err == nil {
		t.Fatalf("expected validation error, got course %+v", got)
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected validation AppError, got %T: %v", err, err)
	}
	if got != nil {
		t.Fatalf("expected nil course on error, got %+v", got)
	}
}

func TestCreateCourse_OK_StoresCreator(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	creatorID := uuid.New()
	createdBy := uuid.New()
	in := CreateCourseInput{
		Name:            "Algebra 101",
		DepartmentID:    uuid.New(),
		CourseCreatorID: creatorID,
		BasePrice:       decimal.NewFromInt(200),
		MinPrice:        decimal.NewFromInt(100),
		CreatedBy:       createdBy,
	}

	got, err := svc.CreateCourse(context.Background(), in)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got == nil {
		t.Fatal("expected course, got nil")
	}
	if got.ID == uuid.Nil {
		t.Error("expected ID to be assigned")
	}
	if got.CourseCreatorID != creatorID {
		t.Errorf("CourseCreatorID = %v, want %v", got.CourseCreatorID, creatorID)
	}
	if got.CreatedBy != createdBy {
		t.Errorf("CreatedBy = %v, want %v", got.CreatedBy, createdBy)
	}
	if !got.IsActive {
		t.Error("new course should be active")
	}

	stored, err := repo.GetCourseByID(context.Background(), got.ID)
	if err != nil {
		t.Fatalf("expected stored course, got err %v", err)
	}
	if stored.CourseCreatorID != creatorID {
		t.Errorf("stored CourseCreatorID = %v, want %v", stored.CourseCreatorID, creatorID)
	}
}

func TestUpdateCourse_KeepsExistingBatchPricesIntact(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	deptID := uuid.New()
	courseID := uuid.New()
	repo.SeedCourse(&Course{
		ID:              courseID,
		Name:            "Original",
		DepartmentID:    deptID,
		CourseCreatorID: uuid.New(),
		BasePrice:       decimal.NewFromInt(100),
		MinPrice:        decimal.NewFromInt(50),
		IsActive:        true,
	})

	originalBatchPrice := decimal.NewFromInt(75)
	batch := repo.SeedBatch(&CourseBatch{
		CourseID: courseID,
		Label:    "Batch A",
		Price:    originalBatchPrice,
		Status:   BatchOpen,
	})

	newName := "Renamed"
	newBase := decimal.NewFromInt(300)
	newMin := decimal.NewFromInt(200)
	updated, err := svc.UpdateCourse(context.Background(), UpdateCourseInput{
		ID:        courseID,
		Name:      &newName,
		BasePrice: &newBase,
		MinPrice:  &newMin,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if updated.Name != newName {
		t.Errorf("Name = %s, want %s", updated.Name, newName)
	}
	if !updated.BasePrice.Equal(newBase) {
		t.Errorf("BasePrice = %s, want %s", updated.BasePrice, newBase)
	}
	if !updated.MinPrice.Equal(newMin) {
		t.Errorf("MinPrice = %s, want %s", updated.MinPrice, newMin)
	}

	// Verify batch's price was NOT touched by UpdateCourse.
	storedBatch, err := repo.GetBatchByID(context.Background(), batch.ID)
	if err != nil {
		t.Fatalf("get batch: %v", err)
	}
	if !storedBatch.Price.Equal(originalBatchPrice) {
		t.Errorf("batch.Price = %s, want %s (unchanged)", storedBatch.Price, originalBatchPrice)
	}
	if storedBatch.Status != BatchOpen {
		t.Errorf("batch.Status = %s, want %s (unchanged)", storedBatch.Status, BatchOpen)
	}
}
