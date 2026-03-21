package list_courseversion

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// ListCourseVersionQuery adalah query untuk mengambil daftar CourseVersion dari satu CourseType.
type ListCourseVersionQuery struct {
	CourseTypeID uuid.UUID
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

// Handler menangani ListCourseVersionQuery.
type Handler struct {
	readRepo courseversion.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo courseversion.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil daftar CourseVersion.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCourseVersionQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	versions, err := h.readRepo.ListByType(ctx, q.CourseTypeID)
	if err != nil {
		log.Error().Err(err).Str("course_type_id", q.CourseTypeID.String()).Msg("failed to list course versions")
		return nil, err
	}

	readModels := make([]*CourseVersionReadModel, len(versions))
	for i, cv := range versions {
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
		readModels[i] = rm
	}

	return readModels, nil
}
