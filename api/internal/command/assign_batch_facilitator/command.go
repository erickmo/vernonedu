package assignbatchfacilitator

// AssignBatchFacilitatorCommand assigns (or unassigns) a facilitator to a course batch.
// Set FacilitatorID to "" to unassign.
type AssignBatchFacilitatorCommand struct {
	BatchID       string `json:"batch_id"       validate:"required"`
	FacilitatorID string `json:"facilitator_id"` // empty = unassign
}

func (c *AssignBatchFacilitatorCommand) CommandName() string {
	return "AssignBatchFacilitator"
}
