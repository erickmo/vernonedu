package update_post

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update post command")
	ErrPostNotFound   = errors.New("post not found")
)
