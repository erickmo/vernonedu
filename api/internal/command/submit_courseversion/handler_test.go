package submit_courseversion_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/submit_courseversion"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type mockRepo struct {
	current      *courseversion.CourseVersion
	updated      *courseversion.CourseVersion
	updateErr    error
	getErr       error
}

func (m *mockRepo) Save(_ context.Context, _ *courseversion.CourseVersion) error { return nil }
func (m *mockRepo) Update(_ context.Context, _ *courseversion.CourseVersion) error {
	return nil
}
func (m *mockRepo) ArchiveAllApproved(_ context.Context, _ uuid.UUID) error { return nil }
func (m *mockRepo) UpdateApprovalWorkflow(_ context.Context, cv *courseversion.CourseVersion) error {
	m.updated = cv
	return m.updateErr
}
func (m *mockRepo) GetByID(_ context.Context, _ uuid.UUID) (*courseversion.CourseVersion, error) {
	if m.getErr != nil {
		return nil, m.getErr
	}
	return m.current, nil
}
func (m *mockRepo) ListByType(_ context.Context, _ uuid.UUID) ([]*courseversion.CourseVersion, error) {
	return nil, nil
}
func (m *mockRepo) GetApproved(_ context.Context, _ uuid.UUID) (*courseversion.CourseVersion, error) {
	return nil, nil
}
func (m *mockRepo) ListPending(_ context.Context, _ *uuid.UUID) ([]*courseversion.CourseVersion, error) {
	return nil, nil
}

func newDraftVersion(t *testing.T) *courseversion.CourseVersion {
	t.Helper()
	cv, err := courseversion.NewCourseVersion(uuid.New(), "1.0.0", "minor", "init", nil)
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	return cv
}

func TestHandler_Handle_Success(t *testing.T) {
	cv := newDraftVersion(t)
	repo := &mockRepo{current: cv}
	bus := eventbus.NewInMemoryEventBus()
	h := submit_courseversion.NewHandler(repo, repo, bus)

	user := uuid.New()
	cmd := &submit_courseversion.SubmitCourseVersionCommand{VersionID: cv.ID, SubmittedBy: user}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo.updated == nil {
		t.Fatal("expected repo.UpdateApprovalWorkflow to be called")
	}
	if repo.updated.ApprovalStatus != courseversion.ApprovalStatusSubmitted {
		t.Fatalf("expected submitted, got %q", repo.updated.ApprovalStatus)
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockRepo{}
	bus := eventbus.NewInMemoryEventBus()
	h := submit_courseversion.NewHandler(repo, repo, bus)

	if err := h.Handle(context.Background(), nil); !errors.Is(err, submit_courseversion.ErrInvalidCommand) {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestHandler_Handle_InvalidTransition(t *testing.T) {
	cv := newDraftVersion(t)
	_ = cv.Submit(uuid.New()) // already submitted
	repo := &mockRepo{current: cv}
	bus := eventbus.NewInMemoryEventBus()
	h := submit_courseversion.NewHandler(repo, repo, bus)

	cmd := &submit_courseversion.SubmitCourseVersionCommand{VersionID: cv.ID, SubmittedBy: uuid.New()}
	if err := h.Handle(context.Background(), cmd); !errors.Is(err, courseversion.ErrInvalidApprovalState) {
		t.Fatalf("expected ErrInvalidApprovalState, got %v", err)
	}
}
