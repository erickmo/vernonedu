package courseversion_test

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
)

// newTestVersion membuat course version draft untuk pengujian.
func newTestVersion(t *testing.T) *courseversion.CourseVersion {
	t.Helper()
	cv, err := courseversion.NewCourseVersion(uuid.New(), "1.0.0", "minor", "init", nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	return cv
}

func TestNewCourseVersion_StartsAsApprovalDraft(t *testing.T) {
	cv := newTestVersion(t)
	if cv.ApprovalStatus != courseversion.ApprovalStatusDraft {
		t.Fatalf("expected approval draft, got %q", cv.ApprovalStatus)
	}
}

func TestSubmit_FromDraft_Success(t *testing.T) {
	cv := newTestVersion(t)
	user := uuid.New()
	if err := cv.Submit(user); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cv.ApprovalStatus != courseversion.ApprovalStatusSubmitted {
		t.Fatalf("expected submitted, got %q", cv.ApprovalStatus)
	}
	if cv.SubmittedBy == nil || *cv.SubmittedBy != user {
		t.Fatalf("expected SubmittedBy to be %v", user)
	}
	if cv.SubmittedAt == nil {
		t.Fatal("expected SubmittedAt to be set")
	}
}

func TestSubmit_FromSubmitted_Rejected(t *testing.T) {
	cv := newTestVersion(t)
	_ = cv.Submit(uuid.New())
	err := cv.Submit(uuid.New())
	if !errors.Is(err, courseversion.ErrInvalidApprovalState) {
		t.Fatalf("expected ErrInvalidApprovalState, got %v", err)
	}
}

func TestSubmit_FromRejected_AllowsResubmit(t *testing.T) {
	cv := newTestVersion(t)
	_ = cv.Submit(uuid.New())
	if err := cv.RejectWorkflow(uuid.New(), "needs work"); err != nil {
		t.Fatalf("unexpected reject err: %v", err)
	}
	if err := cv.Submit(uuid.New()); err != nil {
		t.Fatalf("expected resubmit allowed, got %v", err)
	}
	if cv.RejectionReason != "" {
		t.Fatalf("expected reason cleared, got %q", cv.RejectionReason)
	}
}

func TestApproveWorkflow_FromSubmitted_Success(t *testing.T) {
	cv := newTestVersion(t)
	_ = cv.Submit(uuid.New())
	approver := uuid.New()
	if err := cv.ApproveWorkflow(approver); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cv.ApprovalStatus != courseversion.ApprovalStatusApproved {
		t.Fatalf("expected approved, got %q", cv.ApprovalStatus)
	}
	if cv.ApprovalApprovedBy == nil || *cv.ApprovalApprovedBy != approver {
		t.Fatalf("expected ApprovalApprovedBy=%v", approver)
	}
}

func TestApproveWorkflow_FromDraft_Rejected(t *testing.T) {
	cv := newTestVersion(t)
	err := cv.ApproveWorkflow(uuid.New())
	if !errors.Is(err, courseversion.ErrInvalidApprovalState) {
		t.Fatalf("expected ErrInvalidApprovalState, got %v", err)
	}
}

func TestRejectWorkflow_FromSubmitted_Success(t *testing.T) {
	cv := newTestVersion(t)
	_ = cv.Submit(uuid.New())
	if err := cv.RejectWorkflow(uuid.New(), "missing learning outcomes"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cv.ApprovalStatus != courseversion.ApprovalStatusRejected {
		t.Fatalf("expected rejected, got %q", cv.ApprovalStatus)
	}
	if cv.RejectionReason == "" {
		t.Fatal("expected rejection reason to be stored")
	}
}

func TestRejectWorkflow_EmptyReason_Rejected(t *testing.T) {
	cv := newTestVersion(t)
	_ = cv.Submit(uuid.New())
	err := cv.RejectWorkflow(uuid.New(), "   ")
	if !errors.Is(err, courseversion.ErrEmptyRejectionReason) {
		t.Fatalf("expected ErrEmptyRejectionReason, got %v", err)
	}
}

func TestRejectWorkflow_FromDraft_Rejected(t *testing.T) {
	cv := newTestVersion(t)
	err := cv.RejectWorkflow(uuid.New(), "any")
	if !errors.Is(err, courseversion.ErrInvalidApprovalState) {
		t.Fatalf("expected ErrInvalidApprovalState, got %v", err)
	}
}
