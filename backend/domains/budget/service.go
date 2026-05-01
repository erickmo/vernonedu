package budget

import (
	"context"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

const msgPlannedAmountLocked = "planned_amount is locked for this item"
const msgClassIDMismatch = "realization class_id must match item class_id"

// Service handles budget domain business logic.
type Service struct {
	repo Repository
	log  *zap.Logger
}

// NewService constructs budget Service (FX-injectable).
func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// ─── Template Items ───────────────────────────────────────────────────────────

func (s *Service) CreateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error {
	item.ID = uuid.New()
	now := time.Now()
	item.CreatedAt = now
	item.UpdatedAt = now
	return s.repo.CreateTemplateItem(ctx, item)
}

func (s *Service) UpdateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error {
	return s.repo.UpdateTemplateItem(ctx, item)
}

func (s *Service) DeleteTemplateItem(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteTemplateItem(ctx, id)
}

func (s *Service) ListTemplateItems(ctx context.Context, courseID uuid.UUID) ([]*CourseBudgetTemplateItem, error) {
	return s.repo.ListTemplateItems(ctx, courseID)
}

func (s *Service) GetTemplateItem(ctx context.Context, id uuid.UUID) (*CourseBudgetTemplateItem, error) {
	return s.repo.GetTemplateItem(ctx, id)
}

// ─── Batch Items ──────────────────────────────────────────────────────────────

func (s *Service) CreateBatchItem(ctx context.Context, item *BatchBudgetItem) error {
	item.ID = uuid.New()
	now := time.Now()
	item.CreatedAt = now
	item.UpdatedAt = now
	return s.repo.CreateBatchItem(ctx, item)
}

// UpdateBatchItem enforces overridable lock on planned_amount.
func (s *Service) UpdateBatchItem(ctx context.Context, updated *BatchBudgetItem) error {
	existing, err := s.repo.GetBatchItem(ctx, updated.ID)
	if err != nil {
		return err
	}
	if !existing.Overridable && updated.PlannedAmount != existing.PlannedAmount {
		return apperrors.Validationf(msgPlannedAmountLocked)
	}
	return s.repo.UpdateBatchItem(ctx, updated)
}

func (s *Service) DeleteBatchItem(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteBatchItem(ctx, id)
}

func (s *Service) ListBatchItems(ctx context.Context, batchID uuid.UUID) ([]*BatchBudgetItem, error) {
	return s.repo.ListBatchItems(ctx, batchID)
}

func (s *Service) GetBatchItem(ctx context.Context, id uuid.UUID) (*BatchBudgetItem, error) {
	return s.repo.GetBatchItem(ctx, id)
}

// ─── Realizations ─────────────────────────────────────────────────────────────

// CreateRealization validates class_id consistency before persisting.
func (s *Service) CreateRealization(ctx context.Context, r *BudgetRealization) error {
	item, err := s.repo.GetBatchItem(ctx, r.BatchBudgetItemID)
	if err != nil {
		return err
	}
	if err := validateClassID(item.ClassID, r.ClassID); err != nil {
		return err
	}
	r.ID = uuid.New()
	r.CreatedAt = time.Now()
	r.UpdatedAt = r.CreatedAt
	if r.SpentAt.IsZero() {
		r.SpentAt = time.Now()
	}
	return s.repo.CreateRealization(ctx, r)
}

func (s *Service) UpdateRealization(ctx context.Context, r *BudgetRealization) error {
	existing, err := s.repo.GetRealization(ctx, r.ID)
	if err != nil {
		return err
	}
	item, err := s.repo.GetBatchItem(ctx, existing.BatchBudgetItemID)
	if err != nil {
		return err
	}
	if err := validateClassID(item.ClassID, r.ClassID); err != nil {
		return err
	}
	return s.repo.UpdateRealization(ctx, r)
}

func (s *Service) DeleteRealization(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteRealization(ctx, id)
}

func (s *Service) ListRealizations(ctx context.Context, batchItemID uuid.UUID) ([]*BudgetRealization, error) {
	return s.repo.ListRealizations(ctx, batchItemID)
}

func (s *Service) GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error) {
	return s.repo.GetRealization(ctx, id)
}

// ─── Summary ──────────────────────────────────────────────────────────────────

func (s *Service) GetBatchSummary(ctx context.Context, batchID uuid.UUID) (*BatchBudgetSummary, error) {
	return s.repo.GetBatchSummary(ctx, batchID)
}

// ─── Event handler ────────────────────────────────────────────────────────────

// OnBatchCreated copies all course template items into batch budget items.
func (s *Service) OnBatchCreated(ctx context.Context, batchID uuid.UUID, courseID uuid.UUID, actorID uuid.UUID) error {
	templates, err := s.repo.ListTemplateItems(ctx, courseID)
	if err != nil {
		return err
	}
	for _, tmpl := range templates {
		ref := tmpl.ID
		item := &BatchBudgetItem{
			CourseBatchID: batchID,
			TemplateRefID: &ref,
			Label:         tmpl.Label,
			Category:      tmpl.Category,
			PlannedAmount: tmpl.PresetAmount,
			Overridable:   tmpl.Overridable,
			CreatedBy:     actorID,
		}
		if err := s.CreateBatchItem(ctx, item); err != nil {
			s.log.Error("budget: failed to copy template item to batch",
				zap.String("batch_id", batchID.String()),
				zap.String("template_id", tmpl.ID.String()),
				zap.Error(err),
			)
			return err
		}
	}
	return nil
}

// ─── Private helpers ──────────────────────────────────────────────────────────

// validateClassID enforces rule 6: realization class_id must match item class_id when item is class-mapped.
func validateClassID(itemClassID *uuid.UUID, realizationClassID *uuid.UUID) error {
	if itemClassID == nil {
		return nil
	}
	if realizationClassID == nil || *realizationClassID != *itemClassID {
		return apperrors.Validationf(msgClassIDMismatch)
	}
	return nil
}
