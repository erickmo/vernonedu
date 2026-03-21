package courseversion

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan transisi status CourseVersion
var (
	ErrAlreadyApproved   = errors.New("versi sudah berstatus approved")
	ErrInvalidTransition = errors.New("transisi status tidak valid")
	ErrVersionNotFound   = errors.New("versi tidak ditemukan")
	ErrInvalidChangeType = errors.New("tipe perubahan tidak valid: harus major, minor, atau patch")
)

// ValidChangeTypes adalah daftar tipe perubahan versi yang diperbolehkan.
var ValidChangeTypes = []string{"major", "minor", "patch"}

// CourseVersion merepresentasikan satu versi kurikulum dari sebuah CourseType.
// Menggunakan semantic versioning: vMAJOR.MINOR.PATCH
// Alur status: draft → review → approved → archived
type CourseVersion struct {
	ID           uuid.UUID
	CourseTypeID uuid.UUID
	VersionNumber string     // contoh: "2.1.0"
	Status        string     // draft | review | approved | archived
	ChangeType    string     // major | minor | patch
	Changelog     string
	CreatedBy     *uuid.UUID
	ApprovedBy    *uuid.UUID
	CreatedAt     time.Time
	UpdatedAt     time.Time
	ApprovedAt    *time.Time
	ArchivedAt    *time.Time
}

// NewCourseVersion membuat entitas CourseVersion baru.
// Status awal selalu "draft".
func NewCourseVersion(courseTypeID uuid.UUID, versionNumber, changeType, changelog string, createdBy *uuid.UUID) (*CourseVersion, error) {
	validChange := false
	for _, v := range ValidChangeTypes {
		if v == changeType {
			validChange = true
			break
		}
	}
	if !validChange {
		return nil, ErrInvalidChangeType
	}
	return &CourseVersion{
		ID:            uuid.New(),
		CourseTypeID:  courseTypeID,
		VersionNumber: versionNumber,
		Status:        "draft",
		ChangeType:    changeType,
		Changelog:     changelog,
		CreatedBy:     createdBy,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}, nil
}

// PromoteToReview memindahkan status versi dari draft ke review.
// Hanya boleh dilakukan jika status saat ini adalah "draft".
func (cv *CourseVersion) PromoteToReview() error {
	if cv.Status != "draft" {
		return ErrInvalidTransition
	}
	cv.Status = "review"
	cv.UpdatedAt = time.Now()
	return nil
}

// Approve memindahkan status versi dari review ke approved.
// Menyimpan ID approver dan waktu persetujuan.
func (cv *CourseVersion) Approve(approvedBy uuid.UUID) error {
	if cv.Status == "approved" {
		return ErrAlreadyApproved
	}
	if cv.Status != "review" {
		return ErrInvalidTransition
	}
	now := time.Now()
	cv.Status = "approved"
	cv.ApprovedBy = &approvedBy
	cv.ApprovedAt = &now
	cv.UpdatedAt = now
	return nil
}

// Archive memindahkan status versi dari approved ke archived.
// Menyimpan waktu pengarsipan.
func (cv *CourseVersion) Archive() error {
	if cv.Status != "approved" {
		return ErrInvalidTransition
	}
	now := time.Now()
	cv.Status = "archived"
	cv.ArchivedAt = &now
	cv.UpdatedAt = now
	return nil
}

// NextVersion menghitung nomor versi berikutnya berdasarkan changeType.
// Menerima versionNumber saat ini dalam format "MAJOR.MINOR.PATCH".
// Mengembalikan string versi baru, misalnya "2.0.0" untuk major bump.
func (cv *CourseVersion) NextVersion(changeType string) string {
	parts := strings.Split(cv.VersionNumber, ".")
	if len(parts) != 3 {
		return "1.0.0"
	}
	major, errMajor := strconv.Atoi(parts[0])
	minor, errMinor := strconv.Atoi(parts[1])
	patch, errPatch := strconv.Atoi(parts[2])
	if errMajor != nil || errMinor != nil || errPatch != nil {
		return "1.0.0"
	}
	switch changeType {
	case "major":
		major++
		minor = 0
		patch = 0
	case "minor":
		minor++
		patch = 0
	case "patch":
		patch++
	}
	return fmt.Sprintf("%d.%d.%d", major, minor, patch)
}

// WriteRepository mendefinisikan operasi tulis untuk CourseVersion.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, cv *CourseVersion) error
	Update(ctx context.Context, cv *CourseVersion) error
	// ArchiveAllApproved mengarsipkan semua versi approved untuk satu CourseType.
	// Dipanggil saat versi baru di-approve agar hanya ada satu versi aktif.
	ArchiveAllApproved(ctx context.Context, courseTypeID uuid.UUID) error
}

// ReadRepository mendefinisikan operasi baca untuk CourseVersion.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*CourseVersion, error)
	ListByType(ctx context.Context, courseTypeID uuid.UUID) ([]*CourseVersion, error)
	// GetApproved mengembalikan versi yang sedang aktif (status approved) untuk satu CourseType.
	GetApproved(ctx context.Context, courseTypeID uuid.UUID) (*CourseVersion, error)
}
