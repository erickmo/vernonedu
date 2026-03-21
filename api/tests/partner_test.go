package tests

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	createmoucmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_mou"
	createpartnercmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner"
	createpartnergroupcmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner_group"
	deletepartnercmd "github.com/vernonedu/entrepreneurship-api/internal/command/delete_partner"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
	getpartnerqry "github.com/vernonedu/entrepreneurship-api/internal/query/get_partner"
	listexpiringmousqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_expiring_mous"
	listpartnersqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_partners"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ────────────────────────────────────────────────────────────────
// Mock repositories
// ────────────────────────────────────────────────────────────────

type mockWriteRepo struct {
	savedPartners      []*partner.Partner
	updatedPartners    []*partner.Partner
	deletedPartnerIDs  []uuid.UUID
	savedGroups        []*partner.PartnerGroup
	updatedGroups      []*partner.PartnerGroup
	deletedGroupIDs    []uuid.UUID
	savedMOUs          []*partner.MOU
	updatedMOUs        []*partner.MOU
	deletedMOUIDs      []uuid.UUID
	savedLogs          []*partner.PartnershipLog
}

func (m *mockWriteRepo) Save(ctx context.Context, p *partner.Partner) error {
	m.savedPartners = append(m.savedPartners, p)
	return nil
}
func (m *mockWriteRepo) Update(ctx context.Context, p *partner.Partner) error {
	m.updatedPartners = append(m.updatedPartners, p)
	return nil
}
func (m *mockWriteRepo) Delete(ctx context.Context, id uuid.UUID) error {
	m.deletedPartnerIDs = append(m.deletedPartnerIDs, id)
	return nil
}
func (m *mockWriteRepo) SaveGroup(ctx context.Context, g *partner.PartnerGroup) error {
	m.savedGroups = append(m.savedGroups, g)
	return nil
}
func (m *mockWriteRepo) UpdateGroup(ctx context.Context, g *partner.PartnerGroup) error {
	m.updatedGroups = append(m.updatedGroups, g)
	return nil
}
func (m *mockWriteRepo) DeleteGroup(ctx context.Context, id uuid.UUID) error {
	m.deletedGroupIDs = append(m.deletedGroupIDs, id)
	return nil
}
func (m *mockWriteRepo) SaveMOU(ctx context.Context, mou *partner.MOU) error {
	m.savedMOUs = append(m.savedMOUs, mou)
	return nil
}
func (m *mockWriteRepo) UpdateMOU(ctx context.Context, mou *partner.MOU) error {
	m.updatedMOUs = append(m.updatedMOUs, mou)
	return nil
}
func (m *mockWriteRepo) DeleteMOU(ctx context.Context, id uuid.UUID) error {
	m.deletedMOUIDs = append(m.deletedMOUIDs, id)
	return nil
}
func (m *mockWriteRepo) SaveLog(ctx context.Context, l *partner.PartnershipLog) error {
	m.savedLogs = append(m.savedLogs, l)
	return nil
}

type mockReadRepo struct {
	partners      []*partner.Partner
	groups        []*partner.PartnerGroup
	mous          []*partner.MOU
	mouByID       map[uuid.UUID]*partner.MOU
	logs          []*partner.PartnershipLog
	stats         *partner.PartnerStats
	expiringMOUs  []*partner.MOU
}

func newMockReadRepo() *mockReadRepo {
	return &mockReadRepo{
		mouByID: make(map[uuid.UUID]*partner.MOU),
		stats:   &partner.PartnerStats{},
	}
}

func (m *mockReadRepo) GetByID(ctx context.Context, id uuid.UUID) (*partner.Partner, error) {
	for _, p := range m.partners {
		if p.ID == id {
			return p, nil
		}
	}
	return nil, partner.ErrPartnerNotFound
}
func (m *mockReadRepo) List(ctx context.Context, offset, limit int, status string) ([]*partner.Partner, int, error) {
	return m.partners, len(m.partners), nil
}
func (m *mockReadRepo) ListGroups(ctx context.Context) ([]*partner.PartnerGroup, error) {
	return m.groups, nil
}
func (m *mockReadRepo) ListMOUs(ctx context.Context, partnerID uuid.UUID) ([]*partner.MOU, error) {
	var result []*partner.MOU
	for _, mou := range m.mous {
		if mou.PartnerID == partnerID {
			result = append(result, mou)
		}
	}
	return result, nil
}
func (m *mockReadRepo) GetMOUByID(ctx context.Context, id uuid.UUID) (*partner.MOU, error) {
	if mou, ok := m.mouByID[id]; ok {
		return mou, nil
	}
	return nil, partner.ErrPartnerNotFound
}
func (m *mockReadRepo) ListExpiringMOUs(ctx context.Context, withinMonths int) ([]*partner.MOU, error) {
	return m.expiringMOUs, nil
}
func (m *mockReadRepo) ListLogs(ctx context.Context, partnerID uuid.UUID) ([]*partner.PartnershipLog, error) {
	var result []*partner.PartnershipLog
	for _, l := range m.logs {
		if l.PartnerID == partnerID {
			result = append(result, l)
		}
	}
	return result, nil
}
func (m *mockReadRepo) Stats(ctx context.Context) (*partner.PartnerStats, error) {
	return m.stats, nil
}

// ────────────────────────────────────────────────────────────────
// Tests: CreatePartner command handler
// ────────────────────────────────────────────────────────────────

func TestCreatePartnerHandler_HappyPath(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createpartnercmd.NewHandler(writeRepo, bus)

	cmd := &createpartnercmd.CreatePartnerCommand{
		Name:          "PT Mitra Sejahtera",
		Industry:      "Technology",
		Status:        "active",
		ContactEmail:  "contact@mitra.co.id",
		ContactPhone:  "021-12345678",
		ContactPerson: "Budi Santoso",
		Website:       "https://mitra.co.id",
		Address:       "Jl. Sudirman No. 10, Jakarta",
		Notes:         "Potential long-term partner",
	}

	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if len(writeRepo.savedPartners) != 1 {
		t.Fatalf("expected 1 saved partner, got %d", len(writeRepo.savedPartners))
	}
	saved := writeRepo.savedPartners[0]
	if saved.Name != "PT Mitra Sejahtera" {
		t.Errorf("expected name PT Mitra Sejahtera, got %s", saved.Name)
	}
	if saved.Status != "active" {
		t.Errorf("expected status active, got %s", saved.Status)
	}
	if saved.ID == uuid.Nil {
		t.Error("expected non-nil partner ID")
	}
}

func TestCreatePartnerHandler_DefaultStatus(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createpartnercmd.NewHandler(writeRepo, bus)

	cmd := &createpartnercmd.CreatePartnerCommand{
		Name: "PT Tanpa Status",
	}
	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if writeRepo.savedPartners[0].Status != "prospect" {
		t.Errorf("expected default status 'prospect', got %s", writeRepo.savedPartners[0].Status)
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: CreatePartnerGroup command handler
// ────────────────────────────────────────────────────────────────

func TestCreatePartnerGroupHandler_HappyPath(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createpartnergroupcmd.NewHandler(writeRepo, bus)

	cmd := &createpartnergroupcmd.CreatePartnerGroupCommand{
		Name:        "Technology Partners",
		Description: "Partners from the technology sector",
	}

	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if len(writeRepo.savedGroups) != 1 {
		t.Fatalf("expected 1 saved group, got %d", len(writeRepo.savedGroups))
	}
	if writeRepo.savedGroups[0].Name != "Technology Partners" {
		t.Errorf("unexpected group name: %s", writeRepo.savedGroups[0].Name)
	}
}

func TestCreatePartnerGroupHandler_InvalidCommand(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createpartnergroupcmd.NewHandler(writeRepo, bus)

	// Pass wrong command type
	err := handler.Handle(context.Background(), &createpartnercmd.CreatePartnerCommand{Name: "x"})
	if err == nil {
		t.Fatal("expected error for wrong command type, got nil")
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: CreateMOU command handler
// ────────────────────────────────────────────────────────────────

func TestCreateMOUHandler_HappyPath(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createmoucmd.NewHandler(writeRepo, bus)

	partnerID := uuid.New()
	cmd := &createmoucmd.CreateMOUCommand{
		PartnerIDStr:   partnerID.String(),
		DocumentNumber: "MOU/2026/001",
		Title:          "Kerjasama Pelatihan Teknologi",
		StartDate:      "2026-01-01",
		EndDate:        "2027-01-01",
		Status:         "active",
		DocumentURL:    "https://storage.vernonedu.com/mou/001.pdf",
		Notes:          "MOU untuk program magang",
	}

	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if len(writeRepo.savedMOUs) != 1 {
		t.Fatalf("expected 1 saved MOU, got %d", len(writeRepo.savedMOUs))
	}
	saved := writeRepo.savedMOUs[0]
	if saved.Title != "Kerjasama Pelatihan Teknologi" {
		t.Errorf("unexpected title: %s", saved.Title)
	}
	if saved.Status != "active" {
		t.Errorf("expected status active, got %s", saved.Status)
	}
	if saved.DocumentURL != "https://storage.vernonedu.com/mou/001.pdf" {
		t.Errorf("unexpected document_url: %s", saved.DocumentURL)
	}
	if saved.PartnerID != partnerID {
		t.Errorf("unexpected partner ID: %s", saved.PartnerID)
	}
}

func TestCreateMOUHandler_DefaultStatus(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createmoucmd.NewHandler(writeRepo, bus)

	cmd := &createmoucmd.CreateMOUCommand{
		PartnerIDStr:   uuid.New().String(),
		DocumentNumber: "MOU/2026/002",
		StartDate:      "2026-01-01",
		EndDate:        "2027-01-01",
	}
	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if writeRepo.savedMOUs[0].Status != "active" {
		t.Errorf("expected default status 'active', got %s", writeRepo.savedMOUs[0].Status)
	}
}

func TestCreateMOUHandler_InvalidPartnerID(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := createmoucmd.NewHandler(writeRepo, bus)

	cmd := &createmoucmd.CreateMOUCommand{
		PartnerIDStr:   "not-a-uuid",
		DocumentNumber: "MOU/2026/003",
		StartDate:      "2026-01-01",
		EndDate:        "2027-01-01",
	}
	if err := handler.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for invalid partner ID, got nil")
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: DeletePartner command handler
// ────────────────────────────────────────────────────────────────

func TestDeletePartnerHandler_HappyPath(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := deletepartnercmd.NewHandler(writeRepo, bus)

	partnerID := uuid.New()
	cmd := &deletepartnercmd.DeletePartnerCommand{ID: partnerID.String()}

	if err := handler.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if len(writeRepo.deletedPartnerIDs) != 1 {
		t.Fatalf("expected 1 deleted partner ID, got %d", len(writeRepo.deletedPartnerIDs))
	}
	if writeRepo.deletedPartnerIDs[0] != partnerID {
		t.Errorf("deleted wrong partner ID: got %s, want %s", writeRepo.deletedPartnerIDs[0], partnerID)
	}
}

func TestDeletePartnerHandler_InvalidID(t *testing.T) {
	writeRepo := &mockWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := deletepartnercmd.NewHandler(writeRepo, bus)

	cmd := &deletepartnercmd.DeletePartnerCommand{ID: "invalid"}
	if err := handler.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for invalid ID, got nil")
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: ListPartners query handler
// ────────────────────────────────────────────────────────────────

func TestListPartnersHandler_HappyPath(t *testing.T) {
	now := time.Now()
	readRepo := newMockReadRepo()
	readRepo.partners = []*partner.Partner{
		{
			ID:        uuid.New(),
			Name:      "PT Alpha",
			Industry:  "Education",
			Status:    "active",
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:        uuid.New(),
			Name:      "PT Beta",
			Industry:  "Technology",
			Status:    "negotiating",
			CreatedAt: now,
			UpdatedAt: now,
		},
	}
	readRepo.stats = &partner.PartnerStats{
		ActiveCount: 1, NegotiatingCount: 1,
	}

	handler := listpartnersqry.NewHandler(readRepo)
	result, err := handler.Handle(context.Background(), &listpartnersqry.ListPartnersQuery{Offset: 0, Limit: 20})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	listResult, ok := result.(*listpartnersqry.ListResult)
	if !ok {
		t.Fatal("expected *ListResult")
	}
	if len(listResult.Data) != 2 {
		t.Errorf("expected 2 partners, got %d", len(listResult.Data))
	}
	if listResult.Total != 2 {
		t.Errorf("expected total 2, got %d", listResult.Total)
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: GetPartner query handler
// ────────────────────────────────────────────────────────────────

func TestGetPartnerHandler_HappyPath(t *testing.T) {
	now := time.Now()
	readRepo := newMockReadRepo()

	partnerID := uuid.New()
	mouID := uuid.New()
	readRepo.partners = []*partner.Partner{
		{
			ID:       partnerID,
			Name:     "PT Gamma",
			Industry: "Manufacturing",
			Status:   "active",
			Notes:    "Important partner",
			CreatedAt: now,
			UpdatedAt: now,
		},
	}
	readRepo.mous = []*partner.MOU{
		{
			ID:             mouID,
			PartnerID:      partnerID,
			DocumentNumber: "MOU/2026/010",
			Title:          "MOU Produksi",
			StartDate:      "2026-01-01",
			EndDate:        "2027-01-01",
			Status:         "active",
			DocumentURL:    "https://docs.example.com/mou.pdf",
			Notes:          "",
			CreatedAt:      now,
			UpdatedAt:      now,
		},
	}
	readRepo.logs = []*partner.PartnershipLog{
		{
			ID:         uuid.New(),
			PartnerID:  partnerID,
			LogDate:    "2026-03-01",
			EntityName: "MOU/2026/010",
			EntityType: "mou",
			Status:     "active",
			Notes:      "Initial signing",
			CreatedAt:  now,
			UpdatedAt:  now,
		},
	}

	handler := getpartnerqry.NewHandler(readRepo)
	result, err := handler.Handle(context.Background(), &getpartnerqry.GetPartnerQuery{ID: partnerID.String()})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	detail, ok := result.(*getpartnerqry.PartnerDetailModel)
	if !ok {
		t.Fatal("expected *PartnerDetailModel")
	}
	if detail.Name != "PT Gamma" {
		t.Errorf("unexpected name: %s", detail.Name)
	}
	if len(detail.MOUs) != 1 {
		t.Errorf("expected 1 MOU, got %d", len(detail.MOUs))
	}
	if detail.MOUs[0].Title != "MOU Produksi" {
		t.Errorf("unexpected MOU title: %s", detail.MOUs[0].Title)
	}
	if detail.MOUs[0].Status != "active" {
		t.Errorf("unexpected MOU status: %s", detail.MOUs[0].Status)
	}
	if detail.MOUs[0].DocumentURL != "https://docs.example.com/mou.pdf" {
		t.Errorf("unexpected document_url: %s", detail.MOUs[0].DocumentURL)
	}
	if len(detail.Logs) != 1 {
		t.Errorf("expected 1 log, got %d", len(detail.Logs))
	}
}

func TestGetPartnerHandler_InvalidID(t *testing.T) {
	readRepo := newMockReadRepo()
	handler := getpartnerqry.NewHandler(readRepo)
	_, err := handler.Handle(context.Background(), &getpartnerqry.GetPartnerQuery{ID: "bad-id"})
	if err == nil {
		t.Fatal("expected error for invalid ID, got nil")
	}
}

// ────────────────────────────────────────────────────────────────
// Tests: ListExpiringMOUs query handler
// ────────────────────────────────────────────────────────────────

func TestListExpiringMOUsHandler_HappyPath(t *testing.T) {
	readRepo := newMockReadRepo()
	partnerID := uuid.New()
	readRepo.expiringMOUs = []*partner.MOU{
		{
			ID:             uuid.New(),
			PartnerID:      partnerID,
			PartnerName:    "PT Delta",
			DocumentNumber: "MOU/2025/005",
			Title:          "MOU Jatuh Tempo",
			EndDate:        "2026-04-15",
			Status:         "active",
		},
	}

	handler := listexpiringmousqry.NewHandler(readRepo)
	result, err := handler.Handle(context.Background(), &listexpiringmousqry.ListExpiringMOUsQuery{WithinMonths: 3})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	models, ok := result.([]listexpiringmousqry.ExpiringMOUReadModel)
	if !ok {
		t.Fatal("expected []ExpiringMOUReadModel")
	}
	if len(models) != 1 {
		t.Fatalf("expected 1 expiring MOU, got %d", len(models))
	}
	if models[0].PartnerName != "PT Delta" {
		t.Errorf("unexpected partner_name: %s", models[0].PartnerName)
	}
	if models[0].Title != "MOU Jatuh Tempo" {
		t.Errorf("unexpected title: %s", models[0].Title)
	}
}

func TestListExpiringMOUsHandler_DefaultWithinMonths(t *testing.T) {
	readRepo := newMockReadRepo()
	readRepo.expiringMOUs = []*partner.MOU{}

	handler := listexpiringmousqry.NewHandler(readRepo)
	// WithinMonths = 0 should default to 3 inside the handler
	result, err := handler.Handle(context.Background(), &listexpiringmousqry.ListExpiringMOUsQuery{WithinMonths: 0})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	models, ok := result.([]listexpiringmousqry.ExpiringMOUReadModel)
	if !ok {
		t.Fatal("expected []ExpiringMOUReadModel")
	}
	if len(models) != 0 {
		t.Errorf("expected 0 results, got %d", len(models))
	}
}
