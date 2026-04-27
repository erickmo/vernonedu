package catalog

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds catalog HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs a catalog Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type createCourseRequest struct {
	Name            string          `json:"name"`
	DepartmentID    uuid.UUID       `json:"department_id"`
	CourseCreatorID uuid.UUID       `json:"course_creator_id"`
	BasePrice       decimal.Decimal `json:"base_price"`
	MinPrice        decimal.Decimal `json:"min_price"`
	Description     *string         `json:"description,omitempty"`
}

func (h *Handler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req createCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	course, err := h.svc.CreateCourse(r.Context(), CreateCourseInput{
		Name:            req.Name,
		DepartmentID:    req.DepartmentID,
		CourseCreatorID: req.CourseCreatorID,
		BasePrice:       req.BasePrice,
		MinPrice:        req.MinPrice,
		Description:     req.Description,
		CreatedBy:       uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(course)
}

func (h *Handler) GetCourse(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}

	course, err := h.svc.GetCourse(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(course)
}

func (h *Handler) ListCourses(w http.ResponseWriter, r *http.Request) {
	deptIDStr := r.URL.Query().Get("department_id")
	if deptIDStr == "" {
		apperrors.Render(w, apperrors.Validationf("department_id query param required"))
		return
	}

	deptID, err := uuid.Parse(deptIDStr)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid department_id"))
		return
	}

	courses, err := h.svc.ListCoursesByDepartment(r.Context(), deptID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(courses)
}

func (h *Handler) CreateBatch(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var batch CourseBatch
	if err := json.NewDecoder(r.Body).Decode(&batch); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	created, err := h.svc.CreateBatch(r.Context(), CreateBatchInput{
		CourseID:            batch.CourseID,
		Label:               batch.Label,
		StartDate:           batch.StartDate,
		EndDate:             batch.EndDate,
		Price:               batch.Price,
		BatchBulkPrice:      batch.BatchBulkPrice,
		WebRegistrationOpen: batch.WebRegistrationOpen,
		CreatedBy:           uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

func (h *Handler) GetBatch(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}

	batch, err := h.svc.GetBatch(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(batch)
}

func (h *Handler) ListBatches(w http.ResponseWriter, r *http.Request) {
	courseIDStr := r.URL.Query().Get("course_id")
	if courseIDStr == "" {
		apperrors.Render(w, apperrors.Validationf("course_id query param required"))
		return
	}

	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_id"))
		return
	}

	batches, err := h.svc.ListBatchesByCourse(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(batches)
}

func (h *Handler) OpenBatch(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}

	if err := h.svc.OpenBatch(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CloseBatch(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}

	if err := h.svc.CloseBatch(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListClasses(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "batchID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}

	classes, err := h.svc.ListClassesByBatch(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(classes)
}
