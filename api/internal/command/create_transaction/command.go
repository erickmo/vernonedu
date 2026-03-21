package create_transaction

type CreateTransactionCommand struct {
	Description       string  `validate:"required"`
	TransactionType   string  `validate:"required"`
	Amount            float64 `validate:"required,gt=0"`
	DebitAccountCode  string
	CreditAccountCode string
	Category          string
	TransactionDate   string // "2006-01-02"
	Status            string
}
