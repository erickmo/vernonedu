package accounting_test

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

func TestNewInvoice_CreatesWithCorrectDefaults(t *testing.T) {
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
		BatchName:     "Batch A",
		Source:        "",
	}

	inv, err := accounting.NewInvoice(params)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if inv.ID == uuid.Nil {
		t.Error("expected non-nil UUID")
	}
	if inv.Status != accounting.InvoiceStatusDraft {
		t.Errorf("expected status %q, got %q", accounting.InvoiceStatusDraft, inv.Status)
	}
	if inv.Source != accounting.SourceManual {
		t.Errorf("expected source %q, got %q", accounting.SourceManual, inv.Source)
	}
	if inv.Amount != 500000 {
		t.Errorf("expected amount 500000, got %f", inv.Amount)
	}
}

func TestNewInvoice_FailsWithZeroAmount(t *testing.T) {
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        0,
		DueDate:       &dueDate,
	}

	_, err := accounting.NewInvoice(params)
	if err == nil {
		t.Fatal("expected error for zero amount, got nil")
	}
}

func TestNewInvoice_FailsWithEmptyPaymentMethod(t *testing.T) {
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "",
		Amount:        100000,
		DueDate:       &dueDate,
	}

	_, err := accounting.NewInvoice(params)
	if err == nil {
		t.Fatal("expected error for empty payment method, got nil")
	}
}

func TestGenerateInvoiceNumber_Format(t *testing.T) {
	seq := 42
	year := time.Now().Year()
	result := accounting.GenerateInvoiceNumber(seq)
	expected := "INV-" + itoa(year) + "-0042"
	if result != expected {
		t.Errorf("expected %q, got %q", expected, result)
	}
}

func TestGenerateInvoiceNumber_PaddingFourDigits(t *testing.T) {
	result := accounting.GenerateInvoiceNumber(1)
	// Should have 4-digit sequence: 0001
	if len(result) < 12 { // "INV-2026-0001" = 13 chars minimum
		t.Errorf("invoice number too short: %q", result)
	}
}

func TestMarkPaid_SetsAllFieldsCorrectly(t *testing.T) {
	dueDate := time.Now().Add(-1 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)

	paidAt := time.Now()
	paidAmount := 500000.0
	paidBy := uuid.New()
	proof := "https://proof.example.com/receipt.pdf"

	err := inv.MarkPaid(paidAt, paidAmount, paidBy, proof)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if inv.Status != accounting.InvoiceStatusPaid {
		t.Errorf("expected status %q, got %q", accounting.InvoiceStatusPaid, inv.Status)
	}
	if inv.PaidDate == nil {
		t.Error("expected PaidDate to be set")
	}
	if inv.PaidAmount == nil || *inv.PaidAmount != paidAmount {
		t.Errorf("expected PaidAmount %f, got %v", paidAmount, inv.PaidAmount)
	}
	if inv.PaidBy == nil || *inv.PaidBy != paidBy {
		t.Errorf("expected PaidBy %s, got %v", paidBy, inv.PaidBy)
	}
	if inv.PaymentProof == nil || *inv.PaymentProof != proof {
		t.Errorf("expected PaymentProof %q, got %v", proof, inv.PaymentProof)
	}
}

func TestCancel_SetsCancelledFields(t *testing.T) {
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)

	reason := "Student withdrew"
	err := inv.Cancel(reason)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if inv.Status != accounting.InvoiceStatusCancelled {
		t.Errorf("expected status %q, got %q", accounting.InvoiceStatusCancelled, inv.Status)
	}
	if inv.CancelledAt == nil {
		t.Error("expected CancelledAt to be set")
	}
	if inv.CancelReason != reason {
		t.Errorf("expected CancelReason %q, got %q", reason, inv.CancelReason)
	}
}

func TestDomainInvariants_CannotPayCancelled(t *testing.T) {
	dueDate := time.Now().Add(-1 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)
	_ = inv.Cancel("test reason")

	err := inv.MarkPaid(time.Now(), 500000, uuid.New(), "")
	if err == nil {
		t.Fatal("expected error when paying a cancelled invoice")
	}
	if err != accounting.ErrInvoiceAlreadyCancelled {
		t.Errorf("expected ErrInvoiceAlreadyCancelled, got %v", err)
	}
}

func TestDomainInvariants_CannotCancelPaid(t *testing.T) {
	dueDate := time.Now().Add(-1 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)
	_ = inv.MarkPaid(time.Now(), 500000, uuid.New(), "")

	err := inv.Cancel("try to cancel paid")
	if err == nil {
		t.Fatal("expected error when cancelling a paid invoice")
	}
	if err != accounting.ErrInvoiceAlreadyPaid {
		t.Errorf("expected ErrInvoiceAlreadyPaid, got %v", err)
	}
}

func TestDomainInvariants_CannotPayAlreadyPaid(t *testing.T) {
	dueDate := time.Now().Add(-1 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)
	_ = inv.MarkPaid(time.Now(), 500000, uuid.New(), "")

	err := inv.MarkPaid(time.Now(), 500000, uuid.New(), "")
	if err == nil {
		t.Fatal("expected error when paying an already-paid invoice")
	}
	if err != accounting.ErrInvoiceAlreadyPaid {
		t.Errorf("expected ErrInvoiceAlreadyPaid, got %v", err)
	}
}

func TestSend_SetsStatusToSent(t *testing.T) {
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	params := accounting.NewInvoiceParams{
		PaymentMethod: "upfront",
		Amount:        500000,
		DueDate:       &dueDate,
	}
	inv, _ := accounting.NewInvoice(params)

	err := inv.Send()
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if inv.Status != accounting.InvoiceStatusSent {
		t.Errorf("expected status %q, got %q", accounting.InvoiceStatusSent, inv.Status)
	}
	if inv.SentAt == nil {
		t.Error("expected SentAt to be set")
	}
}

// itoa converts int to string without importing strconv
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	digits := []byte{}
	for n > 0 {
		digits = append([]byte{byte('0' + n%10)}, digits...)
		n /= 10
	}
	return string(digits)
}
