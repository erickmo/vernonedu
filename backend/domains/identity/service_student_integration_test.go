//go:build integration

package identity_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
)

func TestListStudentsFiltered_FilterBySource(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "b2c@test.local", Password: "pass", Name: "B2C Student", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "b2b@test.local", Password: "pass", Name: "B2B Student", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2B,
	})
	require.NoError(t, err)

	src := identity.SourceB2C
	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Source: &src, Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, identity.SourceB2C, results[0].Source)
}

func TestListStudentsFiltered_SearchByName(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "charlie@test.local", Password: "pass", Name: "Charlie Brown", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "dave@test.local", Password: "pass", Name: "Dave Smith", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Search: "charlie", Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Contains(t, results[0].Name, "Charlie")
}

func TestListStudentsFiltered_SearchByEmail(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "unique.email@test.local", Password: "pass", Name: "Email Test", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "other@test.local", Password: "pass", Name: "Other Student", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Search: "unique.email", Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, "unique.email@test.local", results[0].Email)
}

func TestListStudentsFiltered_FilterByProfileComplete(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "pc@test.local", Password: "pass", Name: "Profile Complete", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	dob := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
	gender := "male"
	idType := "ktp"
	idNumber := "1234"
	addr := "Jl. Test 1"
	city := "Jakarta"
	province := "DKI Jakarta"
	postal := "12345"
	_, err = svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		DateOfBirth: &dob, Gender: &gender, IDType: &idType, IDNumber: &idNumber,
		Address: &addr, City: &city, Province: &province, PostalCode: &postal,
	})
	require.NoError(t, err)

	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "incomplete@test.local", Password: "pass", Name: "Incomplete", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	complete := true
	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{ProfileComplete: &complete, Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, student.ID, results[0].ID)
}

func TestListStudentsFiltered_SortByNameAsc(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	for _, name := range []string{"Zara", "Alice", "Mike"} {
		_, err := svc.Register(ctx, identity.RegisterInput{
			Email: name + "@test.local", Password: "pass", Name: name, Phone: "0811",
			Role: identity.RoleStudent, Source: identity.SourceB2C,
		})
		require.NoError(t, err)
	}

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{
		SortBy: "name", SortDir: "asc", Limit: 20,
	})
	require.NoError(t, err)
	require.Len(t, results, 3)
	require.Equal(t, "Alice", results[0].Name)
	require.Equal(t, "Mike", results[1].Name)
	require.Equal(t, "Zara", results[2].Name)
}

func TestCountStudentsFiltered(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	for i := 0; i < 3; i++ {
		_, err := svc.Register(ctx, identity.RegisterInput{
			Email: fmt.Sprintf("count%d@test.local", i), Password: "pass",
			Name: fmt.Sprintf("Count %d", i), Phone: "0811",
			Role: identity.RoleStudent, Source: identity.SourceB2C,
		})
		require.NoError(t, err)
	}

	total, err := svc.CountStudentsFiltered(ctx, identity.StudentFilter{})
	require.NoError(t, err)
	require.Equal(t, 3, total)
}

func TestUpdateStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "update@test.local", Password: "pass", Name: "Original Name", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	updated, err := svc.UpdateStudent(ctx, student.ID, identity.UpdateStudentInput{
		Name: "Updated Name", Email: "updated@test.local", Phone: "0999",
		Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	require.Equal(t, "Updated Name", updated.Name)
	require.Equal(t, "updated@test.local", updated.Email)
}

func TestGetStudentProfile(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "getprofile@test.local", Password: "pass", Name: "Get Profile", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	profile, err := svc.GetStudentProfile(ctx, student.ID)
	require.NoError(t, err)
	require.NotNil(t, profile)
	require.Equal(t, student.ID, profile.StudentID)
	require.False(t, profile.ProfileComplete)
}

func TestUpdateStudentProfile_SetsProfileComplete(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "fullprofile@test.local", Password: "pass", Name: "Full Profile", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	dob := time.Date(1995, 6, 15, 0, 0, 0, 0, time.UTC)
	gender := "female"
	idType := "ktp"
	idNumber := "3201"
	addr := "Jl. Merdeka 10"
	city := "Bandung"
	province := "Jawa Barat"
	postal := "40111"

	profile, err := svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		DateOfBirth: &dob, Gender: &gender, IDType: &idType, IDNumber: &idNumber,
		Address: &addr, City: &city, Province: &province, PostalCode: &postal,
	})
	require.NoError(t, err)
	require.True(t, profile.ProfileComplete)
	require.Equal(t, &dob, profile.DateOfBirth)
	require.Equal(t, &gender, profile.Gender)
}

func TestUpdateStudentProfile_IncompleteDoesNotSetFlag(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "partial@test.local", Password: "pass", Name: "Partial", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	city := "Surabaya"
	profile, err := svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		City: &city,
	})
	require.NoError(t, err)
	require.False(t, profile.ProfileComplete)
}

func TestGetStudentByID(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "byid@test.local", Password: "pass", Name: "By ID", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	fetched, err := svc.GetStudentByID(ctx, student.ID)
	require.NoError(t, err)
	require.Equal(t, student.ID, fetched.ID)
	require.Equal(t, student.Name, fetched.Name)
}

func TestGetStudentByID_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.GetStudentByID(ctx, uuid.New())
	require.Error(t, err)
}
