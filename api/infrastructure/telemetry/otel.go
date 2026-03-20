package telemetry

import (
	"context"

	"github.com/rs/zerolog/log"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"

	"github.com/vernonedu/entrepreneurship-api/infrastructure/config"
)

func InitTracerProvider(ctx context.Context, cfg *config.Config) (*trace.TracerProvider, error) {
	exporter, err := otlptracehttp.New(ctx, otlptracehttp.WithEndpoint(cfg.OTel.OTLPEndpoint))
	if err != nil {
		log.Error().Err(err).Msg("failed to create OTLP trace exporter")
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

	tp := trace.NewTracerProvider(
		trace.WithBatcher(exporter),
		trace.WithResource(res),
	)

	otel.SetTracerProvider(tp)

	log.Info().Msg("tracer provider initialized")
	return tp, nil
}

func Shutdown(ctx context.Context, tp *trace.TracerProvider) error {
	return tp.Shutdown(ctx)
}
