package commandbus

import (
	"context"
	"fmt"

	"github.com/rs/zerolog/log"
	"go.opentelemetry.io/otel"
)

type Command interface{}

type CommandHandler interface {
	Handle(ctx context.Context, cmd Command) error
}

type CommandBus interface {
	Register(cmdType Command, handler CommandHandler) error
	Execute(ctx context.Context, cmd Command) error
}

type SimpleCommandBus struct {
	handlers map[string]CommandHandler
	hooks    []CommandHook
}

type CommandHook interface {
	Before(ctx context.Context, cmd Command) error
	After(ctx context.Context, cmd Command, err error) error
}

type CommandDecorator struct {
	handler CommandHandler
	hook    CommandHook
}

func (cd *CommandDecorator) Handle(ctx context.Context, cmd Command) error {
	if err := cd.hook.Before(ctx, cmd); err != nil {
		return err
	}

	err := cd.handler.Handle(ctx, cmd)

	if afterErr := cd.hook.After(ctx, cmd, err); afterErr != nil {
		return afterErr
	}

	return err
}

func NewCommandBus() *SimpleCommandBus {
	return &SimpleCommandBus{
		handlers: make(map[string]CommandHandler),
		hooks:    make([]CommandHook, 0),
	}
}

func (cb *SimpleCommandBus) Register(cmdType Command, handler CommandHandler) error {
	cmdName := fmt.Sprintf("%T", cmdType)

	if _, exists := cb.handlers[cmdName]; exists {
		return fmt.Errorf("handler for command %s already registered", cmdName)
	}

	wrappedHandler := handler
	for _, hook := range cb.hooks {
		wrappedHandler = &CommandDecorator{handler: wrappedHandler, hook: hook}
	}

	cb.handlers[cmdName] = wrappedHandler

	log.Debug().Str("command", cmdName).Msg("command handler registered")
	return nil
}

func (cb *SimpleCommandBus) Execute(ctx context.Context, cmd Command) error {
	cmdName := fmt.Sprintf("%T", cmd)

	handler, exists := cb.handlers[cmdName]
	if !exists {
		return fmt.Errorf("no handler registered for command %s", cmdName)
	}

	tracer := otel.Tracer("command-bus")
	spanCtx, span := tracer.Start(ctx, cmdName)
	defer span.End()

	log.Debug().Str("command", cmdName).Msg("executing command")

	if err := handler.Handle(spanCtx, cmd); err != nil {
		span.RecordError(err)
		log.Error().Err(err).Str("command", cmdName).Msg("command execution failed")
		return err
	}

	log.Debug().Str("command", cmdName).Msg("command executed successfully")
	return nil
}

func (cb *SimpleCommandBus) AddHook(hook CommandHook) {
	cb.hooks = append(cb.hooks, hook)
}

func GetCommandType(cmd Command) string {
	return fmt.Sprintf("%T", cmd)
}
