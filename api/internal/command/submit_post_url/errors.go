package submit_post_url

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid submit post url command")
	ErrPostNotFound   = errors.New("post not found")
)
