package accounting

// Currency codes (ISO 4217).
const (
	CurrencyIDR = "IDR"
)

// Account types.
const (
	AccountTypeAsset     = "asset"
	AccountTypeLiability = "liability"
	AccountTypeEquity    = "equity"
	AccountTypeRevenue   = "revenue"
	AccountTypeExpense   = "expense"
)

// Transaction types (debit/credit semantics for cash flow).
const (
	TxnTypeDebit  = "debit"
	TxnTypeCredit = "credit"
)

// Transaction status.
const (
	TxnStatusDraft     = "draft"
	TxnStatusCompleted = "completed"
	TxnStatusCancelled = "cancelled"
)

// Validation limits.
const (
	BankAccountNameMinLen = 2
	BankAccountNameMaxLen = 255
)

// IsValidAccountType reports whether t is a recognized COA account type.
func IsValidAccountType(t string) bool {
	switch t {
	case AccountTypeAsset, AccountTypeLiability, AccountTypeEquity,
		AccountTypeRevenue, AccountTypeExpense:
		return true
	}
	return false
}

// IsValidTxnType reports whether t is a recognized transaction type.
func IsValidTxnType(t string) bool {
	return t == TxnTypeDebit || t == TxnTypeCredit
}
