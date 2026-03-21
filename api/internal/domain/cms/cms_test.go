package cms_test

import (
	"testing"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

func TestStatusConstants(t *testing.T) {
	tests := []struct{ name, val, want string }{
		{"draft", cms.StatusDraft, "draft"},
		{"published", cms.StatusPublished, "published"},
		{"archived", cms.StatusArchived, "archived"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.val != tt.want {
				t.Errorf("got %q, want %q", tt.val, tt.want)
			}
		})
	}
}

func TestCategoryConstants(t *testing.T) {
	cats := []string{cms.CategoryTipsKarir, cms.CategoryInfoKursus, cms.CategoryBerita, cms.CategoryEvent}
	for _, c := range cats {
		if c == "" {
			t.Errorf("category constant must not be empty")
		}
	}
}

func TestFaqCategoryConstants(t *testing.T) {
	cats := []string{
		cms.FaqCategoryUmum,
		cms.FaqCategoryPendaftaran,
		cms.FaqCategoryPembayaran,
		cms.FaqCategorySertifikat,
		cms.FaqCategoryProgramKarir,
	}
	for _, c := range cats {
		if c == "" {
			t.Errorf("faq category constant must not be empty")
		}
	}
}

func TestCmsPage_BasicFields(t *testing.T) {
	p := &cms.CmsPage{Slug: "home", Title: "Home Page"}
	if p.Slug != "home" || p.Title != "Home Page" {
		t.Error("CmsPage fields not set correctly")
	}
}

func TestCmsArticle_BasicFields(t *testing.T) {
	a := &cms.CmsArticle{Slug: "test-article", Title: "Test", Status: cms.StatusDraft}
	if a.Status != cms.StatusDraft {
		t.Errorf("expected %q, got %q", cms.StatusDraft, a.Status)
	}
}

func TestCmsFaq_BasicFields(t *testing.T) {
	f := &cms.CmsFaq{Question: "?", Answer: "A", PageSlugs: []string{"home"}}
	if len(f.PageSlugs) != 1 || f.PageSlugs[0] != "home" {
		t.Error("CmsFaq PageSlugs not set correctly")
	}
}

func TestCmsTestimonial_BasicFields(t *testing.T) {
	tst := &cms.CmsTestimonial{StudentName: "Alice", Quote: "Great!", Rating: 5}
	if tst.Rating != 5 {
		t.Errorf("expected rating 5, got %d", tst.Rating)
	}
	if tst.StudentName != "Alice" {
		t.Errorf("expected student name Alice, got %s", tst.StudentName)
	}
}

func TestCmsMedia_BasicFields(t *testing.T) {
	m := &cms.CmsMedia{FileName: "photo.jpg", FileType: "image/jpeg", FileSize: 1024}
	if m.FileName != "photo.jpg" {
		t.Errorf("expected FileName photo.jpg, got %s", m.FileName)
	}
	if m.FileSize != 1024 {
		t.Errorf("expected FileSize 1024, got %d", m.FileSize)
	}
}
