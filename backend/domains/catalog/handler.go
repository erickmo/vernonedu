package catalog

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

// Role constants used for ownership checks.
const (
	roleAdmin          = "admin"
	roleVernoneduAdmin = "vernonedu_admin"
	roleCourseCreator  = "course_creator"
	roleDeptLeader     = "dept_leader"
)

// Handler holds catalog HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs a catalog Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func writeJSON(w http.ResponseWriter, status int, body interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

// ----- Ownership helpers ------------------------------------------------

func (h *Handler) assertCourseOwnerOrAdmin(r *http.Request, courseID uuid.UUID) error {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		return apperrors.ErrUnauthorized
	}
	if uc.Role == roleAdmin || uc.Role == roleVernoneduAdmin {
		return nil
	}
	course, err := h.svc.GetCourse(r.Context(), courseID)
	if err != nil {
		return err
	}
	if course.CourseCreatorID != uc.ID {
		return apperrors.ErrForbidden
	}
	return nil
}

func (h *Handler) assertBatchOwnerOrAdmin(r *http.Request, batchID uuid.UUID) error {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		return apperrors.ErrUnauthorized
	}
	if uc.Role == roleAdmin || uc.Role == roleVernoneduAdmin {
		return nil
	}
	batch, err := h.svc.GetBatch(r.Context(), batchID)
	if err != nil {
		return err
	}
	return h.assertCourseOwnerOrAdmin(r, batch.CourseID)
}

func (h *Handler) assertClassOwnerOrAdmin(r *http.Request, classID uuid.UUID) error {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		return apperrors.ErrUnauthorized
	}
	if uc.Role == roleAdmin || uc.Role == roleVernoneduAdmin {
		return nil
	}
	class, err := h.svc.GetClass(r.Context(), classID)
	if err != nil {
		return err
	}
	return h.assertBatchOwnerOrAdmin(r, class.CourseBatchID)
}

// ----- Course handlers --------------------------------------------------

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
	writeJSON(w, http.StatusCreated, course)
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
	writeJSON(w, http.StatusOK, course)
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
	writeJSON(w, http.StatusOK, courses)
}

type updateCourseRequest struct {
	Name        *string          `json:"name,omitempty"`
	BasePrice   *decimal.Decimal `json:"base_price,omitempty"`
	MinPrice    *decimal.Decimal `json:"min_price,omitempty"`
	Description *string          `json:"description,omitempty"`
}

func (h *Handler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	if err := h.assertCourseOwnerOrAdmin(r, courseID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req updateCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	out, err := h.svc.UpdateCourse(r.Context(), UpdateCourseInput{
		ID:          courseID,
		Name:        req.Name,
		BasePrice:   req.BasePrice,
		MinPrice:    req.MinPrice,
		Description: req.Description,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

type addFormatConfigRequest struct {
	Format      CourseFormat `json:"format"`
	MinStudents *int         `json:"min_students,omitempty"`
	MaxStudents *int         `json:"max_students,omitempty"`
	ModeOnline  bool         `json:"mode_online"`
	ModeOffline bool         `json:"mode_offline"`
}

func (h *Handler) AddFormatConfig(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	if err := h.assertCourseOwnerOrAdmin(r, courseID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req addFormatConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	cfg, err := h.svc.AddFormatConfig(r.Context(), AddFormatConfigInput{
		CourseID:    courseID,
		Format:      req.Format,
		MinStudents: req.MinStudents,
		MaxStudents: req.MaxStudents,
		ModeOnline:  req.ModeOnline,
		ModeOffline: req.ModeOffline,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, cfg)
}

// ----- Batch handlers ---------------------------------------------------

type createBatchRequest struct {
	Label               string           `json:"label"`
	StartDate           time.Time        `json:"start_date"`
	EndDate             time.Time        `json:"end_date"`
	Price               decimal.Decimal  `json:"price"`
	BatchBulkPrice      *decimal.Decimal `json:"batch_bulk_price,omitempty"`
	WebRegistrationOpen bool             `json:"web_registration_open"`
}

func (h *Handler) CreateBatch(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	courseID, err := uuid.Parse(chi.URLParam(r, "courseID"))
	if err != nil {
		// Fall back to body-driven CourseID for legacy POST /api/v1/batches.
		var batch CourseBatch
		if derr := json.NewDecoder(r.Body).Decode(&batch); derr != nil {
			apperrors.Render(w, apperrors.Validationf("invalid request body"))
			return
		}
		created, cerr := h.svc.CreateBatch(r.Context(), CreateBatchInput{
			CourseID:            batch.CourseID,
			Label:               batch.Label,
			StartDate:           batch.StartDate,
			EndDate:             batch.EndDate,
			Price:               batch.Price,
			BatchBulkPrice:      batch.BatchBulkPrice,
			WebRegistrationOpen: batch.WebRegistrationOpen,
			CreatedBy:           uc.ID,
		})
		if cerr != nil {
			apperrors.Render(w, cerr)
			return
		}
		writeJSON(w, http.StatusCreated, created)
		return
	}
	if err := h.assertCourseOwnerOrAdmin(r, courseID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req createBatchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	created, err := h.svc.CreateBatch(r.Context(), CreateBatchInput{
		CourseID:            courseID,
		Label:               req.Label,
		StartDate:           req.StartDate,
		EndDate:             req.EndDate,
		Price:               req.Price,
		BatchBulkPrice:      req.BatchBulkPrice,
		WebRegistrationOpen: req.WebRegistrationOpen,
		CreatedBy:           uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, created)
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
	writeJSON(w, http.StatusOK, batch)
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
	writeJSON(w, http.StatusOK, batches)
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

func (h *Handler) MoveToOngoing(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	if err := h.svc.MoveToOngoing(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ----- Class handlers ---------------------------------------------------

type createClassRequest struct {
	Title          *string        `json:"title,omitempty"`
	SessionDate    time.Time      `json:"session_date"`
	StartTime      string         `json:"start_time"`
	EndTime        string         `json:"end_time"`
	Mode           DeliveryMode   `json:"mode"`
	Location       *string        `json:"location,omitempty"`
	OnlineLink     *string        `json:"online_link,omitempty"`
	InstructorID   uuid.UUID      `json:"instructor_id"`
	InstructorType InstructorType `json:"instructor_type"`
	AssignedBy     AssignedByType `json:"assigned_by"`
}

func (h *Handler) CreateClass(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	if err := h.assertBatchOwnerOrAdmin(r, batchID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req createClassRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	cl, err := h.svc.CreateClass(r.Context(), CreateClassInput{
		CourseBatchID:  batchID,
		Title:          req.Title,
		SessionDate:    req.SessionDate,
		StartTime:      req.StartTime,
		EndTime:        req.EndTime,
		Mode:           req.Mode,
		Location:       req.Location,
		OnlineLink:     req.OnlineLink,
		InstructorID:   req.InstructorID,
		InstructorType: req.InstructorType,
		AssignedBy:     req.AssignedBy,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, cl)
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
	writeJSON(w, http.StatusOK, classes)
}

type assignInstructorRequest struct {
	InstructorID   uuid.UUID      `json:"instructor_id"`
	InstructorType InstructorType `json:"instructor_type"`
	AssignedBy     AssignedByType `json:"assigned_by"`
}

func (h *Handler) AssignInstructor(w http.ResponseWriter, r *http.Request) {
	classID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	// dept_leader bypasses ownership; course_creator must own.
	if uc.Role != roleDeptLeader {
		if err := h.assertClassOwnerOrAdmin(r, classID); err != nil {
			apperrors.Render(w, err)
			return
		}
	}
	var req assignInstructorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.AssignInstructor(r.Context(), classID, req.InstructorID, req.InstructorType, req.AssignedBy); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type rescheduleClassRequest struct {
	SessionDate time.Time `json:"session_date"`
	StartTime   string    `json:"start_time"`
	EndTime     string    `json:"end_time"`
}

func (h *Handler) RescheduleClass(w http.ResponseWriter, r *http.Request) {
	classID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	if err := h.assertClassOwnerOrAdmin(r, classID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req rescheduleClassRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.RescheduleClass(r.Context(), classID, req.SessionDate, req.StartTime, req.EndTime); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelClass(w http.ResponseWriter, r *http.Request) {
	classID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	if err := h.svc.CancelClass(r.Context(), classID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ----- Cost template handlers ------------------------------------------

type createCostTemplateRequest struct {
	Label    string          `json:"label"`
	Amount   decimal.Decimal `json:"amount"`
	CostType CostType        `json:"cost_type"`
}

func (h *Handler) CreateCostTemplate(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "courseID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	if err := h.assertCourseOwnerOrAdmin(r, courseID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req createCostTemplateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	out, err := h.svc.CreateCourseCostTemplate(r.Context(), CreateCourseCostTemplateInput{
		CourseID: courseID,
		Label:    req.Label,
		Amount:   req.Amount,
		CostType: req.CostType,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, out)
}

func (h *Handler) ListBatchCostLineItems(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "batchID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	if err := h.assertBatchOwnerOrAdmin(r, batchID); err != nil {
		apperrors.Render(w, err)
		return
	}
	items, err := h.svc.ListBatchCostLineItems(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

// ----- Module handlers --------------------------------------------------

type createModuleRequest struct {
	Title string `json:"title"`
	Order int    `json:"order"`
}

func (h *Handler) CreateModule(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "courseID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	if err := h.assertCourseOwnerOrAdmin(r, courseID); err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	var req createModuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	m, err := h.svc.CreateModule(r.Context(), CreateModuleInput{
		CourseID:  courseID,
		Title:     req.Title,
		Order:     req.Order,
		CreatedBy: uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, m)
}

type createModuleVersionRequest struct {
	VersionNumber int     `json:"version_number"`
	Title         string  `json:"title"`
	Description   *string `json:"description,omitempty"`
}

func (h *Handler) CreateModuleVersion(w http.ResponseWriter, r *http.Request) {
	moduleID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	// Resolve module → course for ownership check.
	if err := h.assertModuleOwner(r, moduleID); err != nil {
		apperrors.Render(w, err)
		return
	}
	var req createModuleVersionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	mv := &ModuleVersion{
		ModuleID:      moduleID,
		VersionNumber: req.VersionNumber,
		Title:         req.Title,
		Description:   req.Description,
		CreatedBy:     uc.ID,
	}
	if err := h.svc.CreateModuleVersion(r.Context(), mv); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, mv)
}

func (h *Handler) assertModuleOwner(r *http.Request, moduleID uuid.UUID) error {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		return apperrors.ErrUnauthorized
	}
	if uc.Role == roleAdmin || uc.Role == roleVernoneduAdmin {
		return nil
	}
	mod, err := h.svc.repo.GetModuleByID(r.Context(), moduleID)
	if err != nil {
		return err
	}
	return h.assertCourseOwnerOrAdmin(r, mod.CourseID)
}

func (h *Handler) PublishModuleVersion(w http.ResponseWriter, r *http.Request) {
	versionID, err := uuid.Parse(chi.URLParam(r, "vid"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	v, err := h.svc.repo.GetModuleVersionByID(r.Context(), versionID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.assertModuleOwner(r, v.ModuleID); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.PublishModuleVersion(r.Context(), versionID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type lockBatchVersionRequest struct {
	VersionID uuid.UUID `json:"version_id"`
}

func (h *Handler) LockBatchToVersion(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "batchID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	moduleID, err := uuid.Parse(chi.URLParam(r, "modID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if uc.Role != roleDeptLeader {
		if err := h.assertBatchOwnerOrAdmin(r, batchID); err != nil {
			apperrors.Render(w, err)
			return
		}
	}
	var req lockBatchVersionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	cfg, err := h.svc.LockBatchToVersion(r.Context(), batchID, moduleID, req.VersionID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, cfg)
}

type batchModuleRow struct {
	Module          *CourseModule  `json:"module"`
	ResolvedVersion *ModuleVersion `json:"resolved_version,omitempty"`
}

func (h *Handler) ListBatchModules(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "batchID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	batch, err := h.svc.GetBatch(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	modules, err := h.svc.ListModulesByCourse(r.Context(), batch.CourseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	rows := make([]batchModuleRow, 0, len(modules))
	for _, m := range modules {
		v, vErr := h.svc.ResolveModuleVersion(r.Context(), batchID, m.ID)
		if vErr != nil {
			rows = append(rows, batchModuleRow{Module: m, ResolvedVersion: nil})
			continue
		}
		rows = append(rows, batchModuleRow{Module: m, ResolvedVersion: v})
	}
	writeJSON(w, http.StatusOK, rows)
}
