package querybus

import (
	"context"
	"fmt"

	"github.com/rs/zerolog/log"
	"go.opentelemetry.io/otel"
)

type Query interface{}

type QueryHandler interface {
	Handle(ctx context.Context, query Query) (interface{}, error)
}

type QueryBus interface {
	Register(queryType Query, handler QueryHandler) error
	Execute(ctx context.Context, query Query) (interface{}, error)
}

type SimpleQueryBus struct {
	handlers map[string]QueryHandler
}

func NewQueryBus() *SimpleQueryBus {
	return &SimpleQueryBus{
		handlers: make(map[string]QueryHandler),
	}
}

func (qb *SimpleQueryBus) Register(queryType Query, handler QueryHandler) error {
	queryName := fmt.Sprintf("%T", queryType)

	if _, exists := qb.handlers[queryName]; exists {
		return fmt.Errorf("handler for query %s already registered", queryName)
	}

	qb.handlers[queryName] = handler

	log.Debug().Str("query", queryName).Msg("query handler registered")
	return nil
}

func (qb *SimpleQueryBus) Execute(ctx context.Context, query Query) (interface{}, error) {
	queryName := fmt.Sprintf("%T", query)

	handler, exists := qb.handlers[queryName]
	if !exists {
		return nil, fmt.Errorf("no handler registered for query %s", queryName)
	}

	tracer := otel.Tracer("query-bus")
	spanCtx, span := tracer.Start(ctx, queryName)
	defer span.End()

	log.Debug().Str("query", queryName).Msg("executing query")

	result, err := handler.Handle(spanCtx, query)
	if err != nil {
		span.RecordError(err)
		log.Error().Err(err).Str("query", queryName).Msg("query execution failed")
		return nil, err
	}

	log.Debug().Str("query", queryName).Msg("query executed successfully")
	return result, nil
}
