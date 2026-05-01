package server

import (
	"context"
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	appMiddleware "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// NewRouter constructs the Chi router with global middleware.
func NewRouter(cfg *config.Config, log *zap.Logger) *chi.Mux {
	r := chi.NewRouter()

	// Global middleware
	r.Use(appMiddleware.Logger)
	r.Use(appMiddleware.Recovery(log))
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   cfg.CORS.AllowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Compress(5))

	// Rate-limit auth endpoints
	r.Group(func(r chi.Router) {
		r.Use(httprate.LimitByIP(20, 1))
		r.Post("/api/v1/auth/login", http.NotFoundHandler().ServeHTTP)   // placeholder — overridden by identity module
		r.Post("/api/v1/auth/register", http.NotFoundHandler().ServeHTTP) // placeholder — overridden by identity module
	})

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	return r
}

// NewHTTPServer builds *http.Server for FX lifecycle management.
func NewHTTPServer(lc fx.Lifecycle, cfg *config.Config, r *chi.Mux, log *zap.Logger) *http.Server {
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.App.Port),
		Handler: r,
	}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			go func() {
				log.Info("HTTP server starting", zap.String("addr", srv.Addr))
				if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					log.Fatal("HTTP server error", zap.Error(err))
				}
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			log.Info("HTTP server shutting down")
			return srv.Shutdown(ctx)
		},
	})

	return srv
}

// Params groups FX dependencies for server module.
type Params struct {
	fx.In
	Config *config.Config
	Log    *zap.Logger
}

// Module wires the HTTP server via FX.
var Module = fx.Options(
	fx.Provide(NewRouter),
	fx.Provide(NewHTTPServer),
	fx.Invoke(func(*http.Server) {}),
)

// NewZapLogger constructs a zap.Logger from config.
func NewZapLogger(cfg *config.Config) (*zap.Logger, error) {
	if cfg.App.Env == "production" {
		return zap.NewProduction()
	}
	return zap.NewDevelopment()
}

// NewConfig loads config via FX.
func NewConfig() (*config.Config, error) {
	return config.Load()
}

// MustGetUserContext extracts UserContext from r or panics.
func MustGetUserContext(r *http.Request) *appMiddleware.UserContext {
	uc := appMiddleware.GetUserContext(r.Context())
	if uc == nil {
		panic("user context missing from request")
	}
	return uc
}
