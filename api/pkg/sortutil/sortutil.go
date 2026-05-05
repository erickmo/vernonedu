package sortutil

import (
	"encoding/json"
	"fmt"
)

// Sort holds a parsed sort directive from the frontend.
type Sort struct {
	Column string // frontend key, e.g. "name"
	Dir    string // "ASC" or "DESC"
}

// Parse parses the frontend sort query param format: [["column",1]] or [["column",-1]].
// Returns nil on invalid or empty input.
func Parse(raw string) *Sort {
	if raw == "" {
		return nil
	}
	var arr [][]any
	if err := json.Unmarshal([]byte(raw), &arr); err != nil || len(arr) == 0 {
		return nil
	}
	first := arr[0]
	if len(first) < 2 {
		return nil
	}
	col, ok := first[0].(string)
	if !ok || col == "" {
		return nil
	}
	dir := "ASC"
	if num, ok := first[1].(float64); ok && num < 0 {
		dir = "DESC"
	}
	return &Sort{Column: col, Dir: dir}
}

// OrderByClause builds a safe ORDER BY clause.
// allowed maps frontend column key → SQL column expression (prevents SQL injection).
// defaultExpr is used when s is nil or the column is not in the whitelist.
func OrderByClause(s *Sort, allowed map[string]string, defaultExpr string) string {
	if s == nil {
		return fmt.Sprintf("ORDER BY %s", defaultExpr)
	}
	col, ok := allowed[s.Column]
	if !ok {
		return fmt.Sprintf("ORDER BY %s", defaultExpr)
	}
	return fmt.Sprintf("ORDER BY %s %s", col, s.Dir)
}
