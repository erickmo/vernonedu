package add_student_note

type AddStudentNoteCommand struct {
	StudentID  string
	AuthorID   string
	AuthorName string
	Content    string `validate:"required,min=1"`
}

func (c *AddStudentNoteCommand) CommandName() string { return "AddStudentNote" }
