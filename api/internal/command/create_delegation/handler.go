package create_delegation

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo delegation.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo delegation.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateDelegationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	requestedByID, err := uuid.Parse(c.RequestedByID)
	if err != nil {
		return ErrInvalidCommand
	}

	var assignedToID *uuid.UUID
	if c.AssignedToID != "" {
		aid, err := uuid.Parse(c.AssignedToID)
		if err == nil {
			assignedToID = &aid
		}
	}

	var dueDate *time.Time
	if c.DueDate != "" {
		dl, err := time.Parse(time.RFC3339, c.DueDate)
		if err == nil {
			dueDate = &dl
		}
	}

	var linkedEntityType *string
	if c.LinkedEntityType != "" {
		t := c.LinkedEntityType
		linkedEntityType = &t
	}

	var linkedEntityID *uuid.UUID
	if c.LinkedEntityID != "" {
		eid, err := uuid.Parse(c.LinkedEntityID)
		if err == nil {
			linkedEntityID = &eid
		}
	}

	var notes *string
	if c.Notes != "" {
		n := c.Notes
		notes = &n
	}

	delegationType := delegation.DelegationType(c.Type)
	if delegationType == "" {
		delegationType = delegation.TypeDelegateTask
	}
	priority := delegation.Priority(c.Priority)
	if priority == "" {
		priority = delegation.PriorityMedium
	}

	d, err := delegation.NewDelegation(
		c.Title, c.Description,
		delegationType,
		requestedByID, c.RequestedByName,
		assignedToID, c.AssignedToName, c.AssignedToRole,
		priority,
		dueDate,
		linkedEntityType, linkedEntityID,
		notes,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create delegation domain object")
		return err
	}

	if err := h.writeRepo.Save(ctx, d); err != nil {
		log.Error().Err(err).Msg("failed to save delegation")
		return err
	}

	var assignedToUUID uuid.UUID
	if assignedToID != nil {
		assignedToUUID = *assignedToID
	}
	event := &delegation.DelegationCreatedEvent{
		DelegationID:    d.ID,
		Title:           d.Title,
		RequestedByID:   d.RequestedByID,
		RequestedByName: d.RequestedByName,
		AssignedToID:    assignedToUUID,
		AssignedToName:  d.AssignedToName,
		Priority:        string(d.Priority),
		Timestamp:       time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish DelegationCreated event")
	}

	log.Info().Str("delegation_id", d.ID.String()).Msg("delegation created successfully")
	return nil
}
