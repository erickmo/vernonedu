package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	createcmsarticle "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_article"
	createcmsfaq "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_faq"
	createcmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_testimonial"
	deletecmsarticle "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_article"
	deletecmsfaq "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_faq"
	deletecmsmedia "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_media"
	deletecmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_testimonial"
	updatecmsarticle "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_article"
	updatecmsfaq "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_faq"
	updatecmspage "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_page"
	updatecmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_testimonial"
	uploadcmsmedia "github.com/vernonedu/entrepreneurship-api/internal/command/upload_cms_media"
	getcmsarticle "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_article"
	getcmspage "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_page"
	listcmsarticles "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_articles"
	listcmsfaq "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_faq"
	listcmsmedia "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_media"
	listcmspages "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_pages"
	listcmstestimonials "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_testimonials"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type CmsHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewCmsHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CmsHandler {
	return &CmsHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterCmsRoutes(h *CmsHandler, r chi.Router) {
	// Pages
	r.Get("/api/v1/cms/pages", h.ListPages)
	r.Get("/api/v1/cms/pages/{slug}", h.GetPage)
	r.Put("/api/v1/cms/pages/{slug}", h.UpdatePage)

	// Articles
	r.Get("/api/v1/cms/articles", h.ListArticles)
	r.Post("/api/v1/cms/articles", h.CreateArticle)
	r.Get("/api/v1/cms/articles/{slug}", h.GetArticle)
	r.Put("/api/v1/cms/articles/{id}", h.UpdateArticle)
	r.Delete("/api/v1/cms/articles/{id}", h.DeleteArticle)

	// Testimonials
	r.Get("/api/v1/cms/testimonials", h.ListTestimonials)
	r.Post("/api/v1/cms/testimonials", h.CreateTestimonial)
	r.Put("/api/v1/cms/testimonials/{id}", h.UpdateTestimonial)
	r.Delete("/api/v1/cms/testimonials/{id}", h.DeleteTestimonial)

	// FAQ
	r.Get("/api/v1/cms/faq", h.ListFaq)
	r.Post("/api/v1/cms/faq", h.CreateFaq)
	r.Put("/api/v1/cms/faq/{id}", h.UpdateFaq)
	r.Delete("/api/v1/cms/faq/{id}", h.DeleteFaq)

	// Media
	r.Get("/api/v1/cms/media", h.ListMedia)
	r.Post("/api/v1/cms/media", h.UploadMedia)
	r.Delete("/api/v1/cms/media/{id}", h.DeleteMedia)
}

// ─── PAGES ────────────────────────────────────────────────────────────────────

// ListPages godoc
// @Summary      List CMS pages
// @Description  Retrieve all CMS pages
// @Tags         cms
// @Accept       json
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/pages [get]
func (h *CmsHandler) ListPages(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &listcmspages.ListCmsPagesQuery{})
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms pages")
		writeError(w, http.StatusInternalServerError, "failed to list cms pages")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetPage godoc
// @Summary      Get CMS page by slug
// @Description  Retrieve a single CMS page by its slug
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        slug  path  string  true  "Page slug"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/pages/{slug} [get]
func (h *CmsHandler) GetPage(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	result, err := h.qryBus.Execute(r.Context(), &getcmspage.GetCmsPageQuery{Slug: slug})
	if err != nil {
		log.Error().Err(err).Str("slug", slug).Msg("failed to get cms page")
		writeError(w, http.StatusNotFound, "cms page not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdatePage godoc
// @Summary      Update CMS page
// @Description  Update a CMS page by slug (title, subtitle, content, hero image, SEO)
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        slug  path  string  true  "Page slug"
// @Param        body  body  object  true  "Page update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/pages/{slug} [put]
func (h *CmsHandler) UpdatePage(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	updatedBy := pkgmiddleware.GetUserIDFromContext(r.Context())

	var body struct {
		Title        string                 `json:"title"`
		Subtitle     string                 `json:"subtitle"`
		Content      map[string]interface{} `json:"content"`
		HeroImageURL string                 `json:"hero_image_url"`
		Seo          map[string]interface{} `json:"seo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecmspage.UpdateCmsPageCommand{
		Slug:         slug,
		Title:        body.Title,
		Subtitle:     body.Subtitle,
		Content:      body.Content,
		HeroImageURL: body.HeroImageURL,
		Seo:          body.Seo,
		UpdatedBy:    updatedBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("slug", slug).Msg("failed to update cms page")
		writeError(w, http.StatusInternalServerError, "failed to update cms page")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "page updated"})
}

// ─── ARTICLES ─────────────────────────────────────────────────────────────────

// ListArticles godoc
// @Summary      List CMS articles
// @Description  Retrieve paginated list of CMS articles with optional filters
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        category  query  string  false  "Filter by category"
// @Param        status    query  string  false  "Filter by status"
// @Param        offset    query  int     false  "Pagination offset"
// @Param        limit     query  int     false  "Pagination limit (default 20)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/articles [get]
func (h *CmsHandler) ListArticles(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	status := r.URL.Query().Get("status")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listcmsarticles.ListCmsArticlesQuery{
		Category: category,
		Status:   status,
		Offset:   offset,
		Limit:    limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms articles")
		writeError(w, http.StatusInternalServerError, "failed to list cms articles")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// CreateArticle godoc
// @Summary      Create CMS article
// @Description  Create a new CMS article with title, category, content, image, and status
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Article creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/articles [post]
func (h *CmsHandler) CreateArticle(w http.ResponseWriter, r *http.Request) {
	authorID := pkgmiddleware.GetUserIDFromContext(r.Context())

	var body struct {
		Title            string `json:"title"`
		Category         string `json:"category"`
		Content          string `json:"content"`
		FeaturedImageURL string `json:"featured_image_url"`
		Status           string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createcmsarticle.CreateCmsArticleCommand{
		Title:            body.Title,
		Category:         body.Category,
		Content:          body.Content,
		FeaturedImageURL: body.FeaturedImageURL,
		Status:           body.Status,
		AuthorID:         authorID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create cms article")
		writeError(w, http.StatusInternalServerError, "failed to create cms article")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "article created"})
}

// GetArticle godoc
// @Summary      Get CMS article by slug
// @Description  Retrieve a single CMS article by its slug
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        slug  path  string  true  "Article slug"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/articles/{slug} [get]
func (h *CmsHandler) GetArticle(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	result, err := h.qryBus.Execute(r.Context(), &getcmsarticle.GetCmsArticleQuery{Slug: slug})
	if err != nil {
		log.Error().Err(err).Str("slug", slug).Msg("failed to get cms article")
		writeError(w, http.StatusNotFound, "cms article not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdateArticle godoc
// @Summary      Update CMS article
// @Description  Update an existing CMS article by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Article ID"
// @Param        body  body  object  true  "Article update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/articles/{id} [put]
func (h *CmsHandler) UpdateArticle(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var body struct {
		Title            string `json:"title"`
		Slug             string `json:"slug"`
		Category         string `json:"category"`
		Content          string `json:"content"`
		FeaturedImageURL string `json:"featured_image_url"`
		Status           string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecmsarticle.UpdateCmsArticleCommand{
		ID:               id,
		Title:            body.Title,
		Slug:             body.Slug,
		Category:         body.Category,
		Content:          body.Content,
		FeaturedImageURL: body.FeaturedImageURL,
		Status:           body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to update cms article")
		writeError(w, http.StatusInternalServerError, "failed to update cms article")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "article updated"})
}

// DeleteArticle godoc
// @Summary      Delete CMS article
// @Description  Delete a CMS article by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Article ID"
// @Success      200  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/articles/{id} [delete]
func (h *CmsHandler) DeleteArticle(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletecmsarticle.DeleteCmsArticleCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to delete cms article")
		writeError(w, http.StatusInternalServerError, "failed to delete cms article")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "article deleted"})
}

// ─── TESTIMONIALS ─────────────────────────────────────────────────────────────

// ListTestimonials godoc
// @Summary      List CMS testimonials
// @Description  Retrieve CMS testimonials with optional course and featured filters
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        course_id    query  string  false  "Filter by course ID"
// @Param        is_featured  query  bool    false  "Filter by featured status"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/testimonials [get]
func (h *CmsHandler) ListTestimonials(w http.ResponseWriter, r *http.Request) {
	courseID := r.URL.Query().Get("course_id")
	isFeaturedStr := r.URL.Query().Get("is_featured")

	var isFeatured *bool
	if isFeaturedStr != "" {
		b := isFeaturedStr == "true"
		isFeatured = &b
	}

	result, err := h.qryBus.Execute(r.Context(), &listcmstestimonials.ListCmsTestimonialsQuery{
		CourseID:   courseID,
		IsFeatured: isFeatured,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms testimonials")
		writeError(w, http.StatusInternalServerError, "failed to list cms testimonials")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// CreateTestimonial godoc
// @Summary      Create CMS testimonial
// @Description  Create a new CMS testimonial with student name, quote, rating, etc.
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Testimonial creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/testimonials [post]
func (h *CmsHandler) CreateTestimonial(w http.ResponseWriter, r *http.Request) {
	var body struct {
		StudentName string `json:"student_name"`
		CourseID    string `json:"course_id"`
		Quote       string `json:"quote"`
		Rating      int    `json:"rating"`
		PhotoURL    string `json:"photo_url"`
		IsFeatured  bool   `json:"is_featured"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createcmstestimonial.CreateCmsTestimonialCommand{
		StudentName: body.StudentName,
		CourseID:    body.CourseID,
		Quote:       body.Quote,
		Rating:      body.Rating,
		PhotoURL:    body.PhotoURL,
		IsFeatured:  body.IsFeatured,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create cms testimonial")
		writeError(w, http.StatusInternalServerError, "failed to create cms testimonial")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "testimonial created"})
}

// UpdateTestimonial godoc
// @Summary      Update CMS testimonial
// @Description  Update an existing CMS testimonial by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Testimonial ID"
// @Param        body  body  object  true  "Testimonial update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/testimonials/{id} [put]
func (h *CmsHandler) UpdateTestimonial(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var body struct {
		StudentName string `json:"student_name"`
		CourseID    string `json:"course_id"`
		Quote       string `json:"quote"`
		Rating      int    `json:"rating"`
		PhotoURL    string `json:"photo_url"`
		IsFeatured  bool   `json:"is_featured"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecmstestimonial.UpdateCmsTestimonialCommand{
		ID:          id,
		StudentName: body.StudentName,
		CourseID:    body.CourseID,
		Quote:       body.Quote,
		Rating:      body.Rating,
		PhotoURL:    body.PhotoURL,
		IsFeatured:  body.IsFeatured,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to update cms testimonial")
		writeError(w, http.StatusInternalServerError, "failed to update cms testimonial")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "testimonial updated"})
}

// DeleteTestimonial godoc
// @Summary      Delete CMS testimonial
// @Description  Delete a CMS testimonial by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Testimonial ID"
// @Success      200  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/testimonials/{id} [delete]
func (h *CmsHandler) DeleteTestimonial(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletecmstestimonial.DeleteCmsTestimonialCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to delete cms testimonial")
		writeError(w, http.StatusInternalServerError, "failed to delete cms testimonial")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "testimonial deleted"})
}

// ─── FAQ ──────────────────────────────────────────────────────────────────────

// ListFaq godoc
// @Summary      List CMS FAQ entries
// @Description  Retrieve CMS FAQ entries with optional category and page slug filters
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        category    query  string  false  "Filter by category"
// @Param        page_slug   query  string  false  "Filter by page slug"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/faq [get]
func (h *CmsHandler) ListFaq(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	pageSlug := r.URL.Query().Get("page_slug")

	result, err := h.qryBus.Execute(r.Context(), &listcmsfaq.ListCmsFaqQuery{
		Category: category,
		PageSlug: pageSlug,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms faq")
		writeError(w, http.StatusInternalServerError, "failed to list cms faq")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// CreateFaq godoc
// @Summary      Create CMS FAQ entry
// @Description  Create a new CMS FAQ with question, answer, category, page slugs, and sort order
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "FAQ creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/faq [post]
func (h *CmsHandler) CreateFaq(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Question  string   `json:"question"`
		Answer    string   `json:"answer"`
		Category  string   `json:"category"`
		PageSlugs []string `json:"page_slugs"`
		SortOrder int      `json:"sort_order"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createcmsfaq.CreateCmsFaqCommand{
		Question:  body.Question,
		Answer:    body.Answer,
		Category:  body.Category,
		PageSlugs: body.PageSlugs,
		SortOrder: body.SortOrder,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create cms faq")
		writeError(w, http.StatusInternalServerError, "failed to create cms faq")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "faq created"})
}

// UpdateFaq godoc
// @Summary      Update CMS FAQ entry
// @Description  Update an existing CMS FAQ by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "FAQ ID"
// @Param        body  body  object  true  "FAQ update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/faq/{id} [put]
func (h *CmsHandler) UpdateFaq(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var body struct {
		Question  string   `json:"question"`
		Answer    string   `json:"answer"`
		Category  string   `json:"category"`
		PageSlugs []string `json:"page_slugs"`
		SortOrder int      `json:"sort_order"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecmsfaq.UpdateCmsFaqCommand{
		ID:        id,
		Question:  body.Question,
		Answer:    body.Answer,
		Category:  body.Category,
		PageSlugs: body.PageSlugs,
		SortOrder: body.SortOrder,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to update cms faq")
		writeError(w, http.StatusInternalServerError, "failed to update cms faq")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "faq updated"})
}

// DeleteFaq godoc
// @Summary      Delete CMS FAQ entry
// @Description  Delete a CMS FAQ by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "FAQ ID"
// @Success      200  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/faq/{id} [delete]
func (h *CmsHandler) DeleteFaq(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletecmsfaq.DeleteCmsFaqCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to delete cms faq")
		writeError(w, http.StatusInternalServerError, "failed to delete cms faq")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "faq deleted"})
}

// ─── MEDIA ────────────────────────────────────────────────────────────────────

// ListMedia godoc
// @Summary      List CMS media
// @Description  Retrieve paginated list of CMS media entries
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 20)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/media [get]
func (h *CmsHandler) ListMedia(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listcmsmedia.ListCmsMediaQuery{
		Offset: offset,
		Limit:  limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms media")
		writeError(w, http.StatusInternalServerError, "failed to list cms media")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// UploadMedia godoc
// @Summary      Upload CMS media
// @Description  Upload a new media entry to CMS (URL, file name, type, size)
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Media upload payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/media [post]
func (h *CmsHandler) UploadMedia(w http.ResponseWriter, r *http.Request) {
	uploadedBy := pkgmiddleware.GetUserIDFromContext(r.Context())

	var body struct {
		URL      string `json:"url"`
		FileName string `json:"file_name"`
		FileType string `json:"file_type"`
		FileSize int64  `json:"file_size"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &uploadcmsmedia.UploadCmsMediaCommand{
		URL:        body.URL,
		FileName:   body.FileName,
		FileType:   body.FileType,
		FileSize:   body.FileSize,
		UploadedBy: uploadedBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to upload cms media")
		writeError(w, http.StatusInternalServerError, "failed to upload cms media")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "media uploaded"})
}

// DeleteMedia godoc
// @Summary      Delete CMS media
// @Description  Delete a CMS media entry by ID
// @Tags         cms
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Media ID"
// @Success      200  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /cms/media/{id} [delete]
func (h *CmsHandler) DeleteMedia(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletecmsmedia.DeleteCmsMediaCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Str("id", id).Msg("failed to delete cms media")
		writeError(w, http.StatusInternalServerError, "failed to delete cms media")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "media deleted"})
}
