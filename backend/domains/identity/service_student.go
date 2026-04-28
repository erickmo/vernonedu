package identity

import (
	"context"

	"github.com/google/uuid"
)

// GetStudentByID fetches student by primary key.
func (s *Service) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByID(ctx, id)
}

// GetStudentByUserID fetches student linked to a user.
func (s *Service) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByUserID(ctx, userID)
}

// ListStudentsFiltered paginates and filters the student list.
func (s *Service) ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error) {
	if f.Limit <= 0 || f.Limit > 100 {
		f.Limit = 20
	}
	return s.repo.ListStudentsFiltered(ctx, f)
}

// CountStudentsFiltered returns total matching students.
func (s *Service) CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error) {
	return s.repo.CountStudentsFiltered(ctx, f)
}

// UpdateStudent updates student core fields.
func (s *Service) UpdateStudent(ctx context.Context, id uuid.UUID, in UpdateStudentInput) (*Student, error) {
	return nil, nil // stub — implemented in Task 4
}

// GetStudentProfile fetches the profile for a student.
func (s *Service) GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	return s.repo.GetStudentProfile(ctx, studentID)
}

// UpdateStudentProfile updates profile fields and recomputes profile_complete.
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in UpdateStudentProfileInput) (*StudentProfile, error) {
	return nil, nil // stub — implemented in Task 4
}
