package platform_test

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

const templatesTable = "platform.notification_templates"

func newSvc(t *testing.T) (*platform.Service, platform.Repository) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, templatesTable)
	repo := platform.NewRepository(pool)
	svc := platform.NewService(repo, nil, zap.NewNop())
	return svc, repo
}

func subjectPtr(s string) *string { return &s }

func TestCreateTemplate_Success(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	tmpl, err := svc.CreateTemplate(ctx, "welcome", platform.ChannelEmail, subjectPtr("Welcome"), "Hello {{name}}")
	require.NoError(t, err)
	require.NotNil(t, tmpl)
	assert.NotEqual(t, "00000000-0000-0000-0000-000000000000", tmpl.ID.String())
	assert.Equal(t, "welcome", tmpl.Key)
	assert.Equal(t, platform.ChannelEmail, tmpl.Channel)
	require.NotNil(t, tmpl.Subject)
	assert.Equal(t, "Welcome", *tmpl.Subject)
	assert.Equal(t, "Hello {{name}}", tmpl.Body)
	assert.True(t, tmpl.IsActive)
}

func TestCreateTemplate_DuplicateKeyChannel(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	_, err := svc.CreateTemplate(ctx, "dup", platform.ChannelEmail, nil, "body")
	require.NoError(t, err)

	_, err = svc.CreateTemplate(ctx, "dup", platform.ChannelEmail, nil, "body2")
	require.Error(t, err)
	assert.True(t, errors.Is(err, apperrors.ErrConflict), "expected ErrConflict, got %v", err)
}

func TestCreateTemplate_DifferentChannelsSameKey_OK(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	_, err := svc.CreateTemplate(ctx, "shared", platform.ChannelEmail, nil, "email body")
	require.NoError(t, err)

	_, err = svc.CreateTemplate(ctx, "shared", platform.ChannelInApp, nil, "in_app body")
	require.NoError(t, err)
}

func TestDeactivateTemplate_SetsFlagFalse(t *testing.T) {
	svc, repo := newSvc(t)
	ctx := context.Background()

	tmpl, err := svc.CreateTemplate(ctx, "deact", platform.ChannelEmail, nil, "body")
	require.NoError(t, err)

	require.NoError(t, svc.DeactivateTemplate(ctx, tmpl.ID))

	got, err := repo.GetTemplateByID(ctx, tmpl.ID)
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.False(t, got.IsActive)
	assert.Equal(t, tmpl.ID, got.ID)
}

func TestGetActiveTemplate_ReturnsNilWhenInactive(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	tmpl, err := svc.CreateTemplate(ctx, "silent", platform.ChannelEmail, nil, "body")
	require.NoError(t, err)
	require.NoError(t, svc.DeactivateTemplate(ctx, tmpl.ID))

	got, err := svc.GetActiveTemplate(ctx, "silent", platform.ChannelEmail)
	require.NoError(t, err)
	assert.Nil(t, got)
}

func TestGetActiveTemplate_ReturnsNilWhenMissing(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	got, err := svc.GetActiveTemplate(ctx, "nope", platform.ChannelEmail)
	require.NoError(t, err)
	assert.Nil(t, got)
}

func TestGetActiveTemplate_ReturnsTemplate(t *testing.T) {
	svc, _ := newSvc(t)
	ctx := context.Background()

	created, err := svc.CreateTemplate(ctx, "active", platform.ChannelEmail, subjectPtr("S"), "body")
	require.NoError(t, err)

	got, err := svc.GetActiveTemplate(ctx, "active", platform.ChannelEmail)
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.Equal(t, created.ID, got.ID)
	assert.True(t, got.IsActive)
}
