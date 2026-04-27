package catalog

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
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

// CreateCourseInput is the structured input for creating a course.
type CreateCourseInput struct {
	Name            string
	DepartmentID    uuid.UUID
	CourseCreatorID uuid.UUID
	BasePrice       decimal.Decimal
	MinPrice        decimal.Decimal
	Description     *string
	CreatedBy       uuid.UUID
}

// UpdateCourseInput is the structured input for updating a course. Nil fields
// leave the existing value untouched.
type UpdateCourseInput struct {
	ID          uuid.UUID
	Name        *string
	BasePrice   *decimal.Decimal
	MinPrice    *decimal.Decimal
	Description *string
}

// CreateCourse creates a new course with price-validation.
func (s *Service) CreateCourse(ctx context.Context, in CreateCourseInput) (*Course, error) {
	if strings.TrimSpace(in.Name) == "" {
		return nil, apperrors.Validationf("name is required")
	}
	if in.MinPrice.GreaterThan(in.BasePrice) {
		return nil, apperrors.Validationf("min_price cannot exceed base_price")
	}
	c := &Course{
		ID:              uuid.New(),
		Name:            in.Name,
		DepartmentID:    in.DepartmentID,
		CourseCreatorID: in.CourseCreatorID,
		BasePrice:       in.BasePrice,
		MinPrice:        in.MinPrice,
		Description:     in.Description,
		IsActive:        true,
		CreatedBy:       in.CreatedBy,
	}
	if err := s.repo.CreateCourse(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

// UpdateCourse applies a partial update to an existing course.
func (s *Service) UpdateCourse(ctx context.Context, in UpdateCourseInput) (*Course, error) {
	existing, err := s.repo.GetCourseByID(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	if in.Name != nil {
		existing.Name = *in.Name
	}
	if in.Description != nil {
		existing.Description = in.Description
	}
	if in.BasePrice != nil {
		existing.BasePrice = *in.BasePrice
	}
	if in.MinPrice != nil {
		existing.MinPrice = *in.MinPrice
	}
	if existing.MinPrice.GreaterThan(existing.BasePrice) {
		return nil, apperrors.Validationf("min_price cannot exceed base_price")
	}
	if err := s.repo.UpdateCourse(ctx, existing); err != nil {
		return nil, err
	}
	return existing, nil
}

// GetCourse fetches course by ID.
func (s *Service) GetCourse(ctx context.Context, id uuid.UUID) (*Course, error) {
	return s.repo.GetCourseByID(ctx, id)
}

// ListCoursesByDepartment returns all courses under a department.
func (s *Service) ListCoursesByDepartment(ctx context.Context, deptID uuid.UUID) ([]*Course, error) {
	return s.repo.ListCoursesByDepartment(ctx, deptID)
}

// OpenBatch transitions batch from draft to open. Requires:
//   - batch currently in draft status
//   - parent course has at least one enabled CourseFormatConfig
//   - batch.price within [course.min_price, course.base_price]
func (s *Service) OpenBatch(ctx context.Context, batchID uuid.UUID) error {
	batch, err := s.repo.GetBatchByID(ctx, batchID)
	if err != nil {
		return err
	}
	if batch.Status != BatchDraft {
		return apperrors.Validationf("batch must be in draft status to open")
	}
	formats, err := s.repo.ListFormatConfigsByCourse(ctx, batch.CourseID)
	if err != nil {
		return err
	}
	hasEnabled := false
	for _, f := range formats {
		if f.IsEnabled {
			hasEnabled = true
			break
		}
	}
	if !hasEnabled {
		return apperrors.Validationf("course has no enabled format configuration")
	}
	course, err := s.repo.GetCourseByID(ctx, batch.CourseID)
	if err != nil {
		return err
	}
	if batch.Price.LessThan(course.MinPrice) {
		return apperrors.Validationf("batch price below course min_price")
	}
	if batch.Price.GreaterThan(course.BasePrice) {
		return apperrors.Validationf("batch price above course base_price")
	}
	return s.repo.UpdateBatchStatus(ctx, batchID, BatchOpen)
}

// MoveToOngoing transitions batch from open to ongoing. Enforces that the
// number of confirmed enrollments meets the min_students threshold of every
// enabled CourseFormatConfig on the parent course.
func (s *Service) MoveToOngoing(ctx context.Context, batchID uuid.UUID) error {
	batch, err := s.repo.GetBatchByID(ctx, batchID)
	if err != nil {
		return err
	}
	if batch.Status != BatchOpen {
		return apperrors.Validationf("batch must be in open status to move to ongoing")
	}
	formats, err := s.repo.ListFormatConfigsByCourse(ctx, batch.CourseID)
	if err != nil {
		return err
	}
	enrolled, err := s.repo.CountEnrollmentsByBatch(ctx, batchID)
	if err != nil {
		return err
	}
	for _, f := range formats {
		if !f.IsEnabled {
			continue
		}
		if f.MinStudents != nil && enrolled < *f.MinStudents {
			return apperrors.Validationf("enrolled student count below min_students for an enabled format")
		}
	}
	return s.repo.UpdateBatchStatus(ctx, batchID, BatchOngoing)
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
		Payload: events.BatchClosedPayload{BatchID: batchID, CourseID: batch.CourseID},
	})
	return nil
}

// CreateBatchInput is the structured input for creating a course batch.
// Cost templates registered on the parent course are copied into
// finance.batch_cost_line_items as part of the same transaction.
type CreateBatchInput struct {
	CourseID            uuid.UUID
	Label               string
	StartDate           time.Time
	EndDate             time.Time
	Price               decimal.Decimal
	BatchBulkPrice      *decimal.Decimal
	WebRegistrationOpen bool
	CreatedBy           uuid.UUID
}

// CreateBatch creates a new course batch and copies cost templates from the
// parent course into batch cost line items.
func (s *Service) CreateBatch(ctx context.Context, in CreateBatchInput) (*CourseBatch, error) {
	b := &CourseBatch{
		ID:                  uuid.New(),
		CourseID:            in.CourseID,
		Label:               in.Label,
		StartDate:           in.StartDate,
		EndDate:             in.EndDate,
		Price:               in.Price,
		BatchBulkPrice:      in.BatchBulkPrice,
		Status:              BatchDraft,
		WebRegistrationOpen: in.WebRegistrationOpen,
		CreatedBy:           in.CreatedBy,
	}
	if err := s.repo.CreateBatchWithCostsCopy(ctx, b, in.CreatedBy); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.BatchCreated,
		Payload: events.BatchCreatedPayload{
			BatchID:  b.ID,
			CourseID: b.CourseID,
			Classes:  []events.ClassPayload{},
		},
	})
	return b, nil
}

// CreateCourseCostTemplateInput is the input for adding a cost template to a course.
type CreateCourseCostTemplateInput struct {
	CourseID uuid.UUID
	Label    string
	Amount   decimal.Decimal
	CostType CostType
}

// CreateCourseCostTemplate registers a default cost line on a course; this is
// what gets copied to each new batch.
func (s *Service) CreateCourseCostTemplate(ctx context.Context, in CreateCourseCostTemplateInput) (*CourseCostTemplate, error) {
	if strings.TrimSpace(in.Label) == "" {
		return nil, apperrors.Validationf("label is required")
	}
	if in.CostType == "" {
		in.CostType = CostFixed
	}
	t := &CourseCostTemplate{
		ID:       uuid.New(),
		CourseID: in.CourseID,
		Label:    in.Label,
		Amount:   in.Amount,
		CostType: in.CostType,
	}
	if err := s.repo.CreateCourseCostTemplate(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

// ListCourseCostTemplates returns all cost templates for a course.
func (s *Service) ListCourseCostTemplates(ctx context.Context, courseID uuid.UUID) ([]*CourseCostTemplate, error) {
	return s.repo.ListCourseCostTemplates(ctx, courseID)
}

// ListBatchCostLineItems returns all cost line items for a batch.
func (s *Service) ListBatchCostLineItems(ctx context.Context, batchID uuid.UUID) ([]*BatchCostLineItem, error) {
	return s.repo.ListBatchCostLineItems(ctx, batchID)
}

// GetBatch fetches batch by ID.
func (s *Service) GetBatch(ctx context.Context, id uuid.UUID) (*CourseBatch, error) {
	return s.repo.GetBatchByID(ctx, id)
}

// ListBatchesByCourse returns batches for a course.
func (s *Service) ListBatchesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseBatch, error) {
	return s.repo.ListBatchesByCourse(ctx, courseID)
}

// CreateClassInput is the structured input for scheduling a class within a batch.
type CreateClassInput struct {
	CourseBatchID  uuid.UUID
	Title          *string
	SessionDate    time.Time
	StartTime      string // "HH:MM" or "HH:MM:SS"
	EndTime        string
	Mode           DeliveryMode
	Location       *string
	OnlineLink     *string
	InstructorID   uuid.UUID
	InstructorType InstructorType
	AssignedBy     AssignedByType
}

// CreateClass schedules a class within a batch. Validates mode-specific
// requirements (offline → location, online → online_link) and, for facilitator
// instructors, requires an approved FacilitatorProposal.
func (s *Service) CreateClass(ctx context.Context, in CreateClassInput) (*Class, error) {
	if in.Mode == ModeOffline && (in.Location == nil || strings.TrimSpace(*in.Location) == "") {
		return nil, apperrors.Validationf("location required for offline mode")
	}
	if in.Mode == ModeOnline && (in.OnlineLink == nil || strings.TrimSpace(*in.OnlineLink) == "") {
		return nil, apperrors.Validationf("online_link required for online mode")
	}
	if in.InstructorType == InstructorFacilitator {
		if err := s.assertApprovedFacilitator(ctx, in.InstructorID); err != nil {
			return nil, err
		}
	}
	cl := &Class{
		ID:             uuid.New(),
		CourseBatchID:  in.CourseBatchID,
		Title:          in.Title,
		SessionDate:    in.SessionDate,
		StartTime:      in.StartTime,
		EndTime:        in.EndTime,
		Mode:           in.Mode,
		Location:       in.Location,
		OnlineLink:     in.OnlineLink,
		InstructorID:   in.InstructorID,
		InstructorType: in.InstructorType,
		AssignedBy:     in.AssignedBy,
	}
	if err := s.repo.CreateClass(ctx, cl); err != nil {
		return nil, err
	}
	if in.InstructorType == InstructorFacilitator {
		_ = s.bus.Publish(ctx, events.Event{
			Type: events.ClassFacilitatorAssigned,
			Payload: events.ClassFacilitatorAssignedPayload{
				ClassID:       cl.ID,
				FacilitatorID: in.InstructorID,
			},
		})
	}
	return cl, nil
}

// AssignInstructor (re)assigns the instructor on an existing class. For
// facilitator assignments, an approved FacilitatorProposal is required. The
// class.facilitator_assigned event is published on facilitator assignment.
func (s *Service) AssignInstructor(
	ctx context.Context,
	classID, instructorID uuid.UUID,
	instructorType InstructorType,
	assignedBy AssignedByType,
) error {
	if instructorType == InstructorFacilitator {
		if err := s.assertApprovedFacilitator(ctx, instructorID); err != nil {
			return err
		}
	}
	if err := s.repo.UpdateClassInstructor(ctx, classID, instructorID, instructorType, assignedBy); err != nil {
		return err
	}
	if instructorType == InstructorFacilitator {
		_ = s.bus.Publish(ctx, events.Event{
			Type: events.ClassFacilitatorAssigned,
			Payload: events.ClassFacilitatorAssignedPayload{
				ClassID:       classID,
				FacilitatorID: instructorID,
			},
		})
	}
	return nil
}

// RescheduleClass updates the session date/time of a class and emits
// course.class.rescheduled with the new start/end times.
func (s *Service) RescheduleClass(
	ctx context.Context,
	classID uuid.UUID,
	sessionDate time.Time,
	startTime, endTime string,
) error {
	if err := s.repo.UpdateClassSchedule(ctx, classID, sessionDate, startTime, endTime); err != nil {
		return err
	}
	startAt, _ := combineDateTime(sessionDate, startTime)
	endAt, _ := combineDateTime(sessionDate, endTime)
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.ClassRescheduled,
		Payload: events.ClassRescheduledPayload{
			ClassID: classID,
			StartAt: startAt,
			EndAt:   endAt,
		},
	})
	return nil
}

// CancelClass deletes a class and emits course.class.cancelled.
func (s *Service) CancelClass(ctx context.Context, classID uuid.UUID) error {
	if err := s.repo.DeleteClass(ctx, classID); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.ClassCancelled,
		Payload: events.ClassCancelledPayload{ClassID: classID},
	})
	return nil
}

// assertApprovedFacilitator returns nil only when the user has both a
// FacilitatorProfile and at least one approved FacilitatorProposal.
func (s *Service) assertApprovedFacilitator(ctx context.Context, userID uuid.UUID) error {
	ok, err := s.repo.IsApprovedFacilitator(ctx, userID)
	if err != nil {
		return err
	}
	if !ok {
		return apperrors.Validationf("instructor is not an approved facilitator")
	}
	return nil
}

// combineDateTime merges a calendar date with an "HH:MM" or "HH:MM:SS" string
// into a UTC time.Time. Returns the date itself on parse failure.
func combineDateTime(d time.Time, hhmm string) (time.Time, error) {
	layouts := []string{"15:04:05", "15:04"}
	for _, layout := range layouts {
		t, err := time.Parse(layout, hhmm)
		if err == nil {
			return time.Date(d.Year(), d.Month(), d.Day(), t.Hour(), t.Minute(), t.Second(), 0, time.UTC), nil
		}
	}
	return d, apperrors.Validationf("invalid time format")
}

// GetClass fetches class by ID.
func (s *Service) GetClass(ctx context.Context, id uuid.UUID) (*Class, error) {
	return s.repo.GetClassByID(ctx, id)
}

// ListClassesByBatch returns all classes in a batch.
func (s *Service) ListClassesByBatch(ctx context.Context, batchID uuid.UUID) ([]*Class, error) {
	return s.repo.ListClassesByBatch(ctx, batchID)
}

// CreateModule creates a module for a course.
func (s *Service) CreateModule(ctx context.Context, m *CourseModule) error {
	m.ID = uuid.New()
	m.IsActive = true
	return s.repo.CreateModule(ctx, m)
}

// ListModulesByCourse returns ordered modules for a course.
func (s *Service) ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	return s.repo.ListModulesByCourse(ctx, courseID)
}

// AddFormatConfigInput is structured input for adding a course format config.
type AddFormatConfigInput struct {
	CourseID    uuid.UUID
	Format      CourseFormat
	MinStudents *int
	MaxStudents *int
	ModeOnline  bool
	ModeOffline bool
}

// AddFormatConfig adds a per-format config for a course. Returns ErrConflict
// if a config for the same (course, format) already exists.
func (s *Service) AddFormatConfig(ctx context.Context, in AddFormatConfigInput) (*CourseFormatConfig, error) {
	if in.MinStudents != nil && in.MaxStudents != nil && *in.MinStudents > *in.MaxStudents {
		return nil, apperrors.Validationf("min_students cannot exceed max_students")
	}
	cfg := &CourseFormatConfig{
		ID:          uuid.New(),
		CourseID:    in.CourseID,
		Format:      in.Format,
		IsEnabled:   true,
		MinStudents: in.MinStudents,
		MaxStudents: in.MaxStudents,
		ModeOnline:  in.ModeOnline,
		ModeOffline: in.ModeOffline,
	}
	if err := s.repo.AddFormatConfig(ctx, cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}

// DisableFormat marks a format config as disabled.
func (s *Service) DisableFormat(ctx context.Context, id uuid.UUID) error {
	return s.repo.DisableFormat(ctx, id)
}

// ListFormatConfigs returns all format configs for a course.
func (s *Service) ListFormatConfigs(ctx context.Context, courseID uuid.UUID) ([]*CourseFormatConfig, error) {
	return s.repo.ListFormatConfigsByCourse(ctx, courseID)
}

// CreateModuleVersion creates a new version of a module.
func (s *Service) CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error {
	mv.ID = uuid.New()
	mv.Status = ModuleDraft
	return s.repo.CreateModuleVersion(ctx, mv)
}
