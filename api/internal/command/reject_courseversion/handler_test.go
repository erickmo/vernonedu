package reject_courseversion_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/reject_courseversion"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type mockRepo struct {
	current *courseversion.CourseVersion
	updated *courseversion.CourseVersion
}

func (m *mockRepo) Save(_ context.Context, _ *courseversion.CourseVersion) error { return nil }
func (m *mockRepo) Update(_ context.Context, _ *courseversion.CourseVersion) error {
	return nil
}
func (m *mockRepo) ArchiveAllApproved(_ context.Context, _ uuid.UUID) error { return nil }
func (m *mockRepo) UpdateApprovalWorkflow(_ context.Context, cv *courseversion.CourseVersion) error {
	m.updated = cv
	return nil
}
func (m *mockRepo) GetByID(_ context.Context, _ uuid.UUID) (*courseversion.CourseVersion, error) {
	return m.current, nil
}
func (m *mockRepo) ListByType(_ context.Context, _ uuid.UUID, _, _ string) ([]*courseversion.CourseVersion, error) {
	return nil, nil
}
func (m *mockRepo) GetApproved(_ context.Context, _ uuid.UUID) (*courseversion.CourseVersion, error) {
	return nil, nil
}
func (m *mockRepo) ListPending(_ context.Context, _ *uuid.UUID) ([]*courseversion.CourseVersion, error) {
	return nil, nil
}

func newSubmittedVersion(t *testing.T) *courseversion.CourseVersion {
	t.Helper()
	cv, err := courseversion.NewCourseVersion(uuid.New(), "1.0.0", "minor", "init", nil)
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if err := cv.Submit(uuid.New()); err != nil {
		t.Fatalf("submit failed: %v", err)
	}
	return cv
}

func TestHandler_Handle_Success(t *testing.T) {
	cv := newSubmittedVersion(t)
	repo := &mockRepo{current: cv}
	bus := eventbus.NewInMemoryEventBus()
	h := reject_courseversion.NewHandler(repo, repo, bus)

	cmd := &reject_courseversion.RejectCourseVersionCommand{
		VersionID:  cv.ID,
		ApprovedBy: uuid.New(),
		Reason:     "outline incomplete",
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if repo.updated == nil || repo.updated.ApprovalStatus != courseversion.ApprovalStatusRejected {
		t.Fatalf("expected rejected, got %+v", repo.updated)
	}
	if repo.updated.RejectionReason != "outline incomplete" {
		t.Fatalf("expected reason stored, got %q", repo.updated.RejectionReason)
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockRepo{}
	bus := eventbus.NewInMemoryEventBus()
	h := reject_courseversion.NewHandler(repo, repo, bus)
	if err := h.Handle(context.Background(), nil); !errors.Is(err, reject_courseversion.ErrInvalidCommand) {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestHandler_Handle_EmptyReason(t *testing.T) {
	cv := newSubmittedVersion(t)
	repo := &mockRepo{current: cv}
	bus := eventbus.NewInMemoryEventBus()
	h := reject_courseversion.NewHandler(repo, repo, bus)

	cmd := &reject_courseversion.RejectCourseVersionCommand{
		VersionID:  cv.ID,
		ApprovedBy: uuid.New(),
		Reason:     "",
	}
	if err := h.Handle(context.Background(), cmd); !errors.Is(err, courseversion.ErrEmptyRejectionReason) {
		t.Fatalf("expected ErrEmptyRejectionReason, got %v", err)
	}
}
