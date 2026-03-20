package item

import "github.com/google/uuid"

type ItemCreated struct {
	ItemID    uuid.UUID `json:"item_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ItemCreated) EventName() string {
	return "ItemCreated"
}

func (e *ItemCreated) EventData() interface{} {
	return e
}

type ItemUpdated struct {
	ItemID    uuid.UUID `json:"item_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ItemUpdated) EventName() string {
	return "ItemUpdated"
}

func (e *ItemUpdated) EventData() interface{} {
	return e
}

type ItemDeleted struct {
	ItemID    uuid.UUID `json:"item_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ItemDeleted) EventName() string {
	return "ItemDeleted"
}

func (e *ItemDeleted) EventData() interface{} {
	return e
}
