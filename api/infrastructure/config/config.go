package config

import (
	"fmt"
	"time"

	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

type Config struct {
	App      AppConfig
	Database DatabaseConfig
	Redis    RedisConfig
	NATS     NATSConfig
	OTel     OTelConfig
}

type AppConfig struct {
	Name      string
	Env       string
	HTTPPort  string
	LogLevel  string
	JWTSecret string
}

type DatabaseConfig struct {
	URL             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

type RedisConfig struct {
	URL string
	TTL time.Duration
}

type NATSConfig struct {
	URL        string
	StreamName string
}

type OTelConfig struct {
	OTLPEndpoint   string
	PrometheusPort string
}

func Load() (*Config, error) {
	viper.SetConfigFile(".env")
	viper.AutomaticEnv()

	// Default values
	viper.SetDefault("APP_NAME", "entrepreneurship-api")
	viper.SetDefault("APP_ENV", "development")
	viper.SetDefault("HTTP_PORT", "8080")
	viper.SetDefault("LOG_LEVEL", "debug")
	viper.SetDefault("JWT_SECRET", "development-secret-change-in-production")
	viper.SetDefault("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/entrepreneurship_db?sslmode=disable")
	viper.SetDefault("DB_MAX_OPEN_CONNS", 25)
	viper.SetDefault("DB_MAX_IDLE_CONNS", 5)
	viper.SetDefault("DB_CONN_MAX_LIFETIME", "5m")
	viper.SetDefault("REDIS_URL", "redis://localhost:6379/0")
	viper.SetDefault("REDIS_TTL_SECONDS", 300)
	viper.SetDefault("NATS_URL", "nats://localhost:4222")
	viper.SetDefault("NATS_STREAM_NAME", "ENTREPRENEURSHIP_EVENTS")
	viper.SetDefault("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
	viper.SetDefault("PROMETHEUS_PORT", "9090")

	if err := viper.ReadInConfig(); err != nil {
		log.Warn().Err(err).Msg("no .env file found, using environment variables and defaults")
	}

	connMaxLifetime, err := time.ParseDuration(viper.GetString("DB_CONN_MAX_LIFETIME"))
	if err != nil {
		connMaxLifetime = 5 * time.Minute
	}

	redisTTL := time.Duration(viper.GetInt("REDIS_TTL_SECONDS")) * time.Second

	cfg := &Config{
		App: AppConfig{
			Name:      viper.GetString("APP_NAME"),
			Env:       viper.GetString("APP_ENV"),
			HTTPPort:  viper.GetString("HTTP_PORT"),
			LogLevel:  viper.GetString("LOG_LEVEL"),
			JWTSecret: viper.GetString("JWT_SECRET"),
		},
		Database: DatabaseConfig{
			URL:             viper.GetString("DATABASE_URL"),
			MaxOpenConns:    viper.GetInt("DB_MAX_OPEN_CONNS"),
			MaxIdleConns:    viper.GetInt("DB_MAX_IDLE_CONNS"),
			ConnMaxLifetime: connMaxLifetime,
		},
		Redis: RedisConfig{
			URL: viper.GetString("REDIS_URL"),
			TTL: redisTTL,
		},
		NATS: NATSConfig{
			URL:        viper.GetString("NATS_URL"),
			StreamName: viper.GetString("NATS_STREAM_NAME"),
		},
		OTel: OTelConfig{
			OTLPEndpoint:   viper.GetString("OTEL_EXPORTER_OTLP_ENDPOINT"),
			PrometheusPort: viper.GetString("PROMETHEUS_PORT"),
		},
	}

	// Validate JWT secret is not default in production
	if cfg.App.Env == "production" && cfg.App.JWTSecret == "development-secret-change-in-production" {
		return nil, fmt.Errorf("JWT_SECRET must be set to a strong secret in production environment")
	}

	return cfg, nil
}
