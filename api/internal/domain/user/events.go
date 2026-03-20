package user

import (
	"github.com/google/uuid"
)

type UserCreated struct {
	UserID    uuid.UUID `json:"user_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *UserCreated) EventName() string {
	return "UserCreated"
}

func (e *UserCreated) EventData() interface{} {
	return e
}

type UserUpdated struct {
	UserID    uuid.UUID `json:"user_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *UserUpdated) EventName() string {
	return "UserUpdated"
}

func (e *UserUpdated) EventData() interface{} {
	return e
}

type UserDeleted struct {
	UserID    uuid.UUID `json:"user_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *UserDeleted) EventName() string {
	return "UserDeleted"
}

func (e *UserDeleted) EventData() interface{} {
	return e
}
