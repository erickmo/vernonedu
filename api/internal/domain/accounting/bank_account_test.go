package accounting

import (
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestBankAccountValidate_NameRequired(t *testing.T) {
	b := &BankAccount{BranchID: uuid.New(), Name: " "}
	if err := b.Validate(); err != ErrBankAccountNameRequired {
		t.Fatalf("expected ErrBankAccountNameRequired, got %v", err)
	}
}

func TestBankAccountValidate_NameTooLong(t *testing.T) {
	b := &BankAccount{BranchID: uuid.New(), Name: strings.Repeat("x", BankAccountNameMaxLen+1)}
	if err := b.Validate(); err != ErrBankAccountNameTooLong {
		t.Fatalf("expected ErrBankAccountNameTooLong, got %v", err)
	}
}

func TestBankAccountValidate_BranchRequired(t *testing.T) {
	b := &BankAccount{Name: "BCA Jakarta"}
	if err := b.Validate(); err != ErrBankAccountBranch {
		t.Fatalf("expected ErrBankAccountBranch, got %v", err)
	}
}

func TestBankAccountValidate_DefaultsCurrency(t *testing.T) {
	b := &BankAccount{BranchID: uuid.New(), Name: "Cash"}
	if err := b.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if b.Currency != CurrencyIDR {
		t.Fatalf("expected currency=%s, got %s", CurrencyIDR, b.Currency)
	}
}

func TestBankAccountValidate_BadCurrency(t *testing.T) {
	b := &BankAccount{BranchID: uuid.New(), Name: "Cash", Currency: "RUPIAH"}
	if err := b.Validate(); err != ErrBankAccountCurrency {
		t.Fatalf("expected ErrBankAccountCurrency, got %v", err)
	}
}

func TestIsValidAccountType(t *testing.T) {
	cases := map[string]bool{
		"asset": true, "liability": true, "equity": true,
		"revenue": true, "expense": true, "bogus": false, "": false,
	}
	for in, want := range cases {
		if got := IsValidAccountType(in); got != want {
			t.Errorf("IsValidAccountType(%q)=%v, want %v", in, got, want)
		}
	}
}

func TestIsValidTxnType(t *testing.T) {
	if !IsValidTxnType(TxnTypeDebit) || !IsValidTxnType(TxnTypeCredit) {
		t.Fatal("expected debit/credit to be valid")
	}
	if IsValidTxnType("transfer") {
		t.Fatal("transfer should not be valid txn type")
	}
}
