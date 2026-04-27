package platform

import (
	"bytes"
	"errors"
	"fmt"
	"strings"
	"text/template"
)

// ErrMissingVariable is returned by Render when the template body
// references a variable not present in vars.
var ErrMissingVariable = errors.New("template: missing variable")

// missingKeySignature is the substring text/template uses when
// missingkey=error is set and a referenced key is absent.
const missingKeySignature = "map has no entry for key"

// Render evaluates body as a text/template against vars.
// It returns ErrMissingVariable (errors.Is-compatible) when the
// template references a key not present in vars. Unknown template
// functions (helpers) are surfaced as raw parse errors.
func Render(body string, vars map[string]any) (string, error) {
	t, err := template.New("render").Option("missingkey=error").Parse(body)
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	if err := t.Execute(&buf, vars); err != nil {
		if strings.Contains(err.Error(), missingKeySignature) {
			return "", fmt.Errorf("%s: %w", err.Error(), ErrMissingVariable)
		}
		return "", err
	}
	return buf.String(), nil
}
