package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"go.uber.org/fx"

	// infrastructure
	"github.com/vernonedu/entrepreneurship-api/infrastructure/config"
	"github.com/vernonedu/entrepreneurship-api/infrastructure/database"
	// pkg
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/hooks"
	"github.com/vernonedu/entrepreneurship-api/pkg/jwtutil"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	// commands
	createbusiness "github.com/vernonedu/entrepreneurship-api/internal/command/create_business"
	createcanvas "github.com/vernonedu/entrepreneurship-api/internal/command/create_canvas"
	createdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/create_designthinking"
	createitem "github.com/vernonedu/entrepreneurship-api/internal/command/create_item"
	createuser "github.com/vernonedu/entrepreneurship-api/internal/command/create_user"
	deletebusiness "github.com/vernonedu/entrepreneurship-api/internal/command/delete_business"
	deletecanvas "github.com/vernonedu/entrepreneurship-api/internal/command/delete_canvas"
	deletedesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/delete_designthinking"
	deleteitem "github.com/vernonedu/entrepreneurship-api/internal/command/delete_item"
	deleteuser "github.com/vernonedu/entrepreneurship-api/internal/command/delete_user"
	registeruser "github.com/vernonedu/entrepreneurship-api/internal/command/register_user"
	updatebusiness "github.com/vernonedu/entrepreneurship-api/internal/command/update_business"
	updatecanvas "github.com/vernonedu/entrepreneurship-api/internal/command/update_canvas"
	updatedesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/update_designthinking"
	updateitem "github.com/vernonedu/entrepreneurship-api/internal/command/update_item"
	updateuser "github.com/vernonedu/entrepreneurship-api/internal/command/update_user"
	// queries
	getbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/get_business"
	getcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/get_canvas"
	getdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/get_designthinking"
	getitem "github.com/vernonedu/entrepreneurship-api/internal/query/get_item"
	getuser "github.com/vernonedu/entrepreneurship-api/internal/query/get_user"
	listbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/list_business"
	listcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/list_canvas"
	listdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/list_designthinking"
	listitemsbycanvas "github.com/vernonedu/entrepreneurship-api/internal/query/list_items_by_canvas"
	listuser "github.com/vernonedu/entrepreneurship-api/internal/query/list_user"
	searchbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/search_business"
	searchcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/search_canvas"
	searchdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/search_designthinking"
	searchuser "github.com/vernonedu/entrepreneurship-api/internal/query/search_user"
	// handlers
	httphandler "github.com/vernonedu/entrepreneurship-api/internal/delivery/http"
)

// queryHandlerAdapter adapts handlers that accept interface{} to querybus.QueryHandler
type queryHandlerAdapter struct {
	fn func(ctx context.Context, q interface{}) (interface{}, error)
}

func (a *queryHandlerAdapter) Handle(ctx context.Context, q querybus.Query) (interface{}, error) {
	return a.fn(ctx, q)
}

func adaptQueryHandler(fn func(ctx context.Context, q interface{}) (interface{}, error)) querybus.QueryHandler {
	return &queryHandlerAdapter{fn: fn}
}

func main() {
	app := fx.New(
		fx.Provide(
			// Config
			config.Load,

			// Database
			newDB,

			// EventBus
			func() eventbus.EventBus {
				return eventbus.NewInMemoryEventBus()
			},

			// CommandBus with ValidationHook and LoggingHook
			func() *commandbus.SimpleCommandBus {
				cb := commandbus.NewCommandBus()
				cb.AddHook(hooks.NewValidationHook())
				cb.AddHook(hooks.NewLoggingHook())
				return cb
			},
			func(cb *commandbus.SimpleCommandBus) commandbus.CommandBus {
				return cb
			},

			// QueryBus
			func() *querybus.SimpleQueryBus {
				return querybus.NewQueryBus()
			},
			func(qb *querybus.SimpleQueryBus) querybus.QueryBus {
				return qb
			},

			// JWT
			newJWTUtil,

			// Repositories — provided as concrete types for direct use in Invoke
			func(db *sqlx.DB) *database.UserRepository {
				return database.NewUserRepository(db)
			},
			func(db *sqlx.DB) *database.BusinessRepository {
				return database.NewBusinessRepository(db)
			},
			func(db *sqlx.DB) *database.ItemRepository {
				return database.NewItemRepository(db)
			},
			func(db *sqlx.DB) *database.CanvasRepository {
				return database.NewCanvasRepository(db)
			},
			func(db *sqlx.DB) *database.DesignThinkingRepository {
				return database.NewDesignThinkingRepository(db)
			},

			// HTTP handlers
			newUserHTTPHandler,
			newBusinessHTTPHandler,
			newItemHTTPHandler,
			newCanvasHTTPHandler,
			newDesignThinkingHTTPHandler,
			newAuthHTTPHandler,

			// Router
			newRouter,
		),
		fx.Invoke(
			registerHandlers,
			startServer,
		),
	)

	app.Run()
}

func newDB(cfg *config.Config) (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", cfg.Database.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	db.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	db.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.Database.ConnMaxLifetime)
	return db, nil
}

func newJWTUtil(cfg *config.Config) *jwtutil.JWTUtil {
	return jwtutil.NewJWTUtil(cfg.App.JWTSecret)
}

func newUserHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.UserHandler {
	return httphandler.NewUserHandler(cmdBus, qryBus)
}

func newBusinessHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.BusinessHandler {
	return httphandler.NewBusinessHandler(cmdBus, qryBus)
}

func newItemHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.ItemHandler {
	return httphandler.NewItemHandler(cmdBus, qryBus)
}

func newCanvasHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CanvasHandler {
	return httphandler.NewCanvasHandler(cmdBus, qryBus)
}

func newDesignThinkingHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.DesignThinkingHandler {
	return httphandler.NewDesignThinkingHandler(cmdBus, qryBus)
}

func newAuthHTTPHandler(
	cmdBus commandbus.CommandBus,
	qryBus querybus.QueryBus,
	db *sqlx.DB,
	jwtUtil *jwtutil.JWTUtil,
) *httphandler.AuthHandler {
	repo := database.NewUserRepository(db)
	return httphandler.NewAuthHandler(cmdBus, qryBus, repo, jwtUtil)
}

func newRouter(
	userHandler *httphandler.UserHandler,
	businessHandler *httphandler.BusinessHandler,
	itemHandler *httphandler.ItemHandler,
	canvasHandler *httphandler.CanvasHandler,
	dtHandler *httphandler.DesignThinkingHandler,
	authHandler *httphandler.AuthHandler,
	jwtUtil *jwtutil.JWTUtil,
) *chi.Mux {
	r := chi.NewRouter()
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(pkgmiddleware.CORS)

	zerolog.SetGlobalLevel(zerolog.DebugLevel)

	// Health check
	r.Get("/health", func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	})

	jwtMW := pkgmiddleware.JWTAuth(jwtUtil)

	// Auth routes (public register/login + protected /me)
	httphandler.RegisterAuthRoutes(authHandler, r, jwtMW)

	// Protected routes
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		httphandler.RegisterUserRoutes(userHandler, r)
		httphandler.RegisterBusinessRoutes(businessHandler, r)
		httphandler.RegisterItemRoutes(itemHandler, r)
		httphandler.RegisterCanvasRoutes(canvasHandler, r)
		httphandler.RegisterDesignThinkingRoutes(dtHandler, r)
	})

	return r
}

type registerParams struct {
	fx.In

	CmdBus  *commandbus.SimpleCommandBus
	QryBus  *querybus.SimpleQueryBus
	UserRepo *database.UserRepository
	BizRepo  *database.BusinessRepository
	ItemRepo *database.ItemRepository
	CanvasRepo *database.CanvasRepository
	DTRepo  *database.DesignThinkingRepository
	EventBus eventbus.EventBus
}

func registerHandlers(p registerParams) error {
	// ---- Command Handlers ----

	// User
	if err := p.CmdBus.Register(&createuser.CreateUserCommand{},
		createuser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&registeruser.RegisterUserCommand{},
		registeruser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateuser.UpdateUserCommand{},
		updateuser.NewHandler(p.UserRepo, p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteuser.DeleteUserCommand{},
		deleteuser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}

	// Business
	if err := p.CmdBus.Register(&createbusiness.CreateBusinessCommand{},
		createbusiness.NewHandler(p.BizRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatebusiness.UpdateBusinessCommand{},
		updatebusiness.NewHandler(p.BizRepo, p.BizRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletebusiness.DeleteBusinessCommand{},
		deletebusiness.NewHandler(p.BizRepo, p.EventBus)); err != nil {
		return err
	}

	// Item
	if err := p.CmdBus.Register(&createitem.CreateItemCommand{},
		createitem.NewHandler(p.ItemRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateitem.UpdateItemCommand{},
		updateitem.NewHandler(p.ItemRepo, p.ItemRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteitem.DeleteItemCommand{},
		deleteitem.NewHandler(p.ItemRepo, p.EventBus)); err != nil {
		return err
	}

	// Canvas
	if err := p.CmdBus.Register(&createcanvas.CreateCanvasCommand{},
		createcanvas.NewHandler(p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecanvas.UpdateCanvasCommand{},
		updatecanvas.NewHandler(p.CanvasRepo, p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecanvas.DeleteCanvasCommand{},
		deletecanvas.NewHandler(p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}

	// DesignThinking
	if err := p.CmdBus.Register(&createdesignthinking.CreateDesignThinkingCommand{},
		createdesignthinking.NewHandler(p.DTRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatedesignthinking.UpdateDesignThinkingCommand{},
		updatedesignthinking.NewHandler(p.DTRepo, p.DTRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletedesignthinking.DeleteDesignThinkingCommand{},
		deletedesignthinking.NewHandler(p.DTRepo, p.EventBus)); err != nil {
		return err
	}

	// ---- Query Handlers ----

	// User
	getUserH := getuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&getuser.GetUserQuery{}, adaptQueryHandler(getUserH.Handle)); err != nil {
		return err
	}
	listUserH := listuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&listuser.ListUserQuery{}, adaptQueryHandler(listUserH.Handle)); err != nil {
		return err
	}
	searchUserH := searchuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&searchuser.SearchUserQuery{}, adaptQueryHandler(searchUserH.Handle)); err != nil {
		return err
	}

	// Business
	getBizH := getbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&getbusiness.GetBusinessQuery{}, adaptQueryHandler(getBizH.Handle)); err != nil {
		return err
	}
	listBizH := listbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&listbusiness.ListBusinessQuery{}, adaptQueryHandler(listBizH.Handle)); err != nil {
		return err
	}
	searchBizH := searchbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&searchbusiness.SearchBusinessQuery{}, adaptQueryHandler(searchBizH.Handle)); err != nil {
		return err
	}

	// Item
	getItemH := getitem.NewHandler(p.ItemRepo)
	if err := p.QryBus.Register(&getitem.GetItemQuery{}, adaptQueryHandler(getItemH.Handle)); err != nil {
		return err
	}
	listItemsByCanvasH := listitemsbycanvas.NewHandler(p.ItemRepo)
	if err := p.QryBus.Register(&listitemsbycanvas.ListItemsByCanvasQuery{}, adaptQueryHandler(listItemsByCanvasH.Handle)); err != nil {
		return err
	}

	// Canvas
	getCanvasH := getcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&getcanvas.GetCanvasQuery{}, adaptQueryHandler(getCanvasH.Handle)); err != nil {
		return err
	}
	listCanvasH := listcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&listcanvas.ListCanvasQuery{}, adaptQueryHandler(listCanvasH.Handle)); err != nil {
		return err
	}
	searchCanvasH := searchcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&searchcanvas.SearchCanvasQuery{}, adaptQueryHandler(searchCanvasH.Handle)); err != nil {
		return err
	}

	// DesignThinking
	getDTH := getdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&getdesignthinking.GetDesignThinkingQuery{}, adaptQueryHandler(getDTH.Handle)); err != nil {
		return err
	}
	listDTH := listdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&listdesignthinking.ListDesignThinkingQuery{}, adaptQueryHandler(listDTH.Handle)); err != nil {
		return err
	}
	searchDTH := searchdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&searchdesignthinking.SearchDesignThinkingQuery{}, adaptQueryHandler(searchDTH.Handle)); err != nil {
		return err
	}

	return nil
}

func startServer(lc fx.Lifecycle, r *chi.Mux, cfg *config.Config) {
	server := &http.Server{
		Addr:         ":" + cfg.App.HTTPPort,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			log.Info().Str("port", cfg.App.HTTPPort).Msg("starting HTTP server")
			go func() {
				if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					log.Fatal().Err(err).Msg("HTTP server error")
				}
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			log.Info().Msg("shutting down HTTP server")
			return server.Shutdown(ctx)
		},
	})
}
