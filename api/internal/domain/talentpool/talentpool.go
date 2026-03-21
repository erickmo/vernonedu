package talentpool

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada TalentPool
var (
	ErrInvalidParticipant = errors.New("data peserta tidak boleh kosong")
	ErrAlreadyPlaced      = errors.New("peserta sudah dalam status placed")
	ErrAlreadyInactive    = errors.New("peserta talent pool sudah tidak aktif")
	ErrEntryNotFound      = errors.New("entri talent pool tidak ditemukan")
)

// PlacementRecord menyimpan riwayat referral kerja dari TalentPool ke perusahaan.
type PlacementRecord struct {
	CompanyName string    `json:"company_name"`
	Position    string    `json:"position"`
	PlacedAt    time.Time `json:"placed_at"`
	Notes       string    `json:"notes"`
}

// TalentPool adalah entitas tersendiri yang merepresentasikan peserta dalam talent pool VernonEdu.
// Peserta masuk ke talent pool setelah lulus tes karakter pada program_karir.
// Entitas ini tidak bergantung langsung pada course — berdiri sendiri sebagai talent registry.
type TalentPool struct {
	ID                  uuid.UUID
	ParticipantID       uuid.UUID
	ParticipantName     string
	ParticipantEmail    string
	MasterCourseID      uuid.UUID
	CourseTypeID        uuid.UUID
	CourseVersionID     uuid.UUID
	CharacterTestResult map[string]interface{} // hasil lengkap tes karakter (fleksibel per provider)
	TestScore           *float64               // skor tes karakter
	TalentpoolStatus    string                 // active | placed | inactive
	PlacementHistory    []PlacementRecord      // riwayat penempatan kerja
	JoinedAt            time.Time
	UpdatedAt           time.Time
}

// NewTalentPool membuat entitas TalentPool baru.
// Status awal selalu "active". PlacementHistory diinisialisasi kosong.
func NewTalentPool(participantID uuid.UUID, participantName, participantEmail string, masterCourseID, courseTypeID, courseVersionID uuid.UUID, testResult map[string]interface{}, testScore *float64) (*TalentPool, error) {
	if participantName == "" || participantEmail == "" {
		return nil, ErrInvalidParticipant
	}
	if testResult == nil {
		testResult = map[string]interface{}{}
	}
	return &TalentPool{
		ID:                  uuid.New(),
		ParticipantID:       participantID,
		ParticipantName:     participantName,
		ParticipantEmail:    participantEmail,
		MasterCourseID:      masterCourseID,
		CourseTypeID:        courseTypeID,
		CourseVersionID:     courseVersionID,
		CharacterTestResult: testResult,
		TestScore:           testScore,
		TalentpoolStatus:    "active",
		PlacementHistory:    []PlacementRecord{},
		JoinedAt:            time.Now(),
		UpdatedAt:           time.Now(),
	}, nil
}

// MarkPlaced menambahkan rekaman penempatan kerja dan mengubah status ke "placed".
func (tp *TalentPool) MarkPlaced(record PlacementRecord) {
	tp.PlacementHistory = append(tp.PlacementHistory, record)
	tp.TalentpoolStatus = "placed"
	tp.UpdatedAt = time.Now()
}

// Deactivate menonaktifkan entri talent pool ini.
// Mengembalikan error jika sudah dalam status inactive.
func (tp *TalentPool) Deactivate() error {
	if tp.TalentpoolStatus == "inactive" {
		return ErrAlreadyInactive
	}
	tp.TalentpoolStatus = "inactive"
	tp.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk TalentPool.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, tp *TalentPool) error
	Update(ctx context.Context, tp *TalentPool) error
}

// ReadRepository mendefinisikan operasi baca untuk TalentPool.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*TalentPool, error)
	// List mengembalikan daftar entri talent pool dengan filter opsional berdasarkan status dan master_course_id.
	// Gunakan string kosong ("") untuk status atau uuid.Nil untuk master_course_id jika tidak ingin filter.
	List(ctx context.Context, offset, limit int, status string, masterCourseID uuid.UUID) ([]*TalentPool, int, error)
	GetByParticipantAndVersion(ctx context.Context, participantID, courseVersionID uuid.UUID) (*TalentPool, error)
}
