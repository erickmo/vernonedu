package approve_courseversion_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/approve_courseversion"
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
	h := approve_courseversion.NewHandler(repo, repo, bus)

	cmd := &approve_courseversion.ApproveCourseVersionCommand{VersionID: cv.ID, ApprovedBy: uuid.New()}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if repo.updated == nil || repo.updated.ApprovalStatus != courseversion.ApprovalStatusApproved {
		t.Fatalf("expected approved, got %+v", repo.updated)
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockRepo{}
	bus := eventbus.NewInMemoryEventBus()
	h := approve_courseversion.NewHandler(repo, repo, bus)
	if err := h.Handle(context.Background(), nil); !errors.Is(err, approve_courseversion.ErrInvalidCommand) {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestHandler_Handle_InvalidTransition(t *testing.T) {
	cv, _ := courseversion.NewCourseVersion(uuid.New(), "1.0.0", "minor", "init", nil)
	repo := &mockRepo{current: cv}
	bus := eventbus.NewInMemoryEventBus()
	h := approve_courseversion.NewHandler(repo, repo, bus)

	cmd := &approve_courseversion.ApproveCourseVersionCommand{VersionID: cv.ID, ApprovedBy: uuid.New()}
	if err := h.Handle(context.Background(), cmd); !errors.Is(err, courseversion.ErrInvalidApprovalState) {
		t.Fatalf("expected ErrInvalidApprovalState, got %v", err)
	}
}
