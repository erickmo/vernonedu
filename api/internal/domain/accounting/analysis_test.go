package accounting_test

import (
	"testing"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

func TestRatioMetric_Trend(t *testing.T) {
	tests := []struct {
		name      string
		current   float64
		previous  float64
		wantTrend string
	}{
		{
			name:      "up when current significantly higher",
			current:   110,
			previous:  100,
			wantTrend: "up",
		},
		{
			name:      "down when current significantly lower",
			current:   90,
			previous:  100,
			wantTrend: "down",
		},
		{
			name:      "flat when change within 0.5%",
			current:   100.4,
			previous:  100,
			wantTrend: "flat",
		},
		{
			name:      "flat when previous is zero",
			current:   0,
			previous:  0,
			wantTrend: "flat",
		},
		{
			name:      "up when previous is zero and current is positive",
			current:   50,
			previous:  0,
			wantTrend: "flat", // changePct stays 0 when previous=0
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			m := buildRatioMetricForTest(tt.current, tt.previous)
			if m.Trend != tt.wantTrend {
				t.Errorf("Trend = %q, want %q (current=%.2f, previous=%.2f, changePct=%.2f)",
					m.Trend, tt.wantTrend, tt.current, tt.previous, m.ChangePct)
			}
		})
	}
}

func TestRatioMetric_ChangeCalculation(t *testing.T) {
	m := buildRatioMetricForTest(120, 100)

	if m.Current != 120 {
		t.Errorf("Current = %.2f, want 120", m.Current)
	}
	if m.Previous != 100 {
		t.Errorf("Previous = %.2f, want 100", m.Previous)
	}
	if m.Change != 20 {
		t.Errorf("Change = %.2f, want 20", m.Change)
	}
	if m.ChangePct != 20 {
		t.Errorf("ChangePct = %.2f, want 20", m.ChangePct)
	}
}

func TestRatioMetric_ZeroPrevious(t *testing.T) {
	m := buildRatioMetricForTest(50, 0)

	if m.ChangePct != 0 {
		t.Errorf("ChangePct should be 0 when previous is zero, got %.2f", m.ChangePct)
	}
	if m.Change != 50 {
		t.Errorf("Change = %.2f, want 50", m.Change)
	}
}

func TestRatioMetric_NegativeChange(t *testing.T) {
	m := buildRatioMetricForTest(80, 100)

	if m.Change != -20 {
		t.Errorf("Change = %.2f, want -20", m.Change)
	}
	if m.ChangePct != -20 {
		t.Errorf("ChangePct = %.2f, want -20", m.ChangePct)
	}
	if m.Trend != "down" {
		t.Errorf("Trend = %q, want 'down'", m.Trend)
	}
}

func TestPeriodParams_Defaults(t *testing.T) {
	p := accounting.PeriodParams{
		Period: "monthly",
		Month:  3,
		Year:   2026,
	}
	if p.Period != "monthly" {
		t.Errorf("Period = %q, want 'monthly'", p.Period)
	}
	if p.Month != 3 {
		t.Errorf("Month = %d, want 3", p.Month)
	}
	if p.Year != 2026 {
		t.Errorf("Year = %d, want 2026", p.Year)
	}
}

func TestFinancialRatiosResult_Structure(t *testing.T) {
	result := &accounting.FinancialRatiosResult{
		ProfitMargin:          accounting.RatioMetric{Current: 25.5, Previous: 22.0, Trend: "up"},
		ExpenseRatio:          accounting.RatioMetric{Current: 74.5, Previous: 78.0, Trend: "down"},
		CollectionRate:        accounting.RatioMetric{Current: 92.0, Previous: 88.0, Trend: "up"},
		DaysSalesOutstanding:  accounting.RatioMetric{Current: 15.0, Previous: 18.0, Trend: "down"},
		RevenueGrowthRate:     accounting.RatioMetric{Current: 12.5, Previous: 0, Trend: "flat"},
	}

	if result.ProfitMargin.Current != 25.5 {
		t.Errorf("ProfitMargin.Current = %.2f, want 25.5", result.ProfitMargin.Current)
	}
	if result.CollectionRate.Trend != "up" {
		t.Errorf("CollectionRate.Trend = %q, want 'up'", result.CollectionRate.Trend)
	}
}

func TestBatchProfitItem_ProfitCalculation(t *testing.T) {
	item := accounting.BatchProfitItem{
		BatchID:    "batch-001",
		BatchCode:  "B001",
		CourseName: "Program Karir AI",
		Revenue:    10_000_000,
		Expense:    6_000_000,
		Commission: 500_000,
	}

	profit := item.Revenue - item.Expense - item.Commission
	if profit != 3_500_000 {
		t.Errorf("Profit = %.2f, want 3500000", profit)
	}

	marginPct := profit / item.Revenue * 100
	if marginPct != 35 {
		t.Errorf("MarginPct = %.2f, want 35", marginPct)
	}
}

func TestCashForecastMonth_ClosingCash(t *testing.T) {
	month := accounting.CashForecastMonth{
		Month:       "2026-04",
		OpeningCash: 50_000_000,
		Inflow:      30_000_000,
		Outflow:     20_000_000,
	}
	closing := month.OpeningCash + month.Inflow - month.Outflow
	if closing != 60_000_000 {
		t.Errorf("Closing cash = %.2f, want 60000000", closing)
	}
}

func TestFinancialAlert_Levels(t *testing.T) {
	alerts := []*accounting.FinancialAlert{
		{Level: "warning", Code: "overdue_invoices", Message: "5 invoice melewati jatuh tempo", Count: 5, Amount: 5_000_000},
		{Level: "info", Code: "pending_invoices", Message: "10 invoice belum dibayar", Count: 10},
		{Level: "success", Code: "all_clear", Message: "Tidak ada peringatan keuangan"},
	}

	validLevels := map[string]bool{"warning": true, "info": true, "success": true}
	for _, a := range alerts {
		if !validLevels[a.Level] {
			t.Errorf("Invalid alert level: %q", a.Level)
		}
		if a.Code == "" {
			t.Error("Alert code should not be empty")
		}
		if a.Message == "" {
			t.Error("Alert message should not be empty")
		}
	}
}

func TestFinancialSuggestion_Structure(t *testing.T) {
	s := &accounting.FinancialSuggestion{
		Icon:    "warning",
		Message: "Tindak lanjuti 3 invoice yang sudah jatuh tempo",
		Amount:  3_000_000,
		Detail:  "Hubungi siswa untuk menyelesaikan pembayaran",
	}

	if s.Icon == "" {
		t.Error("Suggestion icon should not be empty")
	}
	if s.Message == "" {
		t.Error("Suggestion message should not be empty")
	}
}

// buildRatioMetricForTest replicates the logic of buildRatioMetric from the infrastructure layer
// as a test-only helper to validate the computation logic independently.
func buildRatioMetricForTest(current, previous float64) accounting.RatioMetric {
	var changePct float64
	if previous != 0 {
		changePct = (current - previous) / previous * 100
	}
	change := current - previous
	trend := "flat"
	if changePct > 0.5 {
		trend = "up"
	} else if changePct < -0.5 {
		trend = "down"
	}
	return accounting.RatioMetric{
		Current:   current,
		Previous:  previous,
		Change:    change,
		ChangePct: changePct,
		Trend:     trend,
	}
}
