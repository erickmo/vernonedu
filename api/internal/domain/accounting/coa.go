package accounting

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type ChartOfAccount struct {
	ID          uuid.UUID
	Code        string
	Name        string
	AccountType string // asset, liability, equity, revenue, expense
	ParentCode  string
	IsActive    bool
	CreatedAt   time.Time
}

type CoaReadRepository interface {
	List(ctx context.Context) ([]*ChartOfAccount, error)
}
