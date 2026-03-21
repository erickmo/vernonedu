package upsert_facilitator_levels

// FacilitatorLevelInput represents one level entry in the upsert request.
type FacilitatorLevelInput struct {
	Level         int    `validate:"required,min=1"`
	Name          string `validate:"required"`
	FeePerSession int64  `validate:"min=0"`
}

// UpsertFacilitatorLevelsCommand replaces the full set of facilitator levels.
type UpsertFacilitatorLevelsCommand struct {
	Levels []FacilitatorLevelInput `validate:"required,min=1"`
}
