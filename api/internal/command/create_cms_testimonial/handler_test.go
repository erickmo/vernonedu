package create_cms_testimonial_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_testimonial"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

// mockTestimonialWriteRepo is a test double for cms.TestimonialWriteRepository.
type mockTestimonialWriteRepo struct {
	saved *cms.CmsTestimonial
	err   error
}

func (m *mockTestimonialWriteRepo) SaveTestimonial(_ context.Context, t *cms.CmsTestimonial) error {
	m.saved = t
	return m.err
}

func (m *mockTestimonialWriteRepo) UpdateTestimonial(_ context.Context, t *cms.CmsTestimonial) error {
	return nil
}

func (m *mockTestimonialWriteRepo) DeleteTestimonial(_ context.Context, id uuid.UUID) error {
	return nil
}

func TestCreateTestimonial_Success(t *testing.T) {
	mock := &mockTestimonialWriteRepo{}
	h := create_cms_testimonial.NewHandler(mock)
	cmd := &create_cms_testimonial.CreateCmsTestimonialCommand{
		StudentName: "Alice",
		Quote:       "Great course!",
		Rating:      5,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved == nil {
		t.Fatal("testimonial was not saved")
	}
	if mock.saved.Rating != 5 {
		t.Errorf("expected rating 5, got %d", mock.saved.Rating)
	}
	if mock.saved.StudentName != "Alice" {
		t.Errorf("expected student name Alice, got %s", mock.saved.StudentName)
	}
	if mock.saved.ID == uuid.Nil {
		t.Error("testimonial ID should be auto-generated")
	}
}

func TestCreateTestimonial_WithCourseID(t *testing.T) {
	mock := &mockTestimonialWriteRepo{}
	h := create_cms_testimonial.NewHandler(mock)
	courseID := uuid.New()
	cmd := &create_cms_testimonial.CreateCmsTestimonialCommand{
		StudentName: "Bob",
		Quote:       "Excellent!",
		Rating:      4,
		CourseID:    courseID.String(),
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved.CourseID == nil {
		t.Fatal("expected course ID to be set")
	}
	if *mock.saved.CourseID != courseID {
		t.Errorf("expected course ID %s, got %s", courseID, *mock.saved.CourseID)
	}
}

func TestCreateTestimonial_WithInvalidCourseID(t *testing.T) {
	// Invalid course ID should be silently ignored (not an error)
	mock := &mockTestimonialWriteRepo{}
	h := create_cms_testimonial.NewHandler(mock)
	cmd := &create_cms_testimonial.CreateCmsTestimonialCommand{
		StudentName: "Charlie",
		Quote:       "Good!",
		Rating:      3,
		CourseID:    "not-a-uuid",
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved.CourseID != nil {
		t.Error("expected course ID to be nil for invalid UUID input")
	}
}

func TestCreateTestimonial_SaveError(t *testing.T) {
	mock := &mockTestimonialWriteRepo{err: errors.New("db error")}
	h := create_cms_testimonial.NewHandler(mock)
	cmd := &create_cms_testimonial.CreateCmsTestimonialCommand{
		StudentName: "Dave",
		Quote:       "Nice!",
		Rating:      4,
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error from save")
	}
}

func TestCreateTestimonial_WrongCommand(t *testing.T) {
	mock := &mockTestimonialWriteRepo{}
	h := create_cms_testimonial.NewHandler(mock)
	if err := h.Handle(context.Background(), nil); err == nil {
		t.Fatal("expected error for wrong command type")
	}
}

func TestCreateTestimonial_IsFeatured(t *testing.T) {
	mock := &mockTestimonialWriteRepo{}
	h := create_cms_testimonial.NewHandler(mock)
	cmd := &create_cms_testimonial.CreateCmsTestimonialCommand{
		StudentName: "Eve",
		Quote:       "Featured!",
		Rating:      5,
		IsFeatured:  true,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !mock.saved.IsFeatured {
		t.Error("expected is_featured to be true")
	}
}
