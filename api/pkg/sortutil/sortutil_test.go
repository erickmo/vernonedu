package sortutil_test

import (
	"testing"

	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name    string
		raw     string
		wantCol string
		wantDir string
		wantNil bool
	}{
		{"asc", `[["name",1]]`, "name", "ASC", false},
		{"desc", `[["created_at",-1]]`, "created_at", "DESC", false},
		{"empty", "", "", "", true},
		{"invalid json", "notjson", "", "", true},
		{"empty array", "[]", "", "", true},
		{"missing dir", `[["name"]]`, "", "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := sortutil.Parse(tt.raw)
			if tt.wantNil {
				if got != nil {
					t.Errorf("Parse(%q) = %+v, want nil", tt.raw, got)
				}
				return
			}
			if got == nil {
				t.Fatalf("Parse(%q) = nil, want non-nil", tt.raw)
			}
			if got.Column != tt.wantCol || got.Dir != tt.wantDir {
				t.Errorf("Parse(%q) = {%q, %q}, want {%q, %q}", tt.raw, got.Column, got.Dir, tt.wantCol, tt.wantDir)
			}
		})
	}
}

func TestOrderByClause(t *testing.T) {
	allowed := map[string]string{
		"name":       "s.name",
		"created_at": "s.created_at",
	}

	tests := []struct {
		name    string
		sort    *sortutil.Sort
		want    string
	}{
		{"nil sort", nil, "ORDER BY s.created_at DESC"},
		{"valid asc", &sortutil.Sort{Column: "name", Dir: "ASC"}, "ORDER BY s.name ASC"},
		{"valid desc", &sortutil.Sort{Column: "created_at", Dir: "DESC"}, "ORDER BY s.created_at DESC"},
		{"unknown col falls back", &sortutil.Sort{Column: "injected; DROP TABLE", Dir: "ASC"}, "ORDER BY s.created_at DESC"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := sortutil.OrderByClause(tt.sort, allowed, "s.created_at DESC")
			if got != tt.want {
				t.Errorf("OrderByClause() = %q, want %q", got, tt.want)
			}
		})
	}
}
