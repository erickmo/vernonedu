package get_balance_sheet_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	getbalancesheet "github.com/vernonedu/entrepreneurship-api/internal/query/get_balance_sheet"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// ---- mock ----

type mockRepo struct {
	bs  *accounting.BalanceSheet
	err error
}

func (m *mockRepo) GetBalanceSheet(_ context.Context, _ accounting.ReportPeriod) (*accounting.BalanceSheet, error) {
	return m.bs, m.err
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
	return nil, nil
}

// ---- helpers ----

func period(from, to string) accounting.ReportPeriod {
	f, _ := time.Parse("2006-01-02", from)
	t, _ := time.Parse("2006-01-02", to)
	return accounting.ReportPeriod{From: f, To: t}
}

func makeBS(p accounting.ReportPeriod) *accounting.BalanceSheet {
	return &accounting.BalanceSheet{
		Period: p,
		Assets: []*accounting.BalanceSheetLine{
			{AccountCode: "1100", AccountName: "Cash", AccountType: "asset", Balance: 5000},
		},
		TotalAssets: 5000,
		TotalLiab:   2000,
		TotalEquity: 3000,
		IsBalanced:       true,
	}
}

// ---- tests ----

func TestHandle_Success(t *testing.T) {
	fmt.Println("Scenario: GetBalanceSheet — success")
	fmt.Println("Goal:     handler returns BalanceSheetRM for given period")

	p := period("2026-01-01", "2026-01-31")
	repo := &mockRepo{bs: makeBS(p)}
	h := getbalancesheet.NewHandler(repo)

	result, err := h.Handle(context.Background(), &getbalancesheet.GetBalanceSheetQuery{
		From: "2026-01-01",
		To:   "2026-01-31",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	rm, ok := result.(*getbalancesheet.BalanceSheetRM)
	if !ok {
		t.Fatalf("unexpected type: %T", result)
	}
	if rm.From != "2026-01-01" {
		t.Errorf("expected From=2026-01-01, got %s", rm.From)
	}
	if !rm.IsBalanced {
		t.Errorf("expected IsBalanced=true")
	}
	if len(rm.Assets) != 1 {
		t.Errorf("expected 1 asset line, got %d", len(rm.Assets))
	}
	fmt.Printf("Result: from=%s to=%s balanced=%v assets=%d\n", rm.From, rm.To, rm.IsBalanced, len(rm.Assets))
	fmt.Println("Status: PASS")
}

func TestHandle_DefaultPeriod(t *testing.T) {
	fmt.Println("Scenario: GetBalanceSheet — empty period uses current month defaults")
	fmt.Println("Goal:     handler succeeds with empty From/To strings")

	now := time.Now()
	p := accounting.ReportPeriod{
		From: time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC),
		To:   now,
	}
	repo := &mockRepo{bs: makeBS(p)}
	h := getbalancesheet.NewHandler(repo)

	result, err := h.Handle(context.Background(), &getbalancesheet.GetBalanceSheetQuery{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result == nil {
		t.Fatal("expected non-nil result")
	}
	fmt.Println("Status: PASS")
}

func TestHandle_InvalidQuery(t *testing.T) {
	fmt.Println("Scenario: GetBalanceSheet — wrong query type")
	fmt.Println("Goal:     handler returns ErrInvalidQuery")

	repo := &mockRepo{}
	h := getbalancesheet.NewHandler(repo)

	_, err := h.Handle(context.Background(), "not-a-query")
	if !errors.Is(err, getbalancesheet.ErrInvalidQuery) {
		t.Errorf("expected ErrInvalidQuery, got %v", err)
	}
	fmt.Println("Status: PASS")
}

func TestHandle_RepoError(t *testing.T) {
	fmt.Println("Scenario: GetBalanceSheet — repository error")
	fmt.Println("Goal:     handler propagates repository error")

	repoErr := errors.New("db error")
	repo := &mockRepo{err: repoErr}
	h := getbalancesheet.NewHandler(repo)

	_, err := h.Handle(context.Background(), &getbalancesheet.GetBalanceSheetQuery{
		From: "2026-01-01",
		To:   "2026-01-31",
	})
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	fmt.Println("Status: PASS")
}
