package module

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler exposes HTTP endpoints for the module domain.
type Handler struct {
	svc *Service
}

// NewHandler constructs module Handler (FX-injectable).
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ─── Module Management ────────────────────────────────────────────────────────

func (h *Handler) CreateModule(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	var req struct {
		Title string `json:"title"`
		Order int    `json:"order"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), courseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.CreateModule(r.Context(), courseID, req.Title, req.Order, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, m)
}

func (h *Handler) UpdateModule(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	var req struct {
		Title    string `json:"title"`
		Order    int    `json:"order"`
		IsActive bool   `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	updated, err := h.svc.UpdateModule(r.Context(), moduleID, req.Title, req.Order, req.IsActive)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *Handler) ListModules(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	modules, err := h.svc.ListModules(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, modules)
}

func (h *Handler) CreateVersion(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	var req struct {
		Title       string  `json:"title"`
		Description *string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	mv, err := h.svc.CreateModuleVersion(r.Context(), moduleID, req.Title, req.Description, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, mv)
}

func (h *Handler) ListVersions(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	versions, err := h.svc.ListVersionsByModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, versions)
}

func (h *Handler) PublishVersion(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	verID, err := parseUUID(chi.URLParam(r, "ver_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.PublishVersion(r.Context(), moduleID, verID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CreateAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	verID, err := parseUUID(chi.URLParam(r, "ver_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	var req struct {
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.CreateAsset(r.Context(), verID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, a)
}

func (h *Handler) UpdateAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	assetID, err := parseUUID(chi.URLParam(r, "asset_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid asset_id"))
		return
	}
	var req struct {
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.UpdateAsset(r.Context(), assetID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, a)
}

func (h *Handler) DeleteAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	assetID, err := parseUUID(chi.URLParam(r, "asset_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid asset_id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.DeleteAsset(r.Context(), assetID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Batch Config ─────────────────────────────────────────────────────────────

func (h *Handler) ListBatchModuleConfigs(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	configs, err := h.svc.ListBatchModuleConfigs(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, configs)
}

func (h *Handler) UpsertBatchModuleConfig(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	var req struct {
		VersionPolicy   VersionPolicy `json:"version_policy"`
		LockedVersionID *uuid.UUID    `json:"locked_version_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if err := h.svc.AssertBatchCourseOwner(r.Context(), batchID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	cfg, err := h.svc.UpsertBatchModuleConfig(r.Context(), batchID, moduleID, req.VersionPolicy, req.LockedVersionID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, cfg)
}

// ─── Class Progress ───────────────────────────────────────────────────────────

func (h *Handler) ListCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	items, err := h.svc.ListCoverage(r.Context(), classID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) CreateCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	var req struct {
		ModuleID uuid.UUID `json:"module_id"`
		Notes    *string   `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if err := h.svc.AssertClassAccess(r.Context(), classID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	c, err := h.svc.CreateCoverage(r.Context(), classID, req.ModuleID, req.Notes, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, c)
}

func (h *Handler) UpdateCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	covID, err := parseUUID(chi.URLParam(r, "cov_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid coverage id"))
		return
	}
	var req struct {
		Notes *string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if err := h.svc.AssertClassAccess(r.Context(), classID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	c, err := h.svc.MarkCovered(r.Context(), covID, uc.ID, req.Notes)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *Handler) DeleteCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	covID, err := parseUUID(chi.URLParam(r, "cov_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid coverage id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if err := h.svc.AssertClassAccess(r.Context(), classID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.DeleteCoverage(r.Context(), covID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetBatchProgress(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	p, err := h.svc.GetBatchProgress(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

// ─── Student Access ───────────────────────────────────────────────────────────

func (h *Handler) GetStudentModules(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	modules, err := h.svc.ResolveStudentModules(r.Context(), enrollmentID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, modules)
}

func (h *Handler) GetStudentModule(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	m, err := h.svc.ResolveStudentModule(r.Context(), enrollmentID, moduleID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, m)
}

// ─── Simplified Version/Asset Routes ─────────────────────────────────────────

func (h *Handler) ListAssetsByVersion(w http.ResponseWriter, r *http.Request) {
	verID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	assets, err := h.svc.ListAssets(r.Context(), verID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, assets)
}

func (h *Handler) PublishVersionByVersionID(w http.ResponseWriter, r *http.Request) {
	verID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	ver, err := h.svc.GetModuleVersion(r.Context(), verID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.GetModule(r.Context(), ver.ModuleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.PublishVersion(r.Context(), ver.ModuleID, verID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CreateAssetByVersionID(w http.ResponseWriter, r *http.Request) {
	var req struct {
		VersionID      uuid.UUID `json:"version_id"`
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.VersionID == uuid.Nil {
		apperrors.Render(w, apperrors.Validationf("version_id is required"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	ver, err := h.svc.GetModuleVersion(r.Context(), req.VersionID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.GetModule(r.Context(), ver.ModuleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.CreateAsset(r.Context(), req.VersionID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, a)
}

// ─── Util ─────────────────────────────────────────────────────────────────────

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
