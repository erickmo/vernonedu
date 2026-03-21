package create_invoice

import (
	"time"

	"github.com/google/uuid"
)

type CreateInvoiceCommand struct {
	BranchID      *uuid.UUID `json:"branch_id"`
	StudentID     *uuid.UUID `json:"student_id"`
	EnrollmentID  *uuid.UUID `json:"enrollment_id"`
	ClientName    string     `json:"client_name"`
	BatchID       uuid.UUID  `json:"batch_id" validate:"required"`
	BatchName     string     `json:"batch_name"`
	StudentName   string     `json:"student_name"`
	Amount        int64      `json:"amount" validate:"required,gt=0"`
	DueDate       time.Time  `json:"due_date" validate:"required"`
	PaymentMethod string     `json:"payment_method" validate:"required"`
	Notes         string     `json:"notes"`
	CreatedBy     uuid.UUID  `json:"created_by" validate:"required"`
}
