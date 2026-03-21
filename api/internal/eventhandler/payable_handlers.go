package eventhandler

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// AttendanceSubmittedPayload is the expected payload for the AttendanceSubmitted event.
// Published by the session/attendance command handler when a facilitator submits attendance.
type AttendanceSubmittedPayload struct {
	SessionID       uuid.UUID `json:"session_id"`
	BatchID         uuid.UUID `json:"batch_id"`
	BatchName       string    `json:"batch_name"`
	FacilitatorID   uuid.UUID `json:"facilitator_id"`
	FacilitatorName string    `json:"facilitator_name"`
	FacilitatorLevel int      `json:"facilitator_level"`
	Timestamp       int64     `json:"timestamp"`
}

// BatchCompletedPayload is the expected payload for the BatchCompleted event.
// Published by the batch command handler when a batch is marked as completed.
type BatchCompletedPayload struct {
	BatchID           uuid.UUID  `json:"batch_id"`
	BatchName         string     `json:"batch_name"`
	CourseCreatorID   uuid.UUID  `json:"course_creator_id"`
	CourseCreatorName string     `json:"course_creator_name"`
	DeptLeaderID      uuid.UUID  `json:"dept_leader_id"`
	DeptLeaderName    string     `json:"dept_leader_name"`
	OpLeaderID        uuid.UUID  `json:"op_leader_id"`
	OpLeaderName      string     `json:"op_leader_name"`
	TotalRevenue      float64    `json:"total_revenue"`
	TotalProfit       float64    `json:"total_profit"`
	BranchID          *uuid.UUID `json:"branch_id,omitempty"`
	Timestamp         int64      `json:"timestamp"`
}

// EnrollmentCreatedWithReferralPayload contains enrollment + optional referral partner info.
type EnrollmentCreatedWithReferralPayload struct {
	EnrollmentID      uuid.UUID  `json:"enrollment_id"`
	StudentID         uuid.UUID  `json:"student_id"`
	CourseBatchID     uuid.UUID  `json:"course_batch_id"`
	ReferralPartnerID *uuid.UUID `json:"referral_partner_id,omitempty"`
	ReferralPartnerName string   `json:"referral_partner_name,omitempty"`
	ReferralAmount    int64      `json:"referral_amount,omitempty"`
	BranchID          *uuid.UUID `json:"branch_id,omitempty"`
	Timestamp         int64      `json:"timestamp"`
}

// PayableEventHandler creates payables and journal entries in response to domain events.
type PayableEventHandler struct {
	payableRepo    payable.WriteRepository
	commissionRepo settings.CommissionReadRepository
	facLevelRepo   settings.FacilitatorLevelReadRepository
	txRepo         accounting.TransactionWriteRepository
}

func NewPayableEventHandler(
	payableRepo payable.WriteRepository,
	commissionRepo settings.CommissionReadRepository,
	facLevelRepo settings.FacilitatorLevelReadRepository,
	txRepo accounting.TransactionWriteRepository,
) *PayableEventHandler {
	return &PayableEventHandler{
		payableRepo:    payableRepo,
		commissionRepo: commissionRepo,
		facLevelRepo:   facLevelRepo,
		txRepo:         txRepo,
	}
}

// OnAttendanceSubmitted creates a facilitator AP and the corresponding journal entry.
func (h *PayableEventHandler) OnAttendanceSubmitted(ctx context.Context, data []byte) error {
	var payload AttendanceSubmittedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to unmarshal AttendanceSubmitted")
		return err
	}

	// Resolve fee from facilitator level
	levels, err := h.facLevelRepo.List(ctx)
	if err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to list facilitator levels")
		return err
	}

	var feePerSession int64
	for _, lvl := range levels {
		if lvl.Level == payload.FacilitatorLevel {
			feePerSession = lvl.FeePerSession
			break
		}
	}
	if feePerSession == 0 {
		log.Warn().
			Int("level", payload.FacilitatorLevel).
			Str("facilitator_id", payload.FacilitatorID.String()).
			Msg("PayableHandler: facilitator level not found, skipping AP creation")
		return nil
	}

	batchID := payload.BatchID
	p, err := payable.NewPayable(
		payable.TypeFacilitator,
		payload.FacilitatorID,
		payload.FacilitatorName,
		&batchID,
		feePerSession,
		payable.SourceAuto,
		nil,
		fmt.Sprintf("Session %s — Batch %s", payload.SessionID, payload.BatchName),
	)
	if err != nil {
		return err
	}

	if err := h.payableRepo.Save(ctx, p); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to save facilitator payable")
		return err
	}

	// Journal entry: Debit 5001 Biaya Fasilitator / Credit 2100 Hutang Fasilitator
	tx := &accounting.Transaction{
		ReferenceNumber:   fmt.Sprintf("AP-FAC-%s", time.Now().Format("20060102-150405")),
		Description:       fmt.Sprintf("Biaya Fasilitator %s — %s", payload.FacilitatorName, payload.BatchName),
		TransactionType:   "expense",
		Amount:            float64(feePerSession),
		DebitAccountCode:  payable.AccountBiayaFasilitator,
		CreditAccountCode: payable.AccountHutangFasilitator,
		Category:          "facilitator_fee",
		RelatedEntityType: "payable",
		RelatedEntityID:   &p.ID,
		TransactionDate:   time.Now(),
		Status:            "completed",
	}
	if err := h.txRepo.Create(ctx, tx); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to create facilitator journal entry")
		return err
	}

	log.Info().
		Str("payable_id", p.ID.String()).
		Str("facilitator_id", payload.FacilitatorID.String()).
		Int64("amount", feePerSession).
		Msg("PayableHandler: facilitator AP created")

	return nil
}

// OnBatchCompleted creates commission APs for course creator, dept leader, and op leader.
func (h *PayableEventHandler) OnBatchCompleted(ctx context.Context, data []byte) error {
	var payload BatchCompletedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to unmarshal BatchCompleted")
		return err
	}

	cfg, err := h.commissionRepo.Get(ctx)
	if err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to get commission config")
		return err
	}

	type commissionEntry struct {
		payableType string
		recipientID uuid.UUID
		name        string
		pct         float64
		basis       string
	}

	entries := []commissionEntry{
		{payable.TypeCommissionCourseCreator, payload.CourseCreatorID, payload.CourseCreatorName, cfg.CourseCreatorPct, cfg.CourseCreatorBasis},
		{payable.TypeCommissionDeptLeader, payload.DeptLeaderID, payload.DeptLeaderName, cfg.DeptLeaderPct, cfg.DeptLeaderBasis},
		{payable.TypeCommissionOpLeader, payload.OpLeaderID, payload.OpLeaderName, cfg.OpLeaderPct, cfg.OpLeaderBasis},
	}

	for _, e := range entries {
		base := payload.TotalRevenue
		if e.basis == "profit" {
			base = payload.TotalProfit
		}
		amount := int64(base * e.pct / 100)
		if amount <= 0 {
			continue
		}

		batchID := payload.BatchID
		p, err := payable.NewPayable(
			e.payableType,
			e.recipientID,
			e.name,
			&batchID,
			amount,
			payable.SourceAuto,
			payload.BranchID,
			fmt.Sprintf("Komisi Batch %s", payload.BatchName),
		)
		if err != nil {
			log.Error().Err(err).Str("type", e.payableType).Msg("PayableHandler: failed to build payable")
			continue
		}
		p.CalculationBasis = e.basis
		p.CalculationPercentage = e.pct

		if err := h.payableRepo.Save(ctx, p); err != nil {
			log.Error().Err(err).Str("type", e.payableType).Msg("PayableHandler: failed to save commission payable")
			continue
		}

		// Journal entry: Debit expense / Credit hutang
		tx := &accounting.Transaction{
			ReferenceNumber:   fmt.Sprintf("AP-COM-%s", time.Now().Format("20060102-150405")),
			Description:       fmt.Sprintf("Komisi %s — %s", e.name, payload.BatchName),
			TransactionType:   "expense",
			Amount:            float64(amount),
			DebitAccountCode:  payable.ExpenseAccount(e.payableType),
			CreditAccountCode: payable.HutangAccount(e.payableType),
			Category:          "commission",
			RelatedEntityType: "payable",
			RelatedEntityID:   &p.ID,
			TransactionDate:   time.Now(),
			Status:            "completed",
		}
		if err := h.txRepo.Create(ctx, tx); err != nil {
			log.Error().Err(err).Str("type", e.payableType).Msg("PayableHandler: failed to create commission journal entry")
		}

		log.Info().
			Str("payable_id", p.ID.String()).
			Str("type", e.payableType).
			Int64("amount", amount).
			Msg("PayableHandler: commission AP created")
	}

	return nil
}

// OnEnrollmentCreated creates a marketing partner AP when a referral partner is involved.
func (h *PayableEventHandler) OnEnrollmentCreated(ctx context.Context, data []byte) error {
	var payload EnrollmentCreatedWithReferralPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to unmarshal EnrollmentCreated")
		return err
	}

	if payload.ReferralPartnerID == nil || payload.ReferralAmount <= 0 {
		return nil // no referral, skip
	}

	batchID := payload.CourseBatchID
	p, err := payable.NewPayable(
		payable.TypeMarketingPartner,
		*payload.ReferralPartnerID,
		payload.ReferralPartnerName,
		&batchID,
		payload.ReferralAmount,
		payable.SourceAuto,
		payload.BranchID,
		fmt.Sprintf("Referral enrollment %s", payload.EnrollmentID),
	)
	if err != nil {
		return err
	}

	if err := h.payableRepo.Save(ctx, p); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to save marketing partner payable")
		return err
	}

	// Journal entry: Debit 5005 Biaya Marketing / Credit 2204 Hutang Marketing
	tx := &accounting.Transaction{
		ReferenceNumber:   fmt.Sprintf("AP-MKT-%s", time.Now().Format("20060102-150405")),
		Description:       fmt.Sprintf("Referral — %s", payload.ReferralPartnerName),
		TransactionType:   "expense",
		Amount:            float64(payload.ReferralAmount),
		DebitAccountCode:  payable.AccountBiayaMarketing,
		CreditAccountCode: payable.AccountHutangMarketing,
		Category:          "referral_commission",
		RelatedEntityType: "payable",
		RelatedEntityID:   &p.ID,
		TransactionDate:   time.Now(),
		Status:            "completed",
	}
	if err := h.txRepo.Create(ctx, tx); err != nil {
		log.Error().Err(err).Msg("PayableHandler: failed to create marketing journal entry")
		return err
	}

	log.Info().
		Str("payable_id", p.ID.String()).
		Str("partner_id", payload.ReferralPartnerID.String()).
		Int64("amount", payload.ReferralAmount).
		Msg("PayableHandler: marketing partner AP created")

	return nil
}
