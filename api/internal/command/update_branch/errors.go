package update_branch

import "errors"

var (
	ErrInvalidCommand  = errors.New("invalid update branch command")
	ErrBranchNotFound  = errors.New("branch not found")
)
