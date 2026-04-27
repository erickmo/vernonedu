package catalog

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

func intPtr(v int) *int { return &v }

func TestAddFormatConfig_OK(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	courseID := uuid.New()
	in := AddFormatConfigInput{
		CourseID:    courseID,
		Format:      FormatRegular,
		MinStudents: intPtr(5),
		MaxStudents: intPtr(20),
		ModeOnline:  true,
		ModeOffline: false,
	}

	cfg, err := svc.AddFormatConfig(context.Background(), in)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg == nil {
		t.Fatal("expected config, got nil")
	}
	if cfg.ID == uuid.Nil {
		t.Error("expected ID to be assigned")
	}
	if cfg.CourseID != courseID {
		t.Errorf("CourseID = %v, want %v", cfg.CourseID, courseID)
	}
	if cfg.Format != FormatRegular {
		t.Errorf("Format = %v, want %v", cfg.Format, FormatRegular)
	}
	if !cfg.IsEnabled {
		t.Error("new format config should be enabled")
	}

	stored, err := repo.GetFormatConfig(context.Background(), cfg.ID)
	if err != nil {
		t.Fatalf("expected stored config, got err %v", err)
	}
	if stored.Format != FormatRegular {
		t.Errorf("stored Format = %v, want %v", stored.Format, FormatRegular)
	}
}

func TestAddFormatConfig_DuplicateRejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	courseID := uuid.New()
	in := AddFormatConfigInput{
		CourseID: courseID,
		Format:   FormatPrivate,
	}

	if _, err := svc.AddFormatConfig(context.Background(), in); err != nil {
		t.Fatalf("first add unexpected error: %v", err)
	}

	_, err := svc.AddFormatConfig(context.Background(), in)
	if err == nil {
		t.Fatal("expected ErrConflict on duplicate, got nil")
	}
	if !errors.Is(err, apperrors.ErrConflict) {
		t.Errorf("expected ErrConflict, got %v", err)
	}
}

func TestAddFormatConfig_MinGreaterThanMax_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	in := AddFormatConfigInput{
		CourseID:    uuid.New(),
		Format:      FormatRegular,
		MinStudents: intPtr(50),
		MaxStudents: intPtr(10),
	}

	got, err := svc.AddFormatConfig(context.Background(), in)
	if err == nil {
		t.Fatalf("expected validation error, got cfg %+v", got)
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected validation AppError, got %T: %v", err, err)
	}
	if got != nil {
		t.Fatalf("expected nil config on error, got %+v", got)
	}
}

func TestDisableFormat_SetsFlagFalse(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	cfg, err := svc.AddFormatConfig(context.Background(), AddFormatConfigInput{
		CourseID: uuid.New(),
		Format:   FormatInhouseTraining,
	})
	if err != nil {
		t.Fatalf("setup add: %v", err)
	}
	if !cfg.IsEnabled {
		t.Fatal("precondition: expected IsEnabled true")
	}

	if err := svc.DisableFormat(context.Background(), cfg.ID); err != nil {
		t.Fatalf("DisableFormat: %v", err)
	}

	stored, err := repo.GetFormatConfig(context.Background(), cfg.ID)
	if err != nil {
		t.Fatalf("get after disable: %v", err)
	}
	if stored.IsEnabled {
		t.Error("expected IsEnabled false after DisableFormat")
	}
}
