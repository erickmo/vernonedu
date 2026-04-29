package catalog

import (
	"context"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds catalog business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs catalog Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// CreateCourse creates a new course.
func (s *Service) CreateCourse(ctx context.Context, c *Course) error {
	c.ID = uuid.New()
	return s.repo.CreateCourse(ctx, c)
}

// GetCourse fetches course by ID.
func (s *Service) GetCourse(ctx context.Context, id uuid.UUID) (*Course, error) {
	return s.repo.GetCourseByID(ctx, id)
}

// ListCoursesByDepartment returns all courses under a department.
func (s *Service) ListCoursesByDepartment(ctx context.Context, deptID uuid.UUID) ([]*Course, error) {
	return s.repo.ListCoursesByDepartment(ctx, deptID)
}

// ListCourses returns paginated courses with optional department filter.
func (s *Service) ListCourses(ctx context.Context, deptID *uuid.UUID, page, limit int) (*PaginatedCourses, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 15
	}
	courses, total, err := s.repo.ListCourses(ctx, deptID, page, limit)
	if err != nil {
		return nil, err
	}
	if courses == nil {
		courses = []*Course{}
	}
	return &PaginatedCourses{Data: courses, Total: total, Page: page, Limit: limit}, nil
}

// UpdateCourse updates mutable course fields.
func (s *Service) UpdateCourse(ctx context.Context, c *Course) error {
	return s.repo.UpdateCourse(ctx, c)
}

// OpenBatch transitions batch from draft to open.
func (s *Service) OpenBatch(ctx context.Context, batchID uuid.UUID) error {
	batch, err := s.repo.GetBatchByID(ctx, batchID)
	if err != nil {
		return err
	}
	if batch.Status != BatchDraft {
		return apperrors.Validationf("batch must be in draft status to open")
	}
	return s.repo.UpdateBatchStatus(ctx, batchID, BatchOpen)
}

// CloseBatch transitions batch to closed and publishes BatchClosed event.
func (s *Service) CloseBatch(ctx context.Context, batchID uuid.UUID) error {
	batch, err := s.repo.GetBatchByID(ctx, batchID)
	if err != nil {
		return err
	}
	if batch.Status == BatchClosed {
		return apperrors.Validationf("batch is already closed")
	}
	if err := s.repo.UpdateBatchStatus(ctx, batchID, BatchClosed); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.BatchClosed,
		Payload: BatchClosedPayload{BatchID: batchID, CourseID: batch.CourseID},
	})
	return nil
}

// CreateBatch creates a new course batch.
func (s *Service) CreateBatch(ctx context.Context, b *CourseBatch) error {
	b.ID = uuid.New()
	b.Status = BatchDraft
	if err := s.repo.CreateBatch(ctx, b); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.BatchCreated,
		Payload: BatchCreatedPayload{BatchID: b.ID, CourseID: b.CourseID, ActorID: b.CreatedBy},
	})
	return nil
}

// GetBatch fetches batch by ID.
func (s *Service) GetBatch(ctx context.Context, id uuid.UUID) (*CourseBatch, error) {
	return s.repo.GetBatchByID(ctx, id)
}

// ListBatchesByCourse returns batches for a course.
func (s *Service) ListBatchesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseBatch, error) {
	return s.repo.ListBatchesByCourse(ctx, courseID)
}

// CreateClass adds a class to a batch.
func (s *Service) CreateClass(ctx context.Context, cl *Class) error {
	cl.ID = uuid.New()
	return s.repo.CreateClass(ctx, cl)
}

// GetClass fetches class by ID.
func (s *Service) GetClass(ctx context.Context, id uuid.UUID) (*Class, error) {
	return s.repo.GetClassByID(ctx, id)
}

// ListClassesByBatch returns all classes in a batch.
func (s *Service) ListClassesByBatch(ctx context.Context, batchID uuid.UUID) ([]*Class, error) {
	return s.repo.ListClassesByBatch(ctx, batchID)
}

// UpdateBatchStatus updates a batch status directly.
func (s *Service) UpdateBatchStatus(ctx context.Context, batchID uuid.UUID, status BatchStatus) error {
	return s.repo.UpdateBatchStatus(ctx, batchID, status)
}

// AssertCourseOwner returns ErrForbidden if actorID is not the course creator (unless admin).
func (s *Service) AssertCourseOwner(ctx context.Context, courseID, actorID uuid.UUID, role string) error {
	if role == roleAdmin {
		return nil
	}
	course, err := s.repo.GetCourseByID(ctx, courseID)
	if err != nil {
		return err
	}
	if course.CourseCreatorID != actorID {
		return apperrors.ErrForbidden
	}
	return nil
}

