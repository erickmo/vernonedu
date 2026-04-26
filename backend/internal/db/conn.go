package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Params groups FX dependencies for NewPool.
type Params struct {
	fx.In
	Config *config.Config
	Log    *zap.Logger
}

// NewPool constructs a pgxpool.Pool from Config and registers lifecycle hooks.
func NewPool(lc fx.Lifecycle, p Params) (*pgxpool.Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(p.Config.DB.URL)
	if err != nil {
		return nil, fmt.Errorf("db: parse config: %w", err)
	}

	poolCfg.MaxConns = int32(p.Config.DB.MaxOpenConns)
	poolCfg.MinConns = int32(p.Config.DB.MaxIdleConns)
	poolCfg.MaxConnLifetime = p.Config.DB.ConnMaxLifetime
	poolCfg.MaxConnIdleTime = 10 * time.Minute

	pool, err := pgxpool.NewWithConfig(context.Background(), poolCfg)
	if err != nil {
		return nil, fmt.Errorf("db: create pool: %w", err)
	}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			if err := pool.Ping(ctx); err != nil {
				return fmt.Errorf("db: ping failed: %w", err)
			}
			p.Log.Info("database connected", zap.String("host", p.Config.DB.Host))
			return nil
		},
		OnStop: func(ctx context.Context) error {
			pool.Close()
			p.Log.Info("database pool closed")
			return nil
		},
	})

	return pool, nil
}
