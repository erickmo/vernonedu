package get_courseversion

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// GetCourseVersionQuery adalah query untuk mengambil satu CourseVersion berdasarkan ID.
type GetCourseVersionQuery struct {
	VersionID uuid.UUID
}

// CourseVersionReadModel adalah model baca untuk CourseVersion.
type CourseVersionReadModel struct {
	ID            string  `json:"id"`
	CourseTypeID  string  `json:"course_type_id"`
	VersionNumber string  `json:"version_number"`
	Status        string  `json:"status"`
	ChangeType    string  `json:"change_type"`
	Changelog     string  `json:"changelog"`
	CreatedBy     *string `json:"created_by"`
	ApprovedBy    *string `json:"approved_by"`
	CreatedAt     int64   `json:"created_at"`
	UpdatedAt     int64   `json:"updated_at"`
	ApprovedAt    *int64  `json:"approved_at"`
	ArchivedAt    *int64  `json:"archived_at"`
}

// Handler menangani GetCourseVersionQuery.
type Handler struct {
	readRepo courseversion.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo courseversion.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil satu CourseVersion.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCourseVersionQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	cv, err := h.readRepo.GetByID(ctx, q.VersionID)
	if err != nil {
		log.Error().Err(err).Str("version_id", q.VersionID.String()).Msg("failed to get course version")
		return nil, err
	}

	return toReadModel(cv), nil
}

// toReadModel mengonversi domain entity ke read model.
func toReadModel(cv *courseversion.CourseVersion) *CourseVersionReadModel {
	rm := &CourseVersionReadModel{
		ID:            cv.ID.String(),
		CourseTypeID:  cv.CourseTypeID.String(),
		VersionNumber: cv.VersionNumber,
		Status:        cv.Status,
		ChangeType:    cv.ChangeType,
		Changelog:     cv.Changelog,
		CreatedAt:     cv.CreatedAt.Unix(),
		UpdatedAt:     cv.UpdatedAt.Unix(),
	}
	if cv.CreatedBy != nil {
		s := cv.CreatedBy.String()
		rm.CreatedBy = &s
	}
	if cv.ApprovedBy != nil {
		s := cv.ApprovedBy.String()
		rm.ApprovedBy = &s
	}
	if cv.ApprovedAt != nil {
		t := cv.ApprovedAt.Unix()
		rm.ApprovedAt = &t
	}
	if cv.ArchivedAt != nil {
		t := cv.ArchivedAt.Unix()
		rm.ArchivedAt = &t
	}
	return rm
}
