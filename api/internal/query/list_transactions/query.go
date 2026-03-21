package list_transactions

type ListTransactionsQuery struct {
	Offset int
	Limit  int
	Month  int
	Year   int
	Type   string
}
