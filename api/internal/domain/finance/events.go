package finance

import "github.com/google/uuid"

type AccountCreatedEvent struct {
	EventType string    `json:"event_type"`
	AccountID uuid.UUID `json:"account_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *AccountCreatedEvent) EventName() string      { return "FinanceAccountCreated" }
func (e *AccountCreatedEvent) EventData() interface{} { return e }

type TransactionCreatedEvent struct {
	EventType     string    `json:"event_type"`
	TransactionID uuid.UUID `json:"transaction_id"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *TransactionCreatedEvent) EventName() string      { return "FinanceTransactionCreated" }
func (e *TransactionCreatedEvent) EventData() interface{} { return e }
