package business

import "github.com/google/uuid"

type BusinessCreated struct {
	BusinessID uuid.UUID `json:"business_id"`
	Name       string    `json:"name"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BusinessCreated) EventName() string {
	return "BusinessCreated"
}

func (e *BusinessCreated) EventData() interface{} {
	return e
}

type BusinessUpdated struct {
	BusinessID uuid.UUID `json:"business_id"`
	Name       string    `json:"name"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BusinessUpdated) EventName() string {
	return "BusinessUpdated"
}

func (e *BusinessUpdated) EventData() interface{} {
	return e
}

type BusinessDeleted struct {
	BusinessID uuid.UUID `json:"business_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BusinessDeleted) EventName() string {
	return "BusinessDeleted"
}

func (e *BusinessDeleted) EventData() interface{} {
	return e
}
