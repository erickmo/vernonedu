package catalog

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
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

func (h *Handler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var course Course
	if err := json.NewDecoder(r.Body).Decode(&course); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	course.CreatedBy = uc.ID
	course.CourseCreatorID = uc.ID

	if err := h.svc.CreateCourse(r.Context(), &course); err != nil {
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
	q := r.URL.Query()

	var deptID *uuid.UUID
	if s := q.Get("department_id"); s != "" {
		id, err := uuid.Parse(s)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid department_id"))
			return
		}
		deptID = &id
	}

	page, _ := strconv.Atoi(q.Get("page"))
	limit, _ := strconv.Atoi(q.Get("limit"))

	result, err := h.svc.ListCourses(r.Context(), deptID, page, limit)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}

func (h *Handler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}

	if err := h.svc.AssertCourseOwner(r.Context(), id, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}

	var course Course
	if err := json.NewDecoder(r.Body).Decode(&course); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	course.ID = id

	if err := h.svc.UpdateCourse(r.Context(), &course); err != nil {
		apperrors.Render(w, err)
		return
	}

	updated, err := h.svc.GetCourse(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(updated)
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
	batch.CreatedBy = uc.ID

	if err := h.svc.CreateBatch(r.Context(), &batch); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(batch)
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

func (h *Handler) ListBatchesByCourseID(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
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

func (h *Handler) CreateClass(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var cl Class
	if err := json.NewDecoder(r.Body).Decode(&cl); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	switch uc.Role {
	case roleCourseCreator:
		cl.AssignedBy = "course_creator_self"
	case roleDeptLeader:
		cl.AssignedBy = "dept_leader"
	case roleAdmin:
		if cl.AssignedBy != "course_creator_self" && cl.AssignedBy != "dept_leader" {
			cl.AssignedBy = "course_creator_self"
		}
	default:
		apperrors.Render(w, apperrors.ErrForbidden)
		return
	}
	if err := h.svc.CreateClass(r.Context(), &cl); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(cl)
}

func (h *Handler) PatchBatchStatus(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req struct {
		Status BatchStatus `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Status == "" {
		apperrors.Render(w, apperrors.Validationf("status is required"))
		return
	}
	switch req.Status {
	case BatchDraft, BatchOpen, BatchOngoing, BatchClosed:
		// valid
	default:
		apperrors.Render(w, apperrors.Validationf("invalid status value"))
		return
	}
	batch, err := h.svc.GetBatch(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), batch.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.UpdateBatchStatus(r.Context(), id, req.Status); err != nil {
		apperrors.Render(w, err)
		return
	}
	batch, err = h.svc.GetBatch(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(batch)
}
