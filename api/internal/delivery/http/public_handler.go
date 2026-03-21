package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	createenrollment "github.com/vernonedu/entrepreneurship-api/internal/command/create_enrollment"
	createlead "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead"
	createstudent "github.com/vernonedu/entrepreneurship-api/internal/command/create_student"
	getcmsarticlepub "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_article"
	getcmspagepub "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_page"
	getcoursebatchpub "github.com/vernonedu/entrepreneurship-api/internal/query/get_course_batch"
	listcmsarticlespub "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_articles"
	listcmsfaqpub "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_faq"
	listcmstestimonialspub "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_testimonials"
	listcoursebatchpub "github.com/vernonedu/entrepreneurship-api/internal/query/list_course_batch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"

	"github.com/google/uuid"
)

type PublicHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewPublicHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *PublicHandler {
	return &PublicHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterPublicRoutes(h *PublicHandler, r chi.Router) {
	r.Get("/api/v1/public/pages/{slug}", h.GetPage)
	r.Get("/api/v1/public/articles", h.ListArticles)
	r.Get("/api/v1/public/articles/{slug}", h.GetArticle)
	r.Get("/api/v1/public/testimonials", h.ListTestimonials)
	r.Get("/api/v1/public/faq", h.ListFaq)
	r.Get("/api/v1/public/stats", h.GetStats)
	r.Get("/api/v1/public/courses", h.ListCourses)
	r.Get("/api/v1/public/courses/{id}", h.GetCourse)
	r.Get("/api/v1/public/batches/{id}", h.GetBatch)
	r.Post("/api/v1/public/enrollment", h.PublicEnrollment)
	r.Post("/api/v1/public/contact", h.Contact)
	r.Get("/api/v1/public/certificates/{code}", h.VerifyCertificate)
}

// ─── PAGES ────────────────────────────────────────────────────────────────────

func (h *PublicHandler) GetPage(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	result, err := h.qryBus.Execute(r.Context(), &getcmspagepub.GetCmsPageQuery{Slug: slug})
	if err != nil {
		log.Error().Err(err).Str("slug", slug).Msg("failed to get public cms page")
		writeError(w, http.StatusNotFound, "page not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── ARTICLES ─────────────────────────────────────────────────────────────────

func (h *PublicHandler) ListArticles(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listcmsarticlespub.ListCmsArticlesQuery{
		Category: category,
		Status:   "published",
		Offset:   offset,
		Limit:    limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list public articles")
		writeError(w, http.StatusInternalServerError, "failed to list articles")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PublicHandler) GetArticle(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	result, err := h.qryBus.Execute(r.Context(), &getcmsarticlepub.GetCmsArticleQuery{Slug: slug})
	if err != nil {
		log.Error().Err(err).Str("slug", slug).Msg("failed to get public article")
		writeError(w, http.StatusNotFound, "article not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── TESTIMONIALS ─────────────────────────────────────────────────────────────

func (h *PublicHandler) ListTestimonials(w http.ResponseWriter, r *http.Request) {
	courseID := r.URL.Query().Get("course_id")
	isFeaturedStr := r.URL.Query().Get("is_featured")

	var isFeatured *bool
	if isFeaturedStr != "" {
		b := isFeaturedStr == "true"
		isFeatured = &b
	}

	result, err := h.qryBus.Execute(r.Context(), &listcmstestimonialspub.ListCmsTestimonialsQuery{
		CourseID:   courseID,
		IsFeatured: isFeatured,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list public testimonials")
		writeError(w, http.StatusInternalServerError, "failed to list testimonials")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── FAQ ──────────────────────────────────────────────────────────────────────

func (h *PublicHandler) ListFaq(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	pageSlug := r.URL.Query().Get("page_slug")

	result, err := h.qryBus.Execute(r.Context(), &listcmsfaqpub.ListCmsFaqQuery{
		Category: category,
		PageSlug: pageSlug,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list public faq")
		writeError(w, http.StatusInternalServerError, "failed to list faq")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── STATS ────────────────────────────────────────────────────────────────────

func (h *PublicHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	// TODO: replace with real aggregate queries when analytics are wired
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"students": 0,
			"courses":  0,
			"partners": 0,
			"branches": 0,
		},
	})
}

// ─── COURSES ──────────────────────────────────────────────────────────────────

func (h *PublicHandler) ListCourses(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	// TODO: filter by WebsiteVisible=true when ListCourseBatchQuery supports it
	result, err := h.qryBus.Execute(r.Context(), &listcoursebatchpub.ListCourseBatchQuery{
		Offset: offset,
		Limit:  limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list public courses")
		writeError(w, http.StatusInternalServerError, "failed to list courses")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PublicHandler) GetCourse(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getcoursebatchpub.GetCourseBatchQuery{CourseBatchID: id})
	if err != nil {
		log.Error().Err(err).Str("id", idStr).Msg("failed to get public course")
		writeError(w, http.StatusNotFound, "course not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *PublicHandler) GetBatch(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid batch id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getcoursebatchpub.GetCourseBatchQuery{CourseBatchID: id})
	if err != nil {
		log.Error().Err(err).Str("id", idStr).Msg("failed to get public batch")
		writeError(w, http.StatusNotFound, "batch not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── ENROLLMENT ───────────────────────────────────────────────────────────────

type publicEnrollmentRequest struct {
	StudentName   string `json:"student_name"`
	StudentEmail  string `json:"student_email"`
	StudentPhone  string `json:"student_phone"`
	CourseBatchID string `json:"course_batch_id"`
	Notes         string `json:"notes"`
}

func (h *PublicHandler) PublicEnrollment(w http.ResponseWriter, r *http.Request) {
	var body publicEnrollmentRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	// Step 1: create student
	studentCmd := &createstudent.CreateStudentCommand{
		Name:  body.StudentName,
		Email: body.StudentEmail,
		Phone: body.StudentPhone,
	}
	if err := h.cmdBus.Execute(r.Context(), studentCmd); err != nil {
		log.Error().Err(err).Msg("failed to create student for public enrollment")
		writeError(w, http.StatusInternalServerError, "failed to process enrollment")
		return
	}

	// Step 2: parse course batch ID
	batchID, err := uuid.Parse(body.CourseBatchID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course_batch_id")
		return
	}

	// TODO: look up the newly created student ID; for now we use a nil UUID placeholder
	// Full implementation requires returning the student ID from create_student or using a separate lookup.
	enrollCmd := &createenrollment.CreateEnrollmentCommand{
		StudentID:     uuid.Nil,
		CourseBatchID: batchID,
	}
	if err := h.cmdBus.Execute(r.Context(), enrollCmd); err != nil {
		log.Error().Err(err).Msg("failed to create enrollment for public enrollment")
		writeError(w, http.StatusInternalServerError, "failed to process enrollment")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "enrollment request received"})
}

// ─── CONTACT ──────────────────────────────────────────────────────────────────

type contactRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone"`
	Subject string `json:"subject"`
	Message string `json:"message"`
}

func (h *PublicHandler) Contact(w http.ResponseWriter, r *http.Request) {
	var body contactRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createlead.CreateLeadCommand{
		Name:    body.Name,
		Email:   body.Email,
		Phone:   body.Phone,
		Source:  "website_contact",
		Notes:   body.Subject + "\n" + body.Message,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create lead from contact form")
		writeError(w, http.StatusInternalServerError, "failed to submit contact")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "contact submitted"})
}

// ─── CERTIFICATE VERIFICATION ─────────────────────────────────────────────────

func (h *PublicHandler) VerifyCertificate(w http.ResponseWriter, r *http.Request) {
	// TODO: implement certificate verification when certificate domain is wired
	writeError(w, http.StatusNotImplemented, "certificate verification not yet implemented")
}
