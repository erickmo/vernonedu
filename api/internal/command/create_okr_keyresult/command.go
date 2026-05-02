package create_okr_keyresult

type CreateOkrKeyResultCommand struct {
	ObjectiveID string `validate:"required"`
	Title       string `validate:"required"`
	Progress    int
}
