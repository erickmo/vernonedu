package delegation_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
)

func TestNewDelegation_Valid(t *testing.T) {
	requesterID := uuid.New()
	assigneeID := uuid.New()
	title := "Review course proposal"
	desc := "Please review the new course proposal for Q2"
	entityType := "mastercourse"
	entityID := uuid.New()
	notes := "urgent review needed"
	dueDate := time.Now().Add(48 * time.Hour)

	d, err := delegation.NewDelegation(
		title, desc,
		delegation.TypeRequestCourse,
		requesterID, "Alice",
		&assigneeID, "Bob", "dept_leader",
		delegation.PriorityHigh,
		&dueDate,
		&entityType, &entityID,
		&notes,
	)

	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if d.ID == uuid.Nil {
		t.Error("expected non-nil ID")
	}
	if d.Title != title {
		t.Errorf("expected title %q, got %q", title, d.Title)
	}
	if d.Status != delegation.StatusPending {
		t.Errorf("expected status pending, got %s", d.Status)
	}
	if d.Type != delegation.TypeRequestCourse {
		t.Errorf("expected type request_course, got %s", d.Type)
	}
	if d.Priority != delegation.PriorityHigh {
		t.Errorf("expected priority high, got %s", d.Priority)
	}
	if d.DueDate == nil {
		t.Error("expected non-nil due date")
	}
}

func TestNewDelegation_MissingTitle(t *testing.T) {
	_, err := delegation.NewDelegation(
		"", "description",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)
	if err == nil {
		t.Error("expected error for missing title")
	}
}

func TestNewDelegation_InvalidType(t *testing.T) {
	_, err := delegation.NewDelegation(
		"Title", "description",
		delegation.DelegationType("invalid_type"),
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)
	if err != delegation.ErrInvalidType {
		t.Errorf("expected ErrInvalidType, got: %v", err)
	}
}

func TestNewDelegation_InvalidPriority(t *testing.T) {
	_, err := delegation.NewDelegation(
		"Title", "description",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.Priority("critical"),
		nil, nil, nil, nil,
	)
	if err != delegation.ErrInvalidPriority {
		t.Errorf("expected ErrInvalidPriority, got: %v", err)
	}
}

func TestDelegation_Accept(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	if err := d.Accept(); err != nil {
		t.Fatalf("expected no error on Accept, got: %v", err)
	}
	if d.Status != delegation.StatusAccepted {
		t.Errorf("expected status accepted, got %s", d.Status)
	}
}

func TestDelegation_Accept_AlreadyAccepted(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	_ = d.Accept()
	err := d.Accept()
	if err != delegation.ErrInvalidStatusTransition {
		t.Errorf("expected ErrInvalidStatusTransition, got: %v", err)
	}
}

func TestDelegation_Complete(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	_ = d.Accept()
	notes := "all done"
	if err := d.Complete(&notes); err != nil {
		t.Fatalf("expected no error on Complete, got: %v", err)
	}
	if d.Status != delegation.StatusCompleted {
		t.Errorf("expected status completed, got %s", d.Status)
	}
	if d.Notes == nil || *d.Notes != notes {
		t.Errorf("expected notes %q, got %v", notes, d.Notes)
	}
}

func TestDelegation_Complete_FromPending(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	err := d.Complete(nil)
	if err != delegation.ErrInvalidStatusTransition {
		t.Errorf("expected ErrInvalidStatusTransition on Complete from pending, got: %v", err)
	}
}

func TestDelegation_Cancel(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	notes := "no longer needed"
	if err := d.Cancel(&notes); err != nil {
		t.Fatalf("expected no error on Cancel, got: %v", err)
	}
	if d.Status != delegation.StatusCancelled {
		t.Errorf("expected status cancelled, got %s", d.Status)
	}
}

func TestDelegation_Cancel_AlreadyCompleted(t *testing.T) {
	d, _ := delegation.NewDelegation(
		"Title", "desc",
		delegation.TypeDelegateTask,
		uuid.New(), "Alice",
		nil, "", "",
		delegation.PriorityMedium,
		nil, nil, nil, nil,
	)

	_ = d.Accept()
	_ = d.Complete(nil)
	err := d.Cancel(nil)
	if err != delegation.ErrInvalidStatusTransition {
		t.Errorf("expected ErrInvalidStatusTransition on Cancel after Complete, got: %v", err)
	}
}

func TestValidType(t *testing.T) {
	tests := []struct {
		input string
		valid bool
	}{
		{"request_course", true},
		{"request_project", true},
		{"delegate_task", true},
		{"invalid", false},
		{"", false},
	}
	for _, tt := range tests {
		if got := delegation.ValidType(tt.input); got != tt.valid {
			t.Errorf("ValidType(%q) = %v, want %v", tt.input, got, tt.valid)
		}
	}
}

func TestValidPriority(t *testing.T) {
	tests := []struct {
		input string
		valid bool
	}{
		{"low", true},
		{"medium", true},
		{"high", true},
		{"urgent", true},
		{"critical", false},
		{"", false},
	}
	for _, tt := range tests {
		if got := delegation.ValidPriority(tt.input); got != tt.valid {
			t.Errorf("ValidPriority(%q) = %v, want %v", tt.input, got, tt.valid)
		}
	}
}

func TestValidStatus(t *testing.T) {
	tests := []struct {
		input string
		valid bool
	}{
		{"pending", true},
		{"accepted", true},
		{"in_progress", true},
		{"completed", true},
		{"cancelled", true},
		{"unknown", false},
	}
	for _, tt := range tests {
		if got := delegation.ValidStatus(tt.input); got != tt.valid {
			t.Errorf("ValidStatus(%q) = %v, want %v", tt.input, got, tt.valid)
		}
	}
}
