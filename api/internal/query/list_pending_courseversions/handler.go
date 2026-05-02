package list_pending_courseversions

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// ListPendingCourseVersionsQuery mengambil semua course version yang menunggu approval.
type ListPendingCourseVersionsQuery struct {
	DepartmentID *uuid.UUID
}

// PendingCourseVersionReadModel adalah view ringan untuk dept leader inbox.
type PendingCourseVersionReadModel struct {
	ID             string  `json:"id"`
	CourseTypeID   string  `json:"course_type_id"`
	VersionNumber  string  `json:"version_number"`
	ChangeType     string  `json:"change_type"`
	Changelog      string  `json:"changelog"`
	ApprovalStatus string  `json:"approval_status"`
	SubmittedBy    *string `json:"submitted_by"`
	SubmittedAt    *int64  `json:"submitted_at"`
	CreatedAt      int64   `json:"created_at"`
}

// Handler menangani ListPendingCourseVersionsQuery.
type Handler struct {
	readRepo courseversion.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo courseversion.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPendingCourseVersionsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	versions, err := h.readRepo.ListPending(ctx, q.DepartmentID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list pending course versions")
		return nil, err
	}

	return toReadModels(versions), nil
}

// toReadModels mengonversi domain entities ke read models JSON-friendly.
func toReadModels(versions []*courseversion.CourseVersion) []*PendingCourseVersionReadModel {
	out := make([]*PendingCourseVersionReadModel, len(versions))
	for i, cv := range versions {
		out[i] = toReadModel(cv)
	}
	return out
}

// toReadModel mengubah satu entity menjadi read model.
func toReadModel(cv *courseversion.CourseVersion) *PendingCourseVersionReadModel {
	rm := &PendingCourseVersionReadModel{
		ID:             cv.ID.String(),
		CourseTypeID:   cv.CourseTypeID.String(),
		VersionNumber:  cv.VersionNumber,
		ChangeType:     cv.ChangeType,
		Changelog:      cv.Changelog,
		ApprovalStatus: cv.ApprovalStatus,
		CreatedAt:      cv.CreatedAt.Unix(),
	}
	if cv.SubmittedBy != nil {
		s := cv.SubmittedBy.String()
		rm.SubmittedBy = &s
	}
	if cv.SubmittedAt != nil {
		t := cv.SubmittedAt.Unix()
		rm.SubmittedAt = &t
	}
	return rm
}
