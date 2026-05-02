package accounting

import "testing"

func TestBuildTree_IndonesianCOA(t *testing.T) {
	flat := []*ChartOfAccount{
		{Code: "1000", Name: "Aset", AccountType: "asset", IsActive: true},
		{Code: "1100", Name: "Kas & Bank", AccountType: "asset", IsActive: true},
		{Code: "1110", Name: "Kas Tunai", AccountType: "asset", IsActive: true},
		{Code: "1120", Name: "Bank BCA", AccountType: "asset", IsActive: true},
		{Code: "2000", Name: "Kewajiban", AccountType: "liability", IsActive: true},
	}

	tree := BuildTree(flat)
	if len(tree) != 2 {
		t.Fatalf("expected 2 roots, got %d", len(tree))
	}
	if tree[0].Code != "1000" {
		t.Fatalf("expected root 1000 first, got %s", tree[0].Code)
	}
	if len(tree[0].Children) != 1 || tree[0].Children[0].Code != "1100" {
		t.Fatalf("expected 1100 under 1000, got %v", tree[0].Children)
	}
	if len(tree[0].Children[0].Children) != 2 {
		t.Fatalf("expected 2 grandchildren under 1100, got %d", len(tree[0].Children[0].Children))
	}
}

func TestBuildTree_Empty(t *testing.T) {
	if got := BuildTree(nil); got != nil {
		t.Fatalf("expected nil, got %v", got)
	}
}
