package tests

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	createpost       "github.com/vernonedu/entrepreneurship-api/internal/command/create_post"
	createpr         "github.com/vernonedu/entrepreneurship-api/internal/command/create_pr"
	createrefpartner "github.com/vernonedu/entrepreneurship-api/internal/command/create_referral_partner"
	deletepost       "github.com/vernonedu/entrepreneurship-api/internal/command/delete_post"
	deletepr         "github.com/vernonedu/entrepreneurship-api/internal/command/delete_pr"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
	"github.com/vernonedu/entrepreneurship-api/internal/eventhandler"
	listclassdocsqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_class_docs"
	getmarketingstatsqry "github.com/vernonedu/entrepreneurship-api/internal/query/get_marketing_stats"
	listpostsqry     "github.com/vernonedu/entrepreneurship-api/internal/query/list_posts"
	listprqry        "github.com/vernonedu/entrepreneurship-api/internal/query/list_pr"
	listrefpartnersqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_referral_partners"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ────────────────────────────────────────────────────────────────
// Mock: marketing.WriteRepository
// ────────────────────────────────────────────────────────────────

type mockMarketingWriteRepo struct {
	savedPosts        []*marketing.SocialMediaPost
	updatedPosts      []*marketing.SocialMediaPost
	deletedPostIDs    []uuid.UUID
	savedClassDocs    []*marketing.ClassDocPost
	savedPrs          []*marketing.PrSchedule
	updatedPrs        []*marketing.PrSchedule
	deletedPrIDs      []uuid.UUID
	savedRefPartners  []*marketing.ReferralPartner
	updatedRefPartners []*marketing.ReferralPartner
	savedReferrals    []*marketing.Referral
}

func (m *mockMarketingWriteRepo) SavePost(ctx context.Context, p *marketing.SocialMediaPost) error {
	m.savedPosts = append(m.savedPosts, p)
	return nil
}
func (m *mockMarketingWriteRepo) UpdatePost(ctx context.Context, p *marketing.SocialMediaPost) error {
	m.updatedPosts = append(m.updatedPosts, p)
	return nil
}
func (m *mockMarketingWriteRepo) DeletePost(ctx context.Context, id uuid.UUID) error {
	m.deletedPostIDs = append(m.deletedPostIDs, id)
	return nil
}
func (m *mockMarketingWriteRepo) SaveClassDocPost(ctx context.Context, p *marketing.ClassDocPost) error {
	m.savedClassDocs = append(m.savedClassDocs, p)
	return nil
}
func (m *mockMarketingWriteRepo) UpdateClassDocPostStatus(ctx context.Context, id uuid.UUID, status, postURL string) error {
	return nil
}
func (m *mockMarketingWriteRepo) SavePr(ctx context.Context, p *marketing.PrSchedule) error {
	m.savedPrs = append(m.savedPrs, p)
	return nil
}
func (m *mockMarketingWriteRepo) UpdatePr(ctx context.Context, p *marketing.PrSchedule) error {
	m.updatedPrs = append(m.updatedPrs, p)
	return nil
}
func (m *mockMarketingWriteRepo) DeletePr(ctx context.Context, id uuid.UUID) error {
	m.deletedPrIDs = append(m.deletedPrIDs, id)
	return nil
}
func (m *mockMarketingWriteRepo) SaveReferralPartner(ctx context.Context, rp *marketing.ReferralPartner) error {
	m.savedRefPartners = append(m.savedRefPartners, rp)
	return nil
}
func (m *mockMarketingWriteRepo) UpdateReferralPartner(ctx context.Context, rp *marketing.ReferralPartner) error {
	m.updatedRefPartners = append(m.updatedRefPartners, rp)
	return nil
}
func (m *mockMarketingWriteRepo) SaveReferral(ctx context.Context, r *marketing.Referral) error {
	m.savedReferrals = append(m.savedReferrals, r)
	return nil
}

// ────────────────────────────────────────────────────────────────
// Mock: marketing.ReadRepository
// ────────────────────────────────────────────────────────────────

type mockMarketingReadRepo struct {
	posts          []*marketing.SocialMediaPost
	classDocs      []*marketing.ClassDocPost
	prSchedules    []*marketing.PrSchedule
	refPartners    []*marketing.ReferralPartner
	referrals      []*marketing.Referral
	stats          *marketing.MarketingStats
}

func (m *mockMarketingReadRepo) GetPostByID(ctx context.Context, id uuid.UUID) (*marketing.SocialMediaPost, error) {
	for _, p := range m.posts {
		if p.ID == id {
			return p, nil
		}
	}
	return nil, marketing.ErrPostNotFound
}
func (m *mockMarketingReadRepo) ListPosts(ctx context.Context, offset, limit int, platform, status, month string) ([]*marketing.SocialMediaPost, int, error) {
	return m.posts, len(m.posts), nil
}
func (m *mockMarketingReadRepo) ListClassDocs(ctx context.Context, offset, limit int, status string) ([]*marketing.ClassDocPost, int, error) {
	return m.classDocs, len(m.classDocs), nil
}
func (m *mockMarketingReadRepo) GetPrByID(ctx context.Context, id uuid.UUID) (*marketing.PrSchedule, error) {
	for _, p := range m.prSchedules {
		if p.ID == id {
			return p, nil
		}
	}
	return nil, marketing.ErrPrNotFound
}
func (m *mockMarketingReadRepo) ListPr(ctx context.Context, offset, limit int, status, prType string) ([]*marketing.PrSchedule, int, error) {
	return m.prSchedules, len(m.prSchedules), nil
}
func (m *mockMarketingReadRepo) GetReferralPartnerByID(ctx context.Context, id uuid.UUID) (*marketing.ReferralPartner, error) {
	for _, rp := range m.refPartners {
		if rp.ID == id {
			return rp, nil
		}
	}
	return nil, marketing.ErrReferralPartnerNotFound
}
func (m *mockMarketingReadRepo) ListReferralPartners(ctx context.Context, offset, limit int, isActive *bool) ([]*marketing.ReferralPartner, int, error) {
	return m.refPartners, len(m.refPartners), nil
}
func (m *mockMarketingReadRepo) ListReferrals(ctx context.Context, partnerID uuid.UUID) ([]*marketing.Referral, error) {
	return m.referrals, nil
}
func (m *mockMarketingReadRepo) GetStats(ctx context.Context) (*marketing.MarketingStats, error) {
	if m.stats != nil {
		return m.stats, nil
	}
	return &marketing.MarketingStats{}, nil
}

// ────────────────────────────────────────────────────────────────
// Mock: settings.HolidayReadRepository
// ────────────────────────────────────────────────────────────────

type mockHolidayReadRepo struct {
	holidays []*settings.Holiday
}

func (m *mockHolidayReadRepo) ListByYear(ctx context.Context, year int) ([]*settings.Holiday, error) {
	return m.holidays, nil
}

// ────────────────────────────────────────────────────────────────
// Command Tests
// ────────────────────────────────────────────────────────────────

func TestCreatePostHandler_Success(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := createpost.NewHandler(writeRepo, eb)

	cmd := &createpost.CreatePostCommand{
		Platforms:   []string{"instagram", "facebook"},
		ScheduledAt: time.Now().Add(24 * time.Hour).Format(time.RFC3339),
		ContentType: "promo",
		Caption:     "Test caption",
		MediaURL:    "https://example.com/img.jpg",
		CreatedBy:   uuid.New(),
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedPosts) != 1 {
		t.Fatalf("expected 1 saved post, got %d", len(writeRepo.savedPosts))
	}
	post := writeRepo.savedPosts[0]
	if post.Status != "scheduled" {
		t.Errorf("expected status 'scheduled', got '%s'", post.Status)
	}
	if len(post.Platforms) != 2 {
		t.Errorf("expected 2 platforms, got %d", len(post.Platforms))
	}
}

func TestCreatePostHandler_DraftWhenNoDate(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := createpost.NewHandler(writeRepo, eb)

	cmd := &createpost.CreatePostCommand{
		Platforms:   []string{"instagram"},
		ScheduledAt: "", // empty → draft
		ContentType: "info",
		Caption:     "Draft post",
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedPosts) != 1 {
		t.Fatalf("expected 1 saved post, got %d", len(writeRepo.savedPosts))
	}
	post := writeRepo.savedPosts[0]
	if post.Status != "draft" {
		t.Errorf("expected status 'draft', got '%s'", post.Status)
	}
}

func TestCreatePrHandler_Success(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := createpr.NewHandler(writeRepo, eb)

	cmd := &createpr.CreatePrCommand{
		Title:       "Press Release Q1",
		Type:        "press_release",
		ScheduledAt: time.Now().Add(48 * time.Hour).Format(time.RFC3339),
		MediaVenue:  "Kompas",
		PicName:     "John Doe",
		Notes:       "Q1 launch announcement",
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedPrs) != 1 {
		t.Fatalf("expected 1 saved pr, got %d", len(writeRepo.savedPrs))
	}
	pr := writeRepo.savedPrs[0]
	if pr.Status != "scheduled" {
		t.Errorf("expected status 'scheduled', got '%s'", pr.Status)
	}
	if pr.Title != "Press Release Q1" {
		t.Errorf("expected title 'Press Release Q1', got '%s'", pr.Title)
	}
}

func TestCreatePrHandler_InvalidCommand(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := createpr.NewHandler(writeRepo, eb)

	// Pass wrong command type
	cmd := &createpost.CreatePostCommand{
		Platforms:   []string{"instagram"},
		ContentType: "promo",
	}
	err := handler.Handle(context.Background(), cmd)
	if err == nil {
		t.Fatal("expected ErrInvalidCommand, got nil")
	}
}

func TestCreateReferralPartnerHandler_Success(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := createrefpartner.NewHandler(writeRepo, eb)

	cmd := &createrefpartner.CreateReferralPartnerCommand{
		Name:            "Mitra Edutech",
		ContactEmail:    "mitra@example.com",
		ReferralCode:    "MITRA2026",
		CommissionType:  "percentage",
		CommissionValue: 10.0,
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedRefPartners) != 1 {
		t.Fatalf("expected 1 saved referral partner, got %d", len(writeRepo.savedRefPartners))
	}
	rp := writeRepo.savedRefPartners[0]
	if !rp.IsActive {
		t.Error("expected referral partner to be active by default")
	}
	if rp.ReferralCode != "MITRA2026" {
		t.Errorf("expected referral code 'MITRA2026', got '%s'", rp.ReferralCode)
	}
}

func TestDeletePostHandler_Success(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := deletepost.NewHandler(writeRepo, eb)

	id := uuid.New()
	cmd := &deletepost.DeletePostCommand{ID: id}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.deletedPostIDs) != 1 || writeRepo.deletedPostIDs[0] != id {
		t.Errorf("expected post %s to be deleted", id)
	}
}

func TestDeletePrHandler_Success(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	eb := eventbus.NewInMemoryEventBus()
	handler := deletepr.NewHandler(writeRepo, eb)

	id := uuid.New()
	cmd := &deletepr.DeletePrCommand{ID: id}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.deletedPrIDs) != 1 || writeRepo.deletedPrIDs[0] != id {
		t.Errorf("expected pr %s to be deleted", id)
	}
}

// ────────────────────────────────────────────────────────────────
// Query Tests
// ────────────────────────────────────────────────────────────────

func TestListPostsHandler_HappyPath(t *testing.T) {
	now := time.Now()
	readRepo := &mockMarketingReadRepo{
		posts: []*marketing.SocialMediaPost{
			{
				ID:          uuid.New(),
				Platforms:   []string{"instagram"},
				ScheduledAt: now,
				ContentType: "promo",
				Caption:     "Post 1",
				Status:      "scheduled",
			},
		},
	}

	handler := listpostsqry.NewHandler(readRepo)
	q := &listpostsqry.ListPostsQuery{Offset: 0, Limit: 10}

	result, err := handler.Handle(context.Background(), q)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	res, ok := result.(*listpostsqry.ListPostsResult)
	if !ok {
		t.Fatal("expected *ListPostsResult")
	}
	if len(res.Data) != 1 {
		t.Errorf("expected 1 post, got %d", len(res.Data))
	}
	if res.Total != 1 {
		t.Errorf("expected total 1, got %d", res.Total)
	}
}

func TestListClassDocsHandler_HappyPath(t *testing.T) {
	now := time.Now()
	readRepo := &mockMarketingReadRepo{
		classDocs: []*marketing.ClassDocPost{
			{
				ID:                uuid.New(),
				BatchName:         "Batch A",
				ModuleName:        "Module 1",
				ClassDate:         now,
				ScheduledPostDate: now.AddDate(0, 0, 2),
				Status:            "scheduled",
			},
		},
	}

	handler := listclassdocsqry.NewHandler(readRepo)
	q := &listclassdocsqry.ListClassDocsQuery{Offset: 0, Limit: 10}

	result, err := handler.Handle(context.Background(), q)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	res, ok := result.(*listclassdocsqry.ListClassDocsResult)
	if !ok {
		t.Fatal("expected *ListClassDocsResult")
	}
	if len(res.Data) != 1 {
		t.Errorf("expected 1 class doc, got %d", len(res.Data))
	}
}

func TestListPrHandler_HappyPath(t *testing.T) {
	now := time.Now()
	readRepo := &mockMarketingReadRepo{
		prSchedules: []*marketing.PrSchedule{
			{
				ID:          uuid.New(),
				Title:       "Q1 PR",
				Type:        "press_release",
				ScheduledAt: now,
				Status:      "scheduled",
			},
		},
	}

	handler := listprqry.NewHandler(readRepo)
	q := &listprqry.ListPrQuery{Offset: 0, Limit: 10}

	result, err := handler.Handle(context.Background(), q)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	res, ok := result.(*listprqry.ListPrResult)
	if !ok {
		t.Fatal("expected *ListPrResult")
	}
	if len(res.Data) != 1 {
		t.Errorf("expected 1 pr schedule, got %d", len(res.Data))
	}
}

func TestListReferralPartnersHandler_HappyPath(t *testing.T) {
	readRepo := &mockMarketingReadRepo{
		refPartners: []*marketing.ReferralPartner{
			{
				ID:              uuid.New(),
				Name:            "Mitra A",
				ReferralCode:    "MITRA_A",
				CommissionType:  "percentage",
				CommissionValue: 5.0,
				IsActive:        true,
			},
		},
	}

	handler := listrefpartnersqry.NewHandler(readRepo)
	q := &listrefpartnersqry.ListReferralPartnersQuery{Offset: 0, Limit: 10}

	result, err := handler.Handle(context.Background(), q)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	res, ok := result.(*listrefpartnersqry.ListReferralPartnersResult)
	if !ok {
		t.Fatal("expected *ListReferralPartnersResult")
	}
	if len(res.Data) != 1 {
		t.Errorf("expected 1 referral partner, got %d", len(res.Data))
	}
}

func TestGetMarketingStatsHandler_HappyPath(t *testing.T) {
	readRepo := &mockMarketingReadRepo{
		stats: &marketing.MarketingStats{
			TotalLeads:               100,
			LeadsThisMonth:           15,
			LeadsPrevMonth:           12,
			LeadToStudentPct:         30.0,
			ScheduledPosts:           5,
			PostedThisMonth:          8,
			ActiveReferralPartners:   3,
			ReferralRevenueThisMonth: 1500000,
		},
	}

	handler := getmarketingstatsqry.NewHandler(readRepo)
	q := &getmarketingstatsqry.GetMarketingStatsQuery{}

	result, err := handler.Handle(context.Background(), q)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	res, ok := result.(*getmarketingstatsqry.MarketingStatsReadModel)
	if !ok {
		t.Fatal("expected *MarketingStatsReadModel")
	}
	if res.TotalLeads != 100 {
		t.Errorf("expected 100 total leads, got %d", res.TotalLeads)
	}
	if res.ActiveReferralPartners != 3 {
		t.Errorf("expected 3 active referral partners, got %d", res.ActiveReferralPartners)
	}
}

// ────────────────────────────────────────────────────────────────
// Event Handler Tests
// ────────────────────────────────────────────────────────────────

func TestSessionCompletedHandler_AutoSchedule(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}
	holidayRepo := &mockHolidayReadRepo{holidays: nil}
	handler := eventhandler.NewSessionCompletedHandler(writeRepo, holidayRepo)

	classDate := time.Date(2026, 3, 10, 0, 0, 0, 0, time.UTC)
	payload := `{
		"batch_id": "` + uuid.New().String() + `",
		"session_id": "` + uuid.New().String() + `",
		"batch_name": "Batch Go 101",
		"module_name": "Module 1: Intro",
		"class_date": "2026-03-10",
		"timestamp": 1741600000
	}`

	err := handler.OnSessionCompleted(context.Background(), []byte(payload))
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedClassDocs) != 1 {
		t.Fatalf("expected 1 class doc post, got %d", len(writeRepo.savedClassDocs))
	}

	doc := writeRepo.savedClassDocs[0]
	expectedDate := classDate.AddDate(0, 0, 2)
	if !doc.ScheduledPostDate.Equal(expectedDate) {
		t.Errorf("expected scheduled_post_date %s, got %s",
			expectedDate.Format("2006-01-02"),
			doc.ScheduledPostDate.Format("2006-01-02"))
	}
	if doc.Status != "scheduled" {
		t.Errorf("expected status 'scheduled', got '%s'", doc.Status)
	}
}

func TestSessionCompletedHandler_HolidayShift(t *testing.T) {
	writeRepo := &mockMarketingWriteRepo{}

	// 2026-03-10 + 2 days = 2026-03-12 is set as a holiday
	holidayDate := time.Date(2026, 3, 12, 0, 0, 0, 0, time.UTC)
	holidayRepo := &mockHolidayReadRepo{
		holidays: []*settings.Holiday{
			{
				ID:   uuid.New(),
				Date: holidayDate,
				Name: "Hari Libur Nasional",
			},
		},
	}

	handler := eventhandler.NewSessionCompletedHandler(writeRepo, holidayRepo)

	payload := `{
		"batch_id": "` + uuid.New().String() + `",
		"session_id": "` + uuid.New().String() + `",
		"batch_name": "Batch Python",
		"module_name": "Module 2",
		"class_date": "2026-03-10",
		"timestamp": 1741600000
	}`

	err := handler.OnSessionCompleted(context.Background(), []byte(payload))
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if len(writeRepo.savedClassDocs) != 1 {
		t.Fatalf("expected 1 class doc post, got %d", len(writeRepo.savedClassDocs))
	}

	doc := writeRepo.savedClassDocs[0]
	// +2 days is holiday, so should be +3 days = 2026-03-13
	expectedDate := time.Date(2026, 3, 13, 0, 0, 0, 0, time.UTC)
	if !doc.ScheduledPostDate.Equal(expectedDate) {
		t.Errorf("expected scheduled_post_date %s after holiday shift, got %s",
			expectedDate.Format("2006-01-02"),
			doc.ScheduledPostDate.Format("2006-01-02"))
	}
}
