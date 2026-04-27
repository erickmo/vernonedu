package profit_split

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

const (
	roleCEO     = "ceo"
	roleFinance = "finance"
	hundred     = 100
)

// Service holds profit_split business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs profit_split Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// ─── GlobalSettings ──────────────────────────────────────────────────────────

// UpdateGlobalSettingsInput carries parameters for setting global split.
type UpdateGlobalSettingsInput struct {
	ID               uuid.UUID
	VernonEduPct     decimal.Decimal
	CourseCreatorPct decimal.Decimal
	DeptLeaderPct    decimal.Decimal
	UpdatedBy        uuid.UUID
	UpdatedByRole    string
}

// UpdateGlobalSettings upserts the singleton global split settings.
// Only CEO may call this.
func (s *Service) UpdateGlobalSettings(ctx context.Context, in UpdateGlobalSettingsInput) (*GlobalSettings, error) {
	if in.UpdatedByRole != roleCEO {
		return nil, apperrors.ErrForbidden
	}
	if err := validatePctSum(in.VernonEduPct, in.CourseCreatorPct, in.DeptLeaderPct); err != nil {
		return nil, err
	}

	gs := &GlobalSettings{
		ID:               in.ID,
		VernonEduPct:     in.VernonEduPct,
		CourseCreatorPct: in.CourseCreatorPct,
		DeptLeaderPct:    in.DeptLeaderPct,
		UpdatedBy:        in.UpdatedBy,
	}
	if err := s.repo.UpsertGlobalSettings(ctx, gs); err != nil {
		return nil, err
	}
	return gs, nil
}

// GetGlobalSettings returns the current global split settings.
func (s *Service) GetGlobalSettings(ctx context.Context) (*GlobalSettings, error) {
	return s.repo.GetGlobalSettings(ctx)
}

// ─── CourseOverride ───────────────────────────────────────────────────────────

// CreateCourseOverrideInput carries parameters for creating a per-course split.
type CreateCourseOverrideInput struct {
	CourseID         uuid.UUID
	VernonEduPct     decimal.Decimal
	CourseCreatorPct decimal.Decimal
	DeptLeaderPct    decimal.Decimal
	OverriddenBy     uuid.UUID
	OverriddenByRole string
}

// CreateCourseOverride upserts a CEO-defined per-course split override.
func (s *Service) CreateCourseOverride(ctx context.Context, in CreateCourseOverrideInput) (*CourseOverride, error) {
	if in.OverriddenByRole != roleCEO {
		return nil, apperrors.ErrForbidden
	}
	if err := validatePctSum(in.VernonEduPct, in.CourseCreatorPct, in.DeptLeaderPct); err != nil {
		return nil, err
	}

	co := &CourseOverride{
		ID:               uuid.New(),
		CourseID:         in.CourseID,
		VernonEduPct:     in.VernonEduPct,
		CourseCreatorPct: in.CourseCreatorPct,
		DeptLeaderPct:    in.DeptLeaderPct,
		OverriddenBy:     in.OverriddenBy,
	}
	if err := s.repo.UpsertCourseOverride(ctx, co); err != nil {
		return nil, err
	}
	return co, nil
}

// GetCourseOverride returns the override for the given course.
func (s *Service) GetCourseOverride(ctx context.Context, courseID uuid.UUID) (*CourseOverride, error) {
	return s.repo.GetCourseOverride(ctx, courseID)
}

// ─── ExtraRevenue ─────────────────────────────────────────────────────────────

// AddExtraRevenueInput carries parameters for adding extra revenue.
type AddExtraRevenueInput struct {
	CourseBatchID uuid.UUID
	Label         string
	Amount        decimal.Decimal
	AddedBy       uuid.UUID
	AddedByRole   string
}

// AddExtraRevenue creates a new extra revenue entry (finance role only).
func (s *Service) AddExtraRevenue(ctx context.Context, in AddExtraRevenueInput) (*ExtraRevenue, error) {
	if in.AddedByRole != roleFinance {
		return nil, apperrors.ErrForbidden
	}
	if in.Label == "" {
		return nil, apperrors.Validationf("label is required")
	}
	if in.Amount.IsNegative() || in.Amount.IsZero() {
		return nil, apperrors.Validationf("amount must be positive")
	}

	er := &ExtraRevenue{
		ID:             uuid.New(),
		CourseBatchID:  in.CourseBatchID,
		Label:          in.Label,
		Amount:         in.Amount,
		AddedBy:        in.AddedBy,
		ApprovalStatus: ApprovalPending,
	}
	if err := s.repo.CreateExtraRevenue(ctx, er); err != nil {
		return nil, err
	}
	return er, nil
}

// ApproveExtraRevenue approves an extra revenue entry (CEO only).
func (s *Service) ApproveExtraRevenue(ctx context.Context, id, approvedBy uuid.UUID, approvedByRole string) error {
	if approvedByRole != roleCEO {
		return apperrors.ErrForbidden
	}
	return s.repo.UpdateExtraRevenueStatus(ctx, id, ApprovalApproved, &approvedBy)
}

// RejectExtraRevenue rejects an extra revenue entry (CEO only).
func (s *Service) RejectExtraRevenue(ctx context.Context, id, rejectedBy uuid.UUID, rejectedByRole string) error {
	if rejectedByRole != roleCEO {
		return apperrors.ErrForbidden
	}
	return s.repo.UpdateExtraRevenueStatus(ctx, id, ApprovalRejected, &rejectedBy)
}

// ─── BatchCostLineItem ────────────────────────────────────────────────────────

// CreateBatchCostInput carries parameters for a new cost line item.
type CreateBatchCostInput struct {
	CourseBatchID uuid.UUID
	TemplateRef   *uuid.UUID
	Label         string
	Amount        decimal.Decimal
	CostType      CostType
	ReferenceType CostRefType
	ReferenceID   *uuid.UUID
	CreatedBy     uuid.UUID
}

// CreateBatchCostLineItem adds a cost entry to a batch.
func (s *Service) CreateBatchCostLineItem(ctx context.Context, in CreateBatchCostInput) (*BatchCostLineItem, error) {
	if in.Label == "" {
		return nil, apperrors.Validationf("label is required")
	}
	if in.Amount.IsNegative() {
		return nil, apperrors.Validationf("amount must not be negative")
	}

	item := &BatchCostLineItem{
		ID:            uuid.New(),
		CourseBatchID: in.CourseBatchID,
		TemplateRef:   in.TemplateRef,
		Label:         in.Label,
		Amount:        in.Amount,
		CostType:      in.CostType,
		IsRemoved:     false,
		ReferenceType: in.ReferenceType,
		ReferenceID:   in.ReferenceID,
		CreatedBy:     in.CreatedBy,
	}
	if err := s.repo.CreateBatchCostLineItem(ctx, item); err != nil {
		return nil, err
	}
	return item, nil
}

// RemoveBatchCostLineItem soft-deletes a cost item by setting is_removed=true.
func (s *Service) RemoveBatchCostLineItem(ctx context.Context, id uuid.UUID) error {
	return s.repo.RemoveBatchCostLineItem(ctx, id)
}

// ─── BatchSplitRecord ─────────────────────────────────────────────────────────

// GetBatchSplitRecord returns the calculated split for a closed batch.
func (s *Service) GetBatchSplitRecord(ctx context.Context, batchID uuid.UUID) (*BatchSplitRecord, error) {
	return s.repo.GetBatchSplitRecord(ctx, batchID)
}

// CalculateBatchSplitInput carries data required to compute a batch split.
type CalculateBatchSplitInput struct {
	BatchID      uuid.UUID
	CourseID     uuid.UUID
	GrossRevenue decimal.Decimal
	CalculatedBy *uuid.UUID
}

// CalculateBatchSplit computes and stores the profit split for a closed batch.
// It fires the profit_split.calculated event on success.
func (s *Service) CalculateBatchSplit(ctx context.Context, in CalculateBatchSplitInput) (*BatchSplitRecord, error) {
	pcts, err := s.resolveSplitPcts(ctx, in.CourseID)
	if err != nil {
		return nil, err
	}

	costs, err := s.repo.ListActiveBatchCostLineItems(ctx, in.BatchID)
	if err != nil {
		return nil, err
	}
	extras, err := s.repo.ListApprovedExtraRevenues(ctx, in.BatchID)
	if err != nil {
		return nil, err
	}

	totalCosts := sumCosts(costs, in.GrossRevenue)
	grossWithExtra := addExtras(in.GrossRevenue, extras)
	netProfit := grossWithExtra.Sub(totalCosts)

	rec := buildSplitRecord(in.BatchID, grossWithExtra, totalCosts, netProfit, pcts, in.CalculatedBy)
	if err := s.repo.CreateBatchSplitRecord(ctx, rec); err != nil {
		return nil, err
	}

	period := in.CalculatedAt().Format("2006-01")
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.ProfitSplitCalculated,
		Payload: ProfitSplitCalculatedPayload{
			BatchID:             in.BatchID,
			CourseID:            in.CourseID,
			Period:              period,
			NetProfit:           rec.NetProfit,
			VernonEduAmount:     rec.VernonEduAmount,
			CourseCreatorAmount: rec.CourseCreatorAmount,
			DeptLeaderAmount:    rec.DeptLeaderAmount,
		},
	})

	return rec, nil
}

// ─── PeriodBonus ─────────────────────────────────────────────────────────────

// CalculatePeriodBonusInput carries parameters for period bonus aggregation.
type CalculatePeriodBonusInput struct {
	Period       string
	CalculatedBy uuid.UUID
}

// CalculatePeriodBonus aggregates all closed batch splits for a YYYY-MM period.
func (s *Service) CalculatePeriodBonus(ctx context.Context, in CalculatePeriodBonusInput) (*PeriodBonus, error) {
	if in.Period == "" {
		return nil, apperrors.Validationf("period is required (format: YYYY-MM)")
	}

	records, err := s.repo.ListClosedBatchesInPeriod(ctx, in.Period)
	if err != nil {
		return nil, err
	}

	pb := aggregatePeriodBonus(records, in.Period, in.CalculatedBy)
	if err := s.repo.UpsertPeriodBonus(ctx, pb); err != nil {
		return nil, err
	}
	return pb, nil
}

// GetPeriodBonus returns the period bonus for a YYYY-MM period.
func (s *Service) GetPeriodBonus(ctx context.Context, period string) (*PeriodBonus, error) {
	return s.repo.GetPeriodBonus(ctx, period)
}

// GetExtraRevenue returns an extra revenue entry by ID.
func (s *Service) GetExtraRevenue(ctx context.Context, id uuid.UUID) (*ExtraRevenue, error) {
	return s.repo.GetExtraRevenue(ctx, id)
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

// resolveSplitPcts returns the effective percentages for a course.
// It prefers CourseOverride over GlobalSettings.
func (s *Service) resolveSplitPcts(ctx context.Context, courseID uuid.UUID) (*GlobalSettings, error) {
	override, err := s.repo.GetCourseOverride(ctx, courseID)
	if err == nil {
		return &GlobalSettings{
			VernonEduPct:     override.VernonEduPct,
			CourseCreatorPct: override.CourseCreatorPct,
			DeptLeaderPct:    override.DeptLeaderPct,
		}, nil
	}
	return s.repo.GetGlobalSettings(ctx)
}

// sumCosts calculates total costs from active line items.
// percentage_of_revenue items are resolved against gross revenue.
func sumCosts(items []*BatchCostLineItem, grossRevenue decimal.Decimal) decimal.Decimal {
	total := decimal.Zero
	for _, item := range items {
		switch item.CostType {
		case CostFixed:
			total = total.Add(item.Amount)
		case CostPercentageRevenue:
			pct := item.Amount.Div(decimal.NewFromInt(hundred))
			total = total.Add(grossRevenue.Mul(pct))
		}
	}
	return total
}

// addExtras sums approved extra revenue into gross.
func addExtras(gross decimal.Decimal, extras []*ExtraRevenue) decimal.Decimal {
	for _, er := range extras {
		gross = gross.Add(er.Amount)
	}
	return gross
}

// buildSplitRecord constructs a BatchSplitRecord from computed values.
func buildSplitRecord(
	batchID uuid.UUID,
	gross, totalCosts, netProfit decimal.Decimal,
	pcts *GlobalSettings,
	calculatedBy *uuid.UUID,
) *BatchSplitRecord {
	vAmt := applyPct(netProfit, pcts.VernonEduPct)
	ccAmt := applyPct(netProfit, pcts.CourseCreatorPct)
	dlAmt := applyPct(netProfit, pcts.DeptLeaderPct)

	return &BatchSplitRecord{
		ID:                  uuid.New(),
		CourseBatchID:       batchID,
		GrossRevenue:        gross,
		TotalCosts:          totalCosts,
		NetProfit:           netProfit,
		VernonEduPct:        pcts.VernonEduPct,
		CourseCreatorPct:    pcts.CourseCreatorPct,
		DeptLeaderPct:       pcts.DeptLeaderPct,
		VernonEduAmount:     vAmt,
		CourseCreatorAmount: ccAmt,
		DeptLeaderAmount:    dlAmt,
		CalculatedBy:        calculatedBy,
	}
}

// aggregatePeriodBonus sums batch records into a PeriodBonus.
func aggregatePeriodBonus(records []*BatchSplitRecord, period string, calculatedBy uuid.UUID) *PeriodBonus {
	pb := &PeriodBonus{
		ID:           uuid.New(),
		Period:       period,
		PeriodType:   PeriodMonthly,
		CalculatedAt: time.Now().UTC(),
		CalculatedBy: calculatedBy,
		Status:       BonusDraft,
		BatchRefs:    make([]uuid.UUID, 0, len(records)),
	}
	for _, rec := range records {
		pb.VernonEduAmount = pb.VernonEduAmount.Add(rec.VernonEduAmount)
		pb.CourseCreatorAmount = pb.CourseCreatorAmount.Add(rec.CourseCreatorAmount)
		pb.DeptLeaderAmount = pb.DeptLeaderAmount.Add(rec.DeptLeaderAmount)
		pb.BatchRefs = append(pb.BatchRefs, rec.CourseBatchID)
	}
	return pb
}

// applyPct multiplies amount by pct/100.
func applyPct(amount, pct decimal.Decimal) decimal.Decimal {
	return amount.Mul(pct).Div(decimal.NewFromInt(hundred))
}

// validatePctSum checks that three percentages sum to 100.
func validatePctSum(a, b, c decimal.Decimal) error {
	sum := a.Add(b).Add(c)
	if !sum.Equal(decimal.NewFromInt(hundred)) {
		return apperrors.Validationf("percentages must sum to 100, got " + sum.String())
	}
	return nil
}

// CalculatedAt returns the current UTC time for use in CalculateBatchSplit.
func (in *CalculateBatchSplitInput) CalculatedAt() time.Time {
	return time.Now().UTC()
}
