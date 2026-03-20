package telemetry

import (
	"context"

	"github.com/rs/zerolog/log"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"

	"github.com/vernonedu/entrepreneurship-api/infrastructure/config"
)

func InitMeterProvider(ctx context.Context, cfg *config.Config) (*metric.MeterProvider, error) {
	exporter, err := otlpmetrichttp.New(ctx, otlpmetrichttp.WithEndpoint(cfg.OTel.OTLPEndpoint))
	if err != nil {
		log.Error().Err(err).Msg("failed to create OTLP metric exporter")
		return nil, err
	}

	res, err := resource.New(ctx, resource.WithAttributes(
		semconv.ServiceNameKey.String(cfg.App.Name),
		semconv.ServiceVersionKey.String("1.0.0"),
		semconv.DeploymentEnvironmentKey.String(cfg.App.Env),
	))
	if err != nil {
		log.Error().Err(err).Msg("failed to create resource")
		return nil, err
	}

	mp := metric.NewMeterProvider(
		metric.WithReader(metric.NewPeriodicReader(exporter)),
		metric.WithResource(res),
	)

	otel.SetMeterProvider(mp)

	log.Info().Msg("meter provider initialized")
	return mp, nil
}

func ShutdownMeterProvider(ctx context.Context, mp *metric.MeterProvider) error {
	return mp.Shutdown(ctx)
}
