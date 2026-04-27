package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	App      AppConfig
	DB       DBConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Storage  StorageConfig
	Email    EmailConfig
	Midtrans MidtransConfig
	CORS     CORSConfig
	Calendar CalendarConfig
}

type CalendarConfig struct {
	OAuth            CalendarOAuthConfig
	EncryptionKeyHex string
}

type CalendarOAuthConfig struct {
	GoogleClientID     string
	GoogleClientSecret string
	GoogleRedirectURL  string
}

type AppConfig struct {
	Env       string
	Port      string
	LogLevel  string
	SecretKey string
}

type DBConfig struct {
	User            string
	Password        string
	Name            string
	Host            string
	Port            string
	SSLMode         string
	URL             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

type RedisConfig struct {
	URL string
}

type JWTConfig struct {
	Secret            string
	ExpiryHours       int
	RefreshExpiryDays int
}

type StorageConfig struct {
	Provider    string
	LocalPath   string
	S3Bucket    string
	S3Region    string
	S3AccessKey string
	S3SecretKey string
}

type EmailConfig struct {
	SMTPHost     string
	SMTPPort     int
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
}

type MidtransConfig struct {
	ServerKey string
	ClientKey string
	Env       string
}

type CORSConfig struct {
	AllowedOrigins []string
}

func Load() (*Config, error) {
	// try .env in current dir, then parent (when running from backend/ subdir)
	if err := godotenv.Load(); err != nil {
		_ = godotenv.Load("../.env")
	}

	cfg := &Config{}

	cfg.App = AppConfig{
		Env:       getEnv("APP_ENV", "development"),
		Port:      getEnv("APP_PORT", "8080"),
		LogLevel:  getEnv("APP_LOG_LEVEL", "info"),
		SecretKey: requireEnv("APP_SECRET_KEY"),
	}

	maxOpen, _ := strconv.Atoi(getEnv("DB_MAX_OPEN_CONNS", "25"))
	maxIdle, _ := strconv.Atoi(getEnv("DB_MAX_IDLE_CONNS", "5"))
	connLifetimeSec, _ := strconv.Atoi(getEnv("DB_CONN_MAX_LIFETIME_SEC", "300"))

	dbUser := getEnv("DB_USER", "postgres")
	dbPassword := getEnv("DB_PASSWORD", "")
	dbName := getEnv("DB_NAME", "vernonedu2")
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbSSL := getEnv("DB_SSLMODE", "disable")

	dbURL := getEnv("DB_URL", "")
	if dbURL == "" {
		dbURL = fmt.Sprintf(
			"postgres://%s:%s@%s:%s/%s?sslmode=%s",
			dbUser, dbPassword, dbHost, dbPort, dbName, dbSSL,
		)
	}

	cfg.DB = DBConfig{
		User:            dbUser,
		Password:        dbPassword,
		Name:            dbName,
		Host:            dbHost,
		Port:            dbPort,
		SSLMode:         dbSSL,
		URL:             dbURL,
		MaxOpenConns:    maxOpen,
		MaxIdleConns:    maxIdle,
		ConnMaxLifetime: time.Duration(connLifetimeSec) * time.Second,
	}

	cfg.Redis = RedisConfig{
		URL: getEnv("REDIS_URL", "redis://localhost:6379"),
	}

	jwtExpiry, _ := strconv.Atoi(getEnv("JWT_EXPIRY_HOURS", "24"))
	jwtRefresh, _ := strconv.Atoi(getEnv("JWT_REFRESH_EXPIRY_DAYS", "7"))

	cfg.JWT = JWTConfig{
		Secret:            requireEnv("JWT_SECRET"),
		ExpiryHours:       jwtExpiry,
		RefreshExpiryDays: jwtRefresh,
	}

	cfg.Storage = StorageConfig{
		Provider:    getEnv("STORAGE_PROVIDER", "local"),
		LocalPath:   getEnv("STORAGE_LOCAL_PATH", "./uploads"),
		S3Bucket:    getEnv("STORAGE_S3_BUCKET", ""),
		S3Region:    getEnv("STORAGE_S3_REGION", "ap-southeast-1"),
		S3AccessKey: getEnv("STORAGE_S3_ACCESS_KEY", ""),
		S3SecretKey: getEnv("STORAGE_S3_SECRET_KEY", ""),
	}

	smtpPort, _ := strconv.Atoi(getEnv("EMAIL_SMTP_PORT", "587"))

	cfg.Email = EmailConfig{
		SMTPHost:     getEnv("EMAIL_SMTP_HOST", ""),
		SMTPPort:     smtpPort,
		SMTPUser:     getEnv("EMAIL_SMTP_USER", ""),
		SMTPPassword: getEnv("EMAIL_SMTP_PASSWORD", ""),
		SMTPFrom:     getEnv("EMAIL_SMTP_FROM", "noreply@vernonedu.com"),
	}

	cfg.Midtrans = MidtransConfig{
		ServerKey: getEnv("MIDTRANS_SERVER_KEY", ""),
		ClientKey: getEnv("MIDTRANS_CLIENT_KEY", ""),
		Env:       getEnv("MIDTRANS_ENV", "sandbox"),
	}

	cfg.Calendar = CalendarConfig{
		OAuth: CalendarOAuthConfig{
			GoogleClientID:     getEnv("GOOGLE_CLIENT_ID", ""),
			GoogleClientSecret: getEnv("GOOGLE_CLIENT_SECRET", ""),
			GoogleRedirectURL:  getEnv("GOOGLE_REDIRECT_URL", ""),
		},
		EncryptionKeyHex: getEnv("CALENDAR_ENC_KEY_HEX", ""),
	}

	originsRaw := getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000")
	cfg.CORS = CORSConfig{
		AllowedOrigins: strings.Split(originsRaw, ","),
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func requireEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		panic(fmt.Sprintf("required env var %s is not set", key))
	}
	return v
}
