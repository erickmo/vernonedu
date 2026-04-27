package enrollment

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// createSvc builds a Service backed by all four fakes.
func createSvc(t *testing.T) (
	*Service,
	*fakeEnrollmentRepo,
	*fakeCatalogReader,
	*fakePartnershipsReader,
	*fakeBus,
) {
	t.Helper()
	r := newFakeEnrollmentRepo()
	cat := newFakeCatalogReader()
	part := newFakePartnershipsReader()
	bus := newFakeBus()
	s := NewService(r, bus, testLogger(), cat, part)
	return s, r, cat, part, bus
}

// seededBatch returns a batch in "open" status with web reg open and a wide
// registration window. Tests mutate fields before seeding as needed.
func seededBatch(courseID uuid.UUID) *CatalogBatch {
	openAt := time.Now().Add(-1 * time.Hour)
	closeAt := time.Now().Add(24 * time.Hour)
	return &CatalogBatch{
		ID:                  uuid.New(),
		CourseID:            courseID,
		CourseTitle:         "Intro to Vernon",
		Price:               decimal.NewFromInt(1000),
		Status:              BatchStatusOpen,
		WebRegistrationOpen: true,
		RegistrationOpenAt:  &openAt,
		RegistrationCloseAt: &closeAt,
	}
}

func enabledRegular() *CatalogFormatConfig {
	return &CatalogFormatConfig{Format: FormatRegular, IsEnabled: true}
}

func TestCreate_B2C_Web_Self_RequiresWebRegistrationOpen(t *testing.T) {
	s, _, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.WebRegistrationOpen = false
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	_, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreate_OutsideRegistrationWindow_Blocked(t *testing.T) {
	s, _, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	future := time.Now().Add(24 * time.Hour)
	b.RegistrationOpenAt = &future
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	_, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreate_FormatNotEnabled_Rejected(t *testing.T) {
	s, _, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, &CatalogFormatConfig{Format: FormatRegular, IsEnabled: false})

	_, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreate_InhouseTraining_RejectsB2C(t *testing.T) {
	s, _, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, &CatalogFormatConfig{Format: FormatInhouseTraining, IsEnabled: true})

	_, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatInhouseTraining,
		Mode:          ModeOffline,
		Source:        SourceB2C,
	})
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreate_MaxStudentsReached_Rejected(t *testing.T) {
	s, repo, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	cat.SeedBatch(b)
	max := 1
	cat.SeedFormatConfig(courseID, &CatalogFormatConfig{Format: FormatRegular, IsEnabled: true, MaxStudents: &max})

	// Pre-fill capacity.
	repo.SeedEnrollment(&Enrollment{
		ID:               uuid.New(),
		StudentID:        uuid.New(),
		CourseBatchID:    b.ID,
		Format:           FormatRegular,
		CompletionStatus: CompletionOngoing,
	})

	_, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreate_DuplicateStudentBatch_Rejected(t *testing.T) {
	s, _, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	studentID := uuid.New()
	in := EnrollInput{
		StudentID:     studentID,
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	}
	if _, err := s.Enroll(context.Background(), in); err != nil {
		t.Fatalf("first enroll failed: %v", err)
	}
	_, err := s.Enroll(context.Background(), in)
	if err == nil {
		t.Fatalf("expected conflict, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "CONFLICT" {
		t.Fatalf("expected CONFLICT, got %v", err)
	}
}

func TestCreate_FiresEnrollmentConfirmed_WithCanonicalPayload(t *testing.T) {
	s, _, cat, _, bus := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.CourseTitle = "Canonical Course"
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	studentID := uuid.New()
	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     studentID,
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	if err != nil {
		t.Fatalf("enroll failed: %v", err)
	}

	if !bus.Fired(events.EnrollmentConfirmed) {
		t.Fatalf("expected EnrollmentConfirmed to fire")
	}

	bus.mu.Lock()
	payloads := bus.payloads[events.EnrollmentConfirmed]
	bus.mu.Unlock()
	if len(payloads) == 0 {
		t.Fatalf("no payload captured")
	}
	p, ok := payloads[0].(events.EnrollmentConfirmedPayload)
	if !ok {
		t.Fatalf("expected canonical events.EnrollmentConfirmedPayload, got %T", payloads[0])
	}
	if p.EnrollmentID != e.ID {
		t.Fatalf("EnrollmentID mismatch")
	}
	if p.StudentID != studentID {
		t.Fatalf("StudentID mismatch")
	}
	if p.BatchID != b.ID {
		t.Fatalf("BatchID mismatch")
	}
	if p.CourseTitle != "Canonical Course" {
		t.Fatalf("CourseTitle mismatch: got %q", p.CourseTitle)
	}
}

func TestCreate_B2B_PartnerPayer_UsesAgreementBulkPrice(t *testing.T) {
	s, _, cat, part, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.Price = decimal.NewFromInt(1000)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	partnerID := uuid.New()
	bulk := decimal.NewFromInt(700)
	part.SeedAgreement(&Agreement{
		ID:        uuid.New(),
		PartnerID: partnerID,
		Payer:     PayerPartner,
		BulkPrice: &bulk,
		IsActive:  true,
	})

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOffline,
		PartnerID:     &partnerID,
		Source:        SourceB2B,
	})
	if err != nil {
		t.Fatalf("enroll failed: %v", err)
	}
	if !e.FinalPrice.Equal(decimal.NewFromInt(700)) {
		t.Fatalf("expected final 700, got %s", e.FinalPrice.String())
	}
	if e.Payer != string(PayerPartner) {
		t.Fatalf("expected payer=partner, got %s", e.Payer)
	}
}

func TestCreate_B2B_StudentPayer_VoucherApplies(t *testing.T) {
	s, repo, cat, part, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.Price = decimal.NewFromInt(500)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	partnerID := uuid.New()
	part.SeedAgreement(&Agreement{
		ID:        uuid.New(),
		PartnerID: partnerID,
		Payer:     PayerStudent,
		IsActive:  true,
	})

	v := &Voucher{
		ID:            uuid.New(),
		Code:          "STUDENT-VC",
		DiscountType:  DiscountFixed,
		DiscountValue: decimal.NewFromInt(100),
		IsActive:      true,
		ValidFrom:     time.Now().Add(-time.Hour),
		CreatedBy:     uuid.New(),
	}
	repo.SeedVoucher(v)

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOffline,
		PartnerID:     &partnerID,
		VoucherCode:   v.Code,
		Source:        SourceB2B,
	})
	if err != nil {
		t.Fatalf("enroll failed: %v", err)
	}
	if !e.Price.Equal(decimal.NewFromInt(500)) {
		t.Fatalf("expected price 500, got %s", e.Price.String())
	}
	if !e.FinalPrice.Equal(decimal.NewFromInt(400)) {
		t.Fatalf("expected final 400, got %s", e.FinalPrice.String())
	}
	if e.Payer != string(PayerStudent) {
		t.Fatalf("expected payer=student, got %s", e.Payer)
	}
}

func TestCreate_B2C_PercentageVoucher_FinalPriceComputed(t *testing.T) {
	s, repo, cat, _, _ := createSvc(t)
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.Price = decimal.NewFromInt(200)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())

	v := &Voucher{
		ID:            uuid.New(),
		Code:          "PCT10",
		DiscountType:  DiscountPercentage,
		DiscountValue: decimal.NewFromInt(10),
		IsActive:      true,
		ValidFrom:     time.Now().Add(-time.Hour),
		CreatedBy:     uuid.New(),
	}
	repo.SeedVoucher(v)

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		VoucherCode:   v.Code,
		Source:        SourceB2C,
	})
	if err != nil {
		t.Fatalf("enroll failed: %v", err)
	}
	if !e.FinalPrice.Equal(decimal.NewFromInt(180)) {
		t.Fatalf("expected final 180, got %s", e.FinalPrice.String())
	}
	if e.VoucherID == nil || *e.VoucherID != v.ID {
		t.Fatalf("expected voucher applied")
	}
}
