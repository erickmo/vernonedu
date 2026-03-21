package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createpost          "github.com/vernonedu/entrepreneurship-api/internal/command/create_post"
	createpr            "github.com/vernonedu/entrepreneurship-api/internal/command/create_pr"
	createrefpartner    "github.com/vernonedu/entrepreneurship-api/internal/command/create_referral_partner"
	deletepost          "github.com/vernonedu/entrepreneurship-api/internal/command/delete_post"
	deletepr            "github.com/vernonedu/entrepreneurship-api/internal/command/delete_pr"
	submitposturl       "github.com/vernonedu/entrepreneurship-api/internal/command/submit_post_url"
	updatepost          "github.com/vernonedu/entrepreneurship-api/internal/command/update_post"
	updatepr            "github.com/vernonedu/entrepreneurship-api/internal/command/update_pr"
	updaterefpartner    "github.com/vernonedu/entrepreneurship-api/internal/command/update_referral_partner"
	getmarketingstats   "github.com/vernonedu/entrepreneurship-api/internal/query/get_marketing_stats"
	listclassdocs       "github.com/vernonedu/entrepreneurship-api/internal/query/list_class_docs"
	listposts           "github.com/vernonedu/entrepreneurship-api/internal/query/list_posts"
	listpr              "github.com/vernonedu/entrepreneurship-api/internal/query/list_pr"
	listrefpartners     "github.com/vernonedu/entrepreneurship-api/internal/query/list_referral_partners"
	listreferrals       "github.com/vernonedu/entrepreneurship-api/internal/query/list_referrals"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// MarketingHandler handles all marketing-related HTTP endpoints.
type MarketingHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewMarketingHandler creates a new MarketingHandler.
func NewMarketingHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *MarketingHandler {
	return &MarketingHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// RegisterMarketingRoutes registers all marketing routes on the given router.
func RegisterMarketingRoutes(h *MarketingHandler, r chi.Router) {
	// Social media posts
	r.Get("/api/v1/marketing/posts", h.ListPosts)
	r.Post("/api/v1/marketing/posts", h.CreatePost)
	r.Put("/api/v1/marketing/posts/{id}", h.UpdatePost)
	r.Put("/api/v1/marketing/posts/{id}/submit-url", h.SubmitPostUrl)
	r.Delete("/api/v1/marketing/posts/{id}", h.DeletePost)
	// Class docs (auto-generated)
	r.Get("/api/v1/marketing/class-docs", h.ListClassDocs)
	// PR scheduling
	r.Get("/api/v1/marketing/pr", h.ListPr)
	r.Post("/api/v1/marketing/pr", h.CreatePr)
	r.Put("/api/v1/marketing/pr/{id}", h.UpdatePr)
	r.Delete("/api/v1/marketing/pr/{id}", h.DeletePr)
	// Referral partners
	r.Get("/api/v1/marketing/referral-partners", h.ListReferralPartners)
	r.Post("/api/v1/marketing/referral-partners", h.CreateReferralPartner)
	r.Put("/api/v1/marketing/referral-partners/{id}", h.UpdateReferralPartner)
	r.Get("/api/v1/marketing/referral-partners/{id}/referrals", h.ListReferrals)
	// Stats
	r.Get("/api/v1/marketing/stats", h.GetStats)
}

// ---- Social Media Posts ----

func (h *MarketingHandler) ListPosts(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 20
	}

	q := &listposts.ListPostsQuery{
		Offset:   offset,
		Limit:    limit,
		Platform: r.URL.Query().Get("platform"),
		Status:   r.URL.Query().Get("status"),
		Month:    r.URL.Query().Get("month"),
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list posts")
		writeError(w, http.StatusInternalServerError, "failed to list posts")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type createPostRequest struct {
	Platforms   []string   `json:"platforms"`
	ScheduledAt string     `json:"scheduled_at"`
	ContentType string     `json:"content_type"`
	Caption     string     `json:"caption"`
	MediaURL    string     `json:"media_url"`
	BatchID     *uuid.UUID `json:"batch_id"`
}

func (h *MarketingHandler) CreatePost(w http.ResponseWriter, r *http.Request) {
	var req createPostRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createpost.CreatePostCommand{
		Platforms:   req.Platforms,
		ScheduledAt: req.ScheduledAt,
		ContentType: req.ContentType,
		Caption:     req.Caption,
		MediaURL:    req.MediaURL,
		BatchID:     req.BatchID,
		CreatedBy:   uuid.Nil,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create post")
		writeError(w, http.StatusInternalServerError, "failed to create post")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "post created successfully"})
}

type updatePostRequest struct {
	Platforms   []string   `json:"platforms"`
	ScheduledAt string     `json:"scheduled_at"`
	ContentType string     `json:"content_type"`
	Caption     string     `json:"caption"`
	MediaURL    string     `json:"media_url"`
	BatchID     *uuid.UUID `json:"batch_id"`
	Status      string     `json:"status"`
}

func (h *MarketingHandler) UpdatePost(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid post id")
		return
	}

	var req updatePostRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatepost.UpdatePostCommand{
		ID:          id,
		Platforms:   req.Platforms,
		ScheduledAt: req.ScheduledAt,
		ContentType: req.ContentType,
		Caption:     req.Caption,
		MediaURL:    req.MediaURL,
		BatchID:     req.BatchID,
		Status:      req.Status,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update post")
		writeError(w, http.StatusInternalServerError, "failed to update post")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "post updated successfully"})
}

type submitPostUrlRequest struct {
	PostURL string `json:"post_url"`
}

func (h *MarketingHandler) SubmitPostUrl(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid post id")
		return
	}

	var req submitPostUrlRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &submitposturl.SubmitPostUrlCommand{
		ID:      id,
		PostURL: req.PostURL,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to submit post url")
		writeError(w, http.StatusInternalServerError, "failed to submit post url")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "post url submitted successfully"})
}

func (h *MarketingHandler) DeletePost(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid post id")
		return
	}

	cmd := &deletepost.DeletePostCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete post")
		writeError(w, http.StatusInternalServerError, "failed to delete post")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "post deleted successfully"})
}

// ---- Class Docs ----

func (h *MarketingHandler) ListClassDocs(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 20
	}

	q := &listclassdocs.ListClassDocsQuery{
		Offset: offset,
		Limit:  limit,
		Status: r.URL.Query().Get("status"),
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list class docs")
		writeError(w, http.StatusInternalServerError, "failed to list class docs")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ---- PR Schedules ----

func (h *MarketingHandler) ListPr(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 20
	}

	q := &listpr.ListPrQuery{
		Offset: offset,
		Limit:  limit,
		Status: r.URL.Query().Get("status"),
		Type:   r.URL.Query().Get("type"),
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list pr schedules")
		writeError(w, http.StatusInternalServerError, "failed to list pr schedules")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type createPrRequest struct {
	Title       string     `json:"title"`
	Type        string     `json:"type"`
	ScheduledAt string     `json:"scheduled_at"`
	MediaVenue  string     `json:"media_venue"`
	PicID       *uuid.UUID `json:"pic_id"`
	PicName     string     `json:"pic_name"`
	Notes       string     `json:"notes"`
}

func (h *MarketingHandler) CreatePr(w http.ResponseWriter, r *http.Request) {
	var req createPrRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createpr.CreatePrCommand{
		Title:       req.Title,
		Type:        req.Type,
		ScheduledAt: req.ScheduledAt,
		MediaVenue:  req.MediaVenue,
		PicID:       req.PicID,
		PicName:     req.PicName,
		Notes:       req.Notes,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create pr schedule")
		writeError(w, http.StatusInternalServerError, "failed to create pr schedule")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "pr schedule created successfully"})
}

type updatePrRequest struct {
	Title       string     `json:"title"`
	Type        string     `json:"type"`
	ScheduledAt string     `json:"scheduled_at"`
	MediaVenue  string     `json:"media_venue"`
	PicID       *uuid.UUID `json:"pic_id"`
	PicName     string     `json:"pic_name"`
	Status      string     `json:"status"`
	Notes       string     `json:"notes"`
}

func (h *MarketingHandler) UpdatePr(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid pr id")
		return
	}

	var req updatePrRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatepr.UpdatePrCommand{
		ID:          id,
		Title:       req.Title,
		Type:        req.Type,
		ScheduledAt: req.ScheduledAt,
		MediaVenue:  req.MediaVenue,
		PicID:       req.PicID,
		PicName:     req.PicName,
		Status:      req.Status,
		Notes:       req.Notes,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update pr schedule")
		writeError(w, http.StatusInternalServerError, "failed to update pr schedule")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "pr schedule updated successfully"})
}

func (h *MarketingHandler) DeletePr(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid pr id")
		return
	}

	cmd := &deletepr.DeletePrCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete pr schedule")
		writeError(w, http.StatusInternalServerError, "failed to delete pr schedule")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "pr schedule deleted successfully"})
}

// ---- Referral Partners ----

func (h *MarketingHandler) ListReferralPartners(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 20
	}

	var isActive *bool
	if isActiveStr := r.URL.Query().Get("is_active"); isActiveStr != "" {
		v, err := strconv.ParseBool(isActiveStr)
		if err == nil {
			isActive = &v
		}
	}

	q := &listrefpartners.ListReferralPartnersQuery{
		Offset:   offset,
		Limit:    limit,
		IsActive: isActive,
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list referral partners")
		writeError(w, http.StatusInternalServerError, "failed to list referral partners")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type createReferralPartnerRequest struct {
	Name            string  `json:"name"`
	ContactEmail    string  `json:"contact_email"`
	ReferralCode    string  `json:"referral_code"`
	CommissionType  string  `json:"commission_type"`
	CommissionValue float64 `json:"commission_value"`
}

func (h *MarketingHandler) CreateReferralPartner(w http.ResponseWriter, r *http.Request) {
	var req createReferralPartnerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createrefpartner.CreateReferralPartnerCommand{
		Name:            req.Name,
		ContactEmail:    req.ContactEmail,
		ReferralCode:    req.ReferralCode,
		CommissionType:  req.CommissionType,
		CommissionValue: req.CommissionValue,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create referral partner")
		writeError(w, http.StatusInternalServerError, "failed to create referral partner")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "referral partner created successfully"})
}

type updateReferralPartnerRequest struct {
	Name            string  `json:"name"`
	ContactEmail    string  `json:"contact_email"`
	CommissionType  string  `json:"commission_type"`
	CommissionValue float64 `json:"commission_value"`
	IsActive        *bool   `json:"is_active"`
}

func (h *MarketingHandler) UpdateReferralPartner(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid referral partner id")
		return
	}

	var req updateReferralPartnerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updaterefpartner.UpdateReferralPartnerCommand{
		ID:              id,
		Name:            req.Name,
		ContactEmail:    req.ContactEmail,
		CommissionType:  req.CommissionType,
		CommissionValue: req.CommissionValue,
		IsActive:        req.IsActive,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update referral partner")
		writeError(w, http.StatusInternalServerError, "failed to update referral partner")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "referral partner updated successfully"})
}

func (h *MarketingHandler) ListReferrals(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")

	q := &listreferrals.ListReferralsQuery{
		PartnerIDStr: idStr,
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list referrals")
		writeError(w, http.StatusInternalServerError, "failed to list referrals")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ---- Stats ----

func (h *MarketingHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	q := &getmarketingstats.GetMarketingStatsQuery{}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to get marketing stats")
		writeError(w, http.StatusInternalServerError, "failed to get marketing stats")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}
