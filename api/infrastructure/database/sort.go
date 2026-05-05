package database

import "fmt"

// buildOrderBy returns a safe ORDER BY clause.
// allowed maps frontend column key → SQL column expression.
// defaultExpr is used when sortBy is empty or not whitelisted.
func buildOrderBy(sortBy, sortDir string, allowed map[string]string, defaultExpr string) string {
	col, ok := allowed[sortBy]
	if !ok || col == "" {
		return fmt.Sprintf("ORDER BY %s", defaultExpr)
	}
	dir := "ASC"
	if sortDir == "DESC" || sortDir == "desc" {
		dir = "DESC"
	}
	return fmt.Sprintf("ORDER BY %s %s", col, dir)
}
