package enrollment

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// creditSvc builds a Service with a fakeFinanceReader plus the standard fakes.
func creditSvc(t *testing.T) (
	*Service,
	*fakeEnrollmentRepo,
	*fakeCatalogReader,
	*fakeFinanceReader,
) {
	t.Helper()
	r := newFakeEnrollmentRepo()
	cat := newFakeCatalogReader()
	part := newFakePartnershipsReader()
	fin := newFakeFinanceReader()
	bus := newFakeBus()
	s := NewService(r, bus, testLogger(), cat, part, fin)
	return s, r, cat, fin
}

func seedCreditBatch(t *testing.T, cat *fakeCatalogReader, price int64) *CatalogBatch {
	t.Helper()
	courseID := uuid.New()
	b := seededBatch(courseID)
	b.Price = decimal.NewFromInt(price)
	cat.SeedBatch(b)
	cat.SeedFormatConfig(courseID, enabledRegular())
	return b
}

func TestApplyCredit_DuringCreate_Sets_CreditApplied_FinalPriceUnchanged(t *testing.T) {
	s, _, cat, fin := creditSvc(t)
	b := seedCreditBatch(t, cat, 200)

	studentID := uuid.New()
	creditID := uuid.New()
	fin.SeedCredit(&StudentCredit{
		ID:        creditID,
		StudentID: studentID,
		Balance:   decimal.NewFromInt(50),
		IsActive:  true,
	})

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:       studentID,
		CourseBatchID:   b.ID,
		Format:          FormatRegular,
		Mode:            ModeOnline,
		Source:          SourceB2C,
		StudentCreditID: &creditID,
	})
	if err != nil {
		t.Fatalf("Enroll failed: %v", err)
	}
	if !e.FinalPrice.Equal(decimal.NewFromInt(200)) {
		t.Fatalf("FinalPrice changed: got %s, want 200", e.FinalPrice.String())
	}
	if !e.CreditApplied.Equal(decimal.NewFromInt(50)) {
		t.Fatalf("CreditApplied: got %s, want 50", e.CreditApplied.String())
	}
	if e.StudentCreditID == nil || *e.StudentCreditID != creditID {
		t.Fatalf("StudentCreditID not persisted")
	}
	debits := fin.Debits()
	if len(debits) != 1 || !debits[0].Amount.Equal(decimal.NewFromInt(50)) || debits[0].EnrollmentID != e.ID {
		t.Fatalf("debit not recorded correctly: %+v", debits)
	}
}

func TestApplyCredit_GreaterThanFinalPrice_CapAtFinalPrice(t *testing.T) {
	s, _, cat, fin := creditSvc(t)
	b := seedCreditBatch(t, cat, 200)

	studentID := uuid.New()
	creditID := uuid.New()
	fin.SeedCredit(&StudentCredit{
		ID:        creditID,
		StudentID: studentID,
		Balance:   decimal.NewFromInt(300),
		IsActive:  true,
	})

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:       studentID,
		CourseBatchID:   b.ID,
		Format:          FormatRegular,
		Mode:            ModeOnline,
		Source:          SourceB2C,
		StudentCreditID: &creditID,
	})
	if err != nil {
		t.Fatalf("Enroll failed: %v", err)
	}
	if !e.FinalPrice.Equal(decimal.NewFromInt(200)) {
		t.Fatalf("FinalPrice changed: got %s, want 200", e.FinalPrice.String())
	}
	if !e.CreditApplied.Equal(decimal.NewFromInt(200)) {
		t.Fatalf("CreditApplied not capped: got %s, want 200", e.CreditApplied.String())
	}
	debits := fin.Debits()
	if len(debits) != 1 || !debits[0].Amount.Equal(decimal.NewFromInt(200)) {
		t.Fatalf("debit not capped: %+v", debits)
	}
}

func TestApplyCredit_NoStudentCreditID_NoOp(t *testing.T) {
	s, _, cat, fin := creditSvc(t)
	b := seedCreditBatch(t, cat, 200)

	e, err := s.Enroll(context.Background(), EnrollInput{
		StudentID:     uuid.New(),
		CourseBatchID: b.ID,
		Format:        FormatRegular,
		Mode:          ModeOnline,
		Source:        SourceB2C,
	})
	if err != nil {
		t.Fatalf("Enroll failed: %v", err)
	}
	if !e.CreditApplied.Equal(decimal.Zero) {
		t.Fatalf("CreditApplied: got %s, want 0", e.CreditApplied.String())
	}
	if e.StudentCreditID != nil {
		t.Fatalf("StudentCreditID should be nil")
	}
	if len(fin.Debits()) != 0 {
		t.Fatalf("no debit should be recorded")
	}
}

func TestApplyCredit_StudentCreditDomainStub_Returns_AvailableBalance(t *testing.T) {
	fin := newFakeFinanceReader()
	studentID := uuid.New()
	creditID := uuid.New()
	fin.SeedCredit(&StudentCredit{
		ID:        creditID,
		StudentID: studentID,
		Balance:   decimal.NewFromInt(75),
		IsActive:  true,
	})

	got, err := fin.GetStudentCredit(context.Background(), creditID)
	if err != nil {
		t.Fatalf("GetStudentCredit failed: %v", err)
	}
	if !got.Balance.Equal(decimal.NewFromInt(75)) {
		t.Fatalf("balance: got %s, want 75", got.Balance.String())
	}
	if got.StudentID != studentID || !got.IsActive {
		t.Fatalf("credit fields not returned correctly: %+v", got)
	}

	enrollID := uuid.New()
	if err := fin.DebitStudentCredit(context.Background(), creditID, decimal.NewFromInt(30), enrollID); err != nil {
		t.Fatalf("DebitStudentCredit failed: %v", err)
	}
	got2, _ := fin.GetStudentCredit(context.Background(), creditID)
	if !got2.Balance.Equal(decimal.NewFromInt(45)) {
		t.Fatalf("balance after debit: got %s, want 45", got2.Balance.String())
	}
	debits := fin.Debits()
	if len(debits) != 1 || !debits[0].Amount.Equal(decimal.NewFromInt(30)) || debits[0].EnrollmentID != enrollID {
		t.Fatalf("debit record incorrect: %+v", debits)
	}
}
