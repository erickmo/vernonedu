package create_cms_article_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_article"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

// mockArticleWriteRepo is a test double for cms.ArticleWriteRepository.
type mockArticleWriteRepo struct {
	saved *cms.CmsArticle
	err   error
}

func (m *mockArticleWriteRepo) SaveArticle(_ context.Context, a *cms.CmsArticle) error {
	m.saved = a
	return m.err
}

func (m *mockArticleWriteRepo) UpdateArticle(_ context.Context, a *cms.CmsArticle) error {
	return nil
}

func (m *mockArticleWriteRepo) DeleteArticle(_ context.Context, id uuid.UUID) error {
	return nil
}

func TestCreateCmsArticle_Success(t *testing.T) {
	mock := &mockArticleWriteRepo{}
	h := create_cms_article.NewHandler(mock)
	cmd := &create_cms_article.CreateCmsArticleCommand{
		Title:    "Test Article",
		Category: cms.CategoryBerita,
		AuthorID: uuid.New().String(),
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved == nil {
		t.Fatal("article was not saved")
	}
	if mock.saved.Slug == "" {
		t.Error("slug should be auto-generated")
	}
	if mock.saved.Status != cms.StatusDraft {
		t.Errorf("expected draft status, got %s", mock.saved.Status)
	}
}

func TestCreateCmsArticle_InvalidAuthorID(t *testing.T) {
	mock := &mockArticleWriteRepo{}
	h := create_cms_article.NewHandler(mock)
	cmd := &create_cms_article.CreateCmsArticleCommand{
		Title:    "Test",
		Category: cms.CategoryBerita,
		AuthorID: "not-a-uuid",
	}
	err := h.Handle(context.Background(), cmd)
	if err == nil {
		t.Fatal("expected error for invalid author_id")
	}
}

func TestCreateCmsArticle_SaveError(t *testing.T) {
	mock := &mockArticleWriteRepo{err: errors.New("db error")}
	h := create_cms_article.NewHandler(mock)
	cmd := &create_cms_article.CreateCmsArticleCommand{
		Title:    "Test",
		Category: cms.CategoryBerita,
		AuthorID: uuid.New().String(),
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error from save")
	}
}

func TestCreateCmsArticle_WrongCommand(t *testing.T) {
	mock := &mockArticleWriteRepo{}
	h := create_cms_article.NewHandler(mock)
	if err := h.Handle(context.Background(), nil); err == nil {
		t.Fatal("expected error for wrong command type")
	}
}

func TestCreateCmsArticle_PublishedStatus(t *testing.T) {
	mock := &mockArticleWriteRepo{}
	h := create_cms_article.NewHandler(mock)
	cmd := &create_cms_article.CreateCmsArticleCommand{
		Title:    "Published Article",
		Category: cms.CategoryBerita,
		AuthorID: uuid.New().String(),
		Status:   cms.StatusPublished,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved.Status != cms.StatusPublished {
		t.Errorf("expected published status, got %s", mock.saved.Status)
	}
	if mock.saved.PublishedAt == nil {
		t.Error("published_at should be set for published articles")
	}
}

func TestSlugify(t *testing.T) {
	mock := &mockArticleWriteRepo{}
	h := create_cms_article.NewHandler(mock)
	cmd := &create_cms_article.CreateCmsArticleCommand{
		Title:    "Hello World! Test Article",
		Category: cms.CategoryBerita,
		AuthorID: uuid.New().String(),
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if mock.saved.Slug != "hello-world-test-article" {
		t.Errorf("unexpected slug: %q", mock.saved.Slug)
	}
}
