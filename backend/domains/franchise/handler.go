package franchise

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds franchise HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs a franchise Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// CreateFranchisee handles POST /api/v1/franchisees (admin).
func (h *Handler) CreateFranchisee(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var body struct {
		Name       string `json:"name"`
		BranchName string `json:"branch_name"`
		Location   string `json:"location"`
		Contact    string `json:"contact"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	f := &Franchisee{
		Name:       body.Name,
		BranchName: body.BranchName,
		Location:   body.Location,
		Contact:    body.Contact,
		CreatedBy:  uc.ID,
	}
	created, err := h.svc.CreateFranchisee(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

// ListFranchisees handles GET /api/v1/franchisees.
func (h *Handler) ListFranchisees(w http.ResponseWriter, r *http.Request) {
	list, err := h.svc.ListFranchisees(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(list)
}

// GetFranchisee handles GET /api/v1/franchisees/{id}.
func (h *Handler) GetFranchisee(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee id"))
		return
	}

	f, err := h.svc.GetFranchiseeByID(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(f)
}

// CreateAgreement handles POST /api/v1/franchise-agreements (admin).
func (h *Handler) CreateAgreement(w http.ResponseWriter, r *http.Request) {
	if mw.GetUserContext(r.Context()) == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var body struct {
		FranchiseeID      string `json:"franchisee_id"`
		BuyInFee          string `json:"buy_in_fee"`
		MonthlyRoyalty    string `json:"monthly_royalty"`
		RevenueRoyaltyPct string `json:"revenue_royalty_pct"`
		StartDate         string `json:"start_date"` // YYYY-MM-DD
		EndDate           string `json:"end_date,omitempty"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	franchiseeID, err := uuid.Parse(body.FranchiseeID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee_id"))
		return
	}
	buyIn, err := decimal.NewFromString(body.BuyInFee)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid buy_in_fee"))
		return
	}
	monthly, err := decimal.NewFromString(body.MonthlyRoyalty)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid monthly_royalty"))
		return
	}
	revPct, err := decimal.NewFromString(body.RevenueRoyaltyPct)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid revenue_royalty_pct"))
		return
	}
	startDate, err := time.Parse("2006-01-02", body.StartDate)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid start_date, expected YYYY-MM-DD"))
		return
	}

	a := &FranchiseAgreement{
		FranchiseeID:      franchiseeID,
		BuyInFee:          buyIn,
		MonthlyRoyalty:    monthly,
		RevenueRoyaltyPct: revPct,
		StartDate:         startDate,
	}
	if body.EndDate != "" {
		end, err := time.Parse("2006-01-02", body.EndDate)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid end_date, expected YYYY-MM-DD"))
			return
		}
		a.EndDate = &end
	}

	created, err := h.svc.CreateAgreement(r.Context(), a)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

// GetAgreement handles GET /api/v1/franchise-agreements/{franchiseeID}.
func (h *Handler) GetAgreement(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "franchiseeID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee id"))
		return
	}

	a, err := h.svc.GetAgreementByFranchiseeID(r.Context(), franchiseeID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(a)
}

// AddBranchOtherRevenue handles POST /api/v1/franchise-revenues (admin).
func (h *Handler) AddBranchOtherRevenue(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var body struct {
		FranchiseeID string `json:"franchisee_id"`
		Label        string `json:"label"`
		Amount       string `json:"amount"`
		RevenueDate  string `json:"revenue_date"` // YYYY-MM-DD
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	franchiseeID, err := uuid.Parse(body.FranchiseeID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee_id"))
		return
	}
	amount, err := decimal.NewFromString(body.Amount)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid amount"))
		return
	}
	revenueDate, err := time.Parse("2006-01-02", body.RevenueDate)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid revenue_date, expected YYYY-MM-DD"))
		return
	}

	rev := &BranchOtherRevenue{
		FranchiseeID: franchiseeID,
		Label:        body.Label,
		Amount:       amount,
		RevenueDate:  revenueDate,
		AddedBy:      uc.ID,
	}
	created, err := h.svc.AddBranchOtherRevenue(r.Context(), rev)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

// CreateRoyaltyRecord handles POST /api/v1/royalty-records (admin).
func (h *Handler) CreateRoyaltyRecord(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var body struct {
		FranchiseeID string `json:"franchisee_id"`
		Period       string `json:"period"` // YYYY-MM
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	franchiseeID, err := uuid.Parse(body.FranchiseeID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee_id"))
		return
	}

	rec, err := h.svc.CreateRoyaltyRecord(r.Context(), franchiseeID, body.Period, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(rec)
}

// GetRoyaltyRecord handles GET /api/v1/royalty-records/{franchiseeID}/{period}.
func (h *Handler) GetRoyaltyRecord(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "franchiseeID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee id"))
		return
	}
	period := chi.URLParam(r, "period")

	rec, err := h.svc.GetRoyaltyRecord(r.Context(), franchiseeID, period)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(rec)
}

// MarkRoyaltyPaid handles POST /api/v1/royalty-records/{id}/mark-paid (admin).
func (h *Handler) MarkRoyaltyPaid(w http.ResponseWriter, r *http.Request) {
	if mw.GetUserContext(r.Context()) == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid royalty record id"))
		return
	}

	if err := h.svc.MarkRoyaltyPaid(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetMyFranchisee handles GET /api/v1/me/franchisee.
func (h *Handler) GetMyFranchisee(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	f, err := h.svc.GetMyFranchisee(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(f)
}

// ListRoyaltyRecords handles GET /api/v1/royalty-records/{franchiseeID}/all.
func (h *Handler) ListRoyaltyRecords(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "franchiseeID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee id"))
		return
	}
	records, err := h.svc.ListRoyaltyRecords(r.Context(), franchiseeID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if records == nil {
		records = []*RoyaltyPaymentRecord{}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(records)
}
