package testdb

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

const defaultDSN = "postgres://vernonedu:vernonedu_secret@localhost:5432/vernonedu?sslmode=disable"

// New opens a pgx pool to the test database. The pool is closed via t.Cleanup.
// DATABASE_URL env overrides the default DSN. Use t.Skip if the DB is unreachable
// so unit-only runs (without local Postgres) don't fail.
func New(t *testing.T) *pgxpool.Pool {
	t.Helper()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = defaultDSN
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Skipf("testdb: cannot create pool: %v", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		t.Skipf("testdb: cannot ping db at %s: %v", dsn, err)
	}

	t.Cleanup(func() { pool.Close() })
	return pool
}

// Truncate empties one or more tables (schema-qualified) and resets identities.
func Truncate(t *testing.T, pool *pgxpool.Pool, tables ...string) {
	t.Helper()
	if len(tables) == 0 {
		return
	}
	list := ""
	for i, tbl := range tables {
		if i > 0 {
			list += ", "
		}
		list += tbl
	}
	q := fmt.Sprintf("TRUNCATE TABLE %s RESTART IDENTITY CASCADE", list)
	if _, err := pool.Exec(context.Background(), q); err != nil {
		t.Fatalf("testdb.Truncate(%s): %v", list, err)
	}
}
