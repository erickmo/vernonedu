package payable_test

import (
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
)

func TestNewPayable_Success(t *testing.T) {
	recipientID := uuid.New()
	batchID := uuid.New()

	p, err := payable.NewPayable(
		payable.TypeFacilitator,
		recipientID,
		"Budi Santoso",
		&batchID,
		500000,
		payable.SourceAuto,
		nil,
		"session fee",
	)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if p.Type != payable.TypeFacilitator {
		t.Errorf("expected type %s, got %s", payable.TypeFacilitator, p.Type)
	}
	if p.Amount != 500000 {
		t.Errorf("expected amount 500000, got %d", p.Amount)
	}
	if p.Status != payable.StatusPending {
		t.Errorf("expected status pending, got %s", p.Status)
	}
	if p.Source != payable.SourceAuto {
		t.Errorf("expected source auto, got %s", p.Source)
	}
}

func TestNewPayable_EmptyRecipientName(t *testing.T) {
	_, err := payable.NewPayable(payable.TypeFacilitator, uuid.New(), "", nil, 100000, payable.SourceManual, nil, "")
	if err == nil {
		t.Fatal("expected error for empty recipient name")
	}
}

func TestNewPayable_ZeroAmount(t *testing.T) {
	_, err := payable.NewPayable(payable.TypeFacilitator, uuid.New(), "Budi", nil, 0, payable.SourceManual, nil, "")
	if err == nil {
		t.Fatal("expected error for zero amount")
	}
}

func TestNewPayable_NegativeAmount(t *testing.T) {
	_, err := payable.NewPayable(payable.TypeFacilitator, uuid.New(), "Budi", nil, -1, payable.SourceManual, nil, "")
	if err == nil {
		t.Fatal("expected error for negative amount")
	}
}

func TestNewPayable_InvalidType(t *testing.T) {
	_, err := payable.NewPayable("unknown_type", uuid.New(), "Budi", nil, 100000, payable.SourceManual, nil, "")
	if err != payable.ErrInvalidType {
		t.Fatalf("expected ErrInvalidType, got: %v", err)
	}
}

func TestNewPayable_UniqueIDs(t *testing.T) {
	p1, _ := payable.NewPayable(payable.TypeFacilitator, uuid.New(), "A", nil, 1, payable.SourceManual, nil, "")
	p2, _ := payable.NewPayable(payable.TypeFacilitator, uuid.New(), "B", nil, 1, payable.SourceManual, nil, "")
	if p1.ID == p2.ID {
		t.Error("expected unique IDs")
	}
}

func TestHutangAccount(t *testing.T) {
	cases := map[string]string{
		payable.TypeFacilitator:             payable.AccountHutangFasilitator,
		payable.TypeCommissionCourseCreator: payable.AccountHutangCourseCreator,
		payable.TypeCommissionDeptLeader:    payable.AccountHutangDeptLeader,
		payable.TypeCommissionOpLeader:      payable.AccountHutangOpLeader,
		payable.TypeMarketingPartner:        payable.AccountHutangMarketing,
	}
	for pType, want := range cases {
		got := payable.HutangAccount(pType)
		if got != want {
			t.Errorf("HutangAccount(%s) = %s, want %s", pType, got, want)
		}
	}
}

func TestExpenseAccount(t *testing.T) {
	cases := map[string]string{
		payable.TypeFacilitator:             payable.AccountBiayaFasilitator,
		payable.TypeCommissionCourseCreator: payable.AccountKomisiCourseCreator,
		payable.TypeCommissionDeptLeader:    payable.AccountKomisiDeptLeader,
		payable.TypeCommissionOpLeader:      payable.AccountKomisiOpLeader,
		payable.TypeMarketingPartner:        payable.AccountBiayaMarketing,
	}
	for pType, want := range cases {
		got := payable.ExpenseAccount(pType)
		if got != want {
			t.Errorf("ExpenseAccount(%s) = %s, want %s", pType, got, want)
		}
	}
}
