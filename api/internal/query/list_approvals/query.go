package list_approvals

import "github.com/google/uuid"

type ListApprovalsQuery struct {
	Offset     int
	Limit      int
	Status     string
	ApproverID *uuid.UUID
}
