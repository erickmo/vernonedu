package get_trial_balance_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	gettrialbalance "github.com/vernonedu/entrepreneurship-api/internal/query/get_trial_balance"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// ---- mock ----

type mockRepo struct {
	tb  *accounting.TrialBalance
	err error
}

func (m *mockRepo) GetBalanceSheet(_ context.Context, _ accounting.ReportPeriod) (*accounting.BalanceSheet, error) {
	return nil, nil
}

func (m *mockRepo) GetProfitLoss(_ context.Context, _ accounting.ReportPeriod) (*accounting.ProfitLoss, error) {
	return nil, nil
}

func (m *mockRepo) GetCashFlow(_ context.Context, _ accounting.ReportPeriod) (*accounting.CashFlow, error) {
	return nil, nil
}

func (m *mockRepo) GetGeneralLedger(_ context.Context, _ string, _ accounting.ReportPeriod) (*accounting.GeneralLedger, error) {
	return nil, nil
}

func (m *mockRepo) GetTrialBalance(_ context.Context, _ accounting.ReportPeriod) (*accounting.TrialBalance, error) {
	return m.tb, m.err
}

// ---- helpers ----

func makeTB() *accounting.TrialBalance {
	f, _ := time.Parse("2006-01-02", "2026-01-01")
	t, _ := time.Parse("2006-01-02", "2026-01-31")
	return &accounting.TrialBalance{
		Period: accounting.ReportPeriod{From: f, To: t},
		Lines: []*accounting.TrialBalanceLine{
			{AccountCode: "1100", AccountName: "Cash", AccountType: "asset", Debit: 5000, Credit: 0},
			{AccountCode: "3000", AccountName: "Equity", AccountType: "equity", Debit: 0, Credit: 5000},
		},
		TotalDebit:  5000,
		TotalCredit: 5000,
		IsBalanced:  true,
	}
}

// ---- tests ----

func TestHandle_Success(t *testing.T) {
	fmt.Println("Scenario: GetTrialBalance — success")
	fmt.Println("Goal:     handler returns TrialBalanceRM with balanced totals")

	repo := &mockRepo{tb: makeTB()}
	h := gettrialbalance.NewHandler(repo)

	result, err := h.Handle(context.Background(), &gettrialbalance.GetTrialBalanceQuery{
		From: "2026-01-01",
		To:   "2026-01-31",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	rm, ok := result.(*gettrialbalance.TrialBalanceRM)
	if !ok {
		t.Fatalf("unexpected type: %T", result)
	}
	if !rm.IsBalanced {
		t.Errorf("expected IsBalanced=true")
	}
	if rm.TotalDebit != 5000 {
		t.Errorf("expected TotalDebit=5000, got %f", rm.TotalDebit)
	}
	if len(rm.Lines) != 2 {
		t.Errorf("expected 2 lines, got %d", len(rm.Lines))
	}
	fmt.Printf("Result: balanced=%v debit=%.0f credit=%.0f lines=%d\n", rm.IsBalanced, rm.TotalDebit, rm.TotalCredit, len(rm.Lines))
	fmt.Println("Status: PASS")
}

func TestHandle_InvalidQuery(t *testing.T) {
	fmt.Println("Scenario: GetTrialBalance — wrong query type")
	fmt.Println("Goal:     handler returns ErrInvalidQuery")

	repo := &mockRepo{}
	h := gettrialbalance.NewHandler(repo)

	_, err := h.Handle(context.Background(), struct{}{})
	if !errors.Is(err, gettrialbalance.ErrInvalidQuery) {
		t.Errorf("expected ErrInvalidQuery, got %v", err)
	}
	fmt.Println("Status: PASS")
}

func TestHandle_RepoError(t *testing.T) {
	fmt.Println("Scenario: GetTrialBalance — repository error")
	fmt.Println("Goal:     handler propagates repository error")

	repoErr := errors.New("db error")
	repo := &mockRepo{err: repoErr}
	h := gettrialbalance.NewHandler(repo)

	_, err := h.Handle(context.Background(), &gettrialbalance.GetTrialBalanceQuery{
		From: "2026-01-01",
		To:   "2026-01-31",
	})
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	fmt.Println("Status: PASS")
}
