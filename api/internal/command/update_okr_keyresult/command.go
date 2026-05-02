package update_okr_keyresult

type UpdateOkrKeyResultCommand struct {
	ID       string `validate:"required"`
	Title    *string
	Progress *int
}
