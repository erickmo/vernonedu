package main

import (
	"github.com/vernonedu/vernonedu2/backend/domains/catalog"
	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"github.com/vernonedu/vernonedu2/backend/domains/enrollment"
	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/domains/identity"
	"github.com/vernonedu/vernonedu2/backend/domains/partnerships"
	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/db"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/server"
	"github.com/vernonedu/vernonedu2/backend/internal/worker"
	"go.uber.org/fx"
)

func main() {
	app := fx.New(
		// Infrastructure
		fx.Provide(server.NewConfig),
		fx.Provide(server.NewZapLogger),
		fx.Provide(db.NewPool),
		fx.Provide(events.NewBus),

		// HTTP server
		server.Module,

		// Worker primitives (PDF + storage + verify URL) feeding credentialing.
		worker.Module,

		// Domain modules
		identity.Module,
		catalog.Module,
		enrollment.Module,
		finance.Module,
		credentialing.Module,
		partnerships.Module,
		platform.Module,

		fx.NopLogger,
	)

	app.Run()
}
