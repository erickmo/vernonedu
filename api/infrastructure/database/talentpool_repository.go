package database

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
)

// TalentPoolRepository mengimplementasikan talentpool.WriteRepository dan talentpool.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type TalentPoolRepository struct {
	db *sqlx.DB
}

// NewTalentPoolRepository membuat instance baru TalentPoolRepository.
func NewTalentPoolRepository(db *sqlx.DB) *TalentPoolRepository {
	return &TalentPoolRepository{db: db}
}

// talentPoolRecord adalah representasi row dari tabel talentpool.
type talentPoolRecord struct {
	ID                  uuid.UUID `db:"id"`
	ParticipantID       uuid.UUID `db:"participant_id"`
	ParticipantName     string    `db:"participant_name"`
	ParticipantEmail    string    `db:"participant_email"`
	MasterCourseID      uuid.UUID `db:"master_course_id"`
	CourseTypeID        uuid.UUID `db:"course_type_id"`
	CourseVersionID     uuid.UUID `db:"course_version_id"`
	CharacterTestResult []byte    `db:"character_test_result"` // JSONB → map[string]interface{}
	TestScore           *float64  `db:"test_score"`
	TalentpoolStatus    string    `db:"talentpool_status"`
	PlacementHistory    []byte    `db:"placement_history"` // JSONB → []PlacementRecord
	JoinedAt            time.Time `db:"joined_at"`
	UpdatedAt           time.Time `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity TalentPool.
func (rec *talentPoolRecord) toDomain() (*talentpool.TalentPool, error) {
	// Unmarshal character_test_result dari JSONB
	var testResult map[string]interface{}
	if len(rec.CharacterTestResult) > 0 {
		if err := json.Unmarshal(rec.CharacterTestResult, &testResult); err != nil {
			return nil, fmt.Errorf("failed to unmarshal character_test_result: %w", err)
		}
	}
	if testResult == nil {
		testResult = map[string]interface{}{}
	}

	// Unmarshal placement_history dari JSONB
	var placementHistory []talentpool.PlacementRecord
	if len(rec.PlacementHistory) > 0 {
		if err := json.Unmarshal(rec.PlacementHistory, &placementHistory); err != nil {
			return nil, fmt.Errorf("failed to unmarshal placement_history: %w", err)
		}
	}
	if placementHistory == nil {
		placementHistory = []talentpool.PlacementRecord{}
	}

	return &talentpool.TalentPool{
		ID:                  rec.ID,
		ParticipantID:       rec.ParticipantID,
		ParticipantName:     rec.ParticipantName,
		ParticipantEmail:    rec.ParticipantEmail,
		MasterCourseID:      rec.MasterCourseID,
		CourseTypeID:        rec.CourseTypeID,
		CourseVersionID:     rec.CourseVersionID,
		CharacterTestResult: testResult,
		TestScore:           rec.TestScore,
		TalentpoolStatus:    rec.TalentpoolStatus,
		PlacementHistory:    placementHistory,
		JoinedAt:            rec.JoinedAt,
		UpdatedAt:           rec.UpdatedAt,
	}, nil
}

// Save menyimpan entitas TalentPool baru ke database.
func (r *TalentPoolRepository) Save(ctx context.Context, tp *talentpool.TalentPool) error {
	testResultJSON, err := json.Marshal(tp.CharacterTestResult)
	if err != nil {
		return fmt.Errorf("failed to marshal character_test_result: %w", err)
	}
	placementJSON, err := json.Marshal(tp.PlacementHistory)
	if err != nil {
		return fmt.Errorf("failed to marshal placement_history: %w", err)
	}

	query := `
		INSERT INTO talentpool (id, participant_id, participant_name, participant_email,
		                        master_course_id, course_type_id, course_version_id,
		                        character_test_result, test_score, talentpool_status,
		                        placement_history, joined_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
	`
	_, err = r.db.ExecContext(ctx, query,
		tp.ID, tp.ParticipantID, tp.ParticipantName, tp.ParticipantEmail,
		tp.MasterCourseID, tp.CourseTypeID, tp.CourseVersionID,
		testResultJSON, tp.TestScore, tp.TalentpoolStatus,
		placementJSON, tp.JoinedAt, tp.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save talent pool entry: %w", err)
	}
	return nil
}

// Update memperbarui data TalentPool yang sudah ada di database.
func (r *TalentPoolRepository) Update(ctx context.Context, tp *talentpool.TalentPool) error {
	placementJSON, err := json.Marshal(tp.PlacementHistory)
	if err != nil {
		return fmt.Errorf("failed to marshal placement_history: %w", err)
	}

	query := `
		UPDATE talentpool
		SET talentpool_status = $1, placement_history = $2, updated_at = $3
		WHERE id = $4
	`
	_, err = r.db.ExecContext(ctx, query,
		tp.TalentpoolStatus, placementJSON, tp.UpdatedAt, tp.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update talent pool entry: %w", err)
	}
	return nil
}

// GetByID mengambil satu TalentPool berdasarkan ID.
func (r *TalentPoolRepository) GetByID(ctx context.Context, id uuid.UUID) (*talentpool.TalentPool, error) {
	var rec talentPoolRecord
	query := `
		SELECT id, participant_id, participant_name, participant_email,
		       master_course_id, course_type_id, course_version_id,
		       character_test_result, test_score, talentpool_status,
		       placement_history, joined_at, updated_at
		FROM talentpool WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get talent pool entry by id: %w", err)
	}
	return rec.toDomain()
}

// List mengambil daftar TalentPool dengan pagination dan filter opsional berdasarkan status dan master_course_id.
// Gunakan string kosong ("") untuk status dan uuid.Nil untuk masterCourseID jika tidak ingin filter.
func (r *TalentPoolRepository) List(ctx context.Context, offset, limit int, status string, masterCourseID uuid.UUID) ([]*talentpool.TalentPool, int, error) {
	// Bangun kondisi WHERE secara dinamis
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("talentpool_status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if masterCourseID != uuid.Nil {
		conditions = append(conditions, fmt.Sprintf("master_course_id = $%d", argIdx))
		args = append(args, masterCourseID)
		argIdx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Hitung total
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM talentpool %s", whereClause)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count talent pool entries: %w", err)
	}

	// Ambil data dengan pagination
	listArgs := append(args, limit, offset)
	selectQuery := fmt.Sprintf(
		`SELECT id, participant_id, participant_name, participant_email,
		        master_course_id, course_type_id, course_version_id,
		        character_test_result, test_score, talentpool_status,
		        placement_history, joined_at, updated_at
		 FROM talentpool %s ORDER BY joined_at DESC LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1,
	)
	var recs []talentPoolRecord
	if err := r.db.SelectContext(ctx, &recs, selectQuery, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list talent pool entries: %w", err)
	}

	entries := make([]*talentpool.TalentPool, 0, len(recs))
	for _, rec := range recs {
		tp, err := rec.toDomain()
		if err != nil {
			return nil, 0, err
		}
		entries = append(entries, tp)
	}
	return entries, total, nil
}

// GetByParticipantAndVersion mengambil TalentPool berdasarkan participant_id dan course_version_id.
func (r *TalentPoolRepository) GetByParticipantAndVersion(ctx context.Context, participantID, courseVersionID uuid.UUID) (*talentpool.TalentPool, error) {
	var rec talentPoolRecord
	query := `
		SELECT id, participant_id, participant_name, participant_email,
		       master_course_id, course_type_id, course_version_id,
		       character_test_result, test_score, talentpool_status,
		       placement_history, joined_at, updated_at
		FROM talentpool WHERE participant_id = $1 AND course_version_id = $2
	`
	if err := r.db.GetContext(ctx, &rec, query, participantID, courseVersionID); err != nil {
		return nil, fmt.Errorf("failed to get talent pool entry by participant and version: %w", err)
	}
	return rec.toDomain()
}
