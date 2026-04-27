package main

import (
	"context"
	"time"

	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/domains/franchise"
	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/db"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/server"
	"github.com/vernonedu/vernonedu2/backend/internal/worker"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

const (
	overdueCheckInterval  = 1 * time.Hour
	notificationBatchSize = 50
	notificationInterval  = 30 * time.Second
)

func runWorkers(
	lc fx.Lifecycle,
	financeSvc *finance.Service,
	franchiseSvc *franchise.Service,
	platformSvc *platform.Service,
	log *zap.Logger,
) {
	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			// Overdue terms checker
			go func() {
				ticker := time.NewTicker(overdueCheckInterval)
				defer ticker.Stop()
				for {
					select {
					case <-ticker.C:
						if err := financeSvc.MarkOverdueTerms(context.Background()); err != nil {
							log.Error("overdue terms check failed", zap.Error(err))
						}
					case <-ctx.Done():
						return
					}
				}
			}()

			// Overdue invoices checker
			go func() {
				ticker := time.NewTicker(overdueCheckInterval)
				defer ticker.Stop()
				for {
					select {
					case <-ticker.C:
						if err := financeSvc.MarkOverdueInvoices(context.Background()); err != nil {
							log.Error("overdue invoices check failed", zap.Error(err))
						}
					case <-ctx.Done():
						return
					}
				}
			}()

			// Franchise royalty overdue checker (conceptually runs monthly on the 15th)
			go func() {
				ticker := time.NewTicker(overdueCheckInterval)
				defer ticker.Stop()
				for {
					select {
					case <-ticker.C:
						if err := franchiseSvc.MarkOverdueRoyalties(context.Background()); err != nil {
							log.Error("franchise royalty overdue check failed", zap.Error(err))
						}
					case <-ctx.Done():
						return
					}
				}
			}()

			// Notification processor
			go func() {
				ticker := time.NewTicker(notificationInterval)
				defer ticker.Stop()
				for {
					select {
					case <-ticker.C:
						if err := platformSvc.ProcessPending(context.Background(), notificationBatchSize); err != nil {
							log.Error("notification processing failed", zap.Error(err))
						}
					case <-ctx.Done():
						return
					}
				}
			}()

			log.Info("workers started")
			return nil
		},
		OnStop: func(ctx context.Context) error {
			log.Info("workers stopped")
			return nil
		},
	})
}

func main() {
	app := fx.New(
		// Infrastructure
		fx.Provide(server.NewConfig),
		fx.Provide(server.NewZapLogger),
		fx.Provide(db.NewPool),
		fx.Provide(events.NewBus),

		// Finance + platform for workers
		fx.Provide(finance.NewRepository),
		fx.Provide(finance.NewService),
		fx.Provide(platform.NewRepository),
		fx.Provide(platform.NewService),

		// Franchise for royalty overdue worker
		fx.Provide(franchise.NewRepository),
		fx.Provide(franchise.NewService),

		// Credentialing async cert issuer
		worker.Module,
		fx.Provide(credentialing.NewRepository),
		fx.Provide(credentialing.NewService),
		fx.Invoke(credentialing.RegisterSubscriptions),

		fx.Invoke(runWorkers),

		fx.NopLogger,
	)

	app.Run()
}
