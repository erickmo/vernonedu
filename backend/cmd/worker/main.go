package main

import (
	"context"
	"time"

	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/db"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/server"
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
		fx.Provide(platform.NewEmailSender),
		fx.Provide(platform.NewInAppSender),
		fx.Provide(platform.NewPushSender),
		fx.Provide(platform.NewSenders),
		fx.Provide(platform.NewService),

		fx.Invoke(runWorkers),

		fx.NopLogger,
	)

	app.Run()
}
