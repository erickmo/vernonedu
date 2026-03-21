package submit_post_url

import "github.com/google/uuid"

type SubmitPostUrlCommand struct {
	ID      uuid.UUID `validate:"required"`
	PostURL string    `validate:"required"`
}
