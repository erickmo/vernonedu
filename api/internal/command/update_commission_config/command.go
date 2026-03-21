package update_commission_config

type UpdateCommissionConfigCommand struct {
	OpLeaderPct        float64 `validate:"min=0,max=100"`
	OpLeaderBasis      string  `validate:"required,oneof=profit revenue"`
	DeptLeaderPct      float64 `validate:"min=0,max=100"`
	DeptLeaderBasis    string  `validate:"required,oneof=profit revenue"`
	CourseCreatorPct   float64 `validate:"min=0,max=100"`
	CourseCreatorBasis string  `validate:"required,oneof=profit revenue"`
}
