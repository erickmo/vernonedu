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
	student, err := s.repo.GetStudentByID(ctx, id)
	if err != nil {
		return nil, err
	}
	student.Name = in.Name
	student.Email = in.Email
	student.Phone = in.Phone
	student.Source = in.Source
	student.PartnerID = in.PartnerID
	if err := s.repo.UpdateStudent(ctx, student); err != nil {
		return nil, err
	}
	return student, nil
}

// GetStudentProfile fetches the profile for a student.
func (s *Service) GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	return s.repo.GetStudentProfile(ctx, studentID)
}

// UpdateStudentProfile updates profile fields and recomputes profile_complete.
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in UpdateStudentProfileInput) (*StudentProfile, error) {
	profile, err := s.repo.GetStudentProfile(ctx, studentID)
	if err != nil {
		return nil, err
	}
	profile.DateOfBirth = in.DateOfBirth
	profile.Gender = in.Gender
	profile.IDType = in.IDType
	profile.IDNumber = in.IDNumber
	profile.Address = in.Address
	profile.City = in.City
	profile.Province = in.Province
	profile.PostalCode = in.PostalCode
	profile.ProfileComplete = isProfileComplete(profile)
	if err := s.repo.UpdateStudentProfile(ctx, profile); err != nil {
		return nil, err
	}
	return profile, nil
}

func isProfileComplete(p *StudentProfile) bool {
	return p.DateOfBirth != nil && p.Gender != nil && p.IDType != nil &&
		p.IDNumber != nil && p.Address != nil && p.City != nil &&
		p.Province != nil && p.PostalCode != nil
}
