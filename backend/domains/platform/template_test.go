package platform_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/vernonedu/vernonedu2/backend/domains/platform"
)

func TestRender_Success(t *testing.T) {
	out, err := platform.Render(
		"Hi {{.name}}, your code is {{.code}}",
		map[string]any{"name": "Alice", "code": "X1"},
	)
	require.NoError(t, err)
	require.Equal(t, "Hi Alice, your code is X1", out)
}

func TestRender_MissingVariable_ReturnsErrMissingVariable(t *testing.T) {
	_, err := platform.Render(
		"Hi {{.name}}, your code is {{.code}}",
		map[string]any{"name": "Alice"},
	)
	require.Error(t, err)
	require.True(t, errors.Is(err, platform.ErrMissingVariable),
		"expected ErrMissingVariable, got %v", err)
}

func TestRender_UnknownHelper_ReturnsError(t *testing.T) {
	_, err := platform.Render(
		"Hello {{unknownFunc .name}}",
		map[string]any{"name": "Alice"},
	)
	require.Error(t, err)
	require.True(t,
		strings.Contains(err.Error(), "function") ||
			strings.Contains(err.Error(), "not defined"),
		"expected unknown function parse error, got %v", err)
}

func TestRender_EmptyVars_OK_NoPlaceholders(t *testing.T) {
	out, err := platform.Render("hello world", map[string]any{})
	require.NoError(t, err)
	require.Equal(t, "hello world", out)
}
