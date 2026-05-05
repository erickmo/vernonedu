package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type HrmRepository struct {
	db *sqlx.DB
}

func NewHrmRepository(db *sqlx.DB) *HrmRepository {
	return &HrmRepository{db: db}
}

// --- Record structs ---

type employeeRecord struct {
	ID             uuid.UUID  `db:"id"`
	UserID         uuid.UUID  `db:"user_id"`
	EmployeeNumber string     `db:"employee_number"`
	DepartmentID   *uuid.UUID `db:"department_id"`
	Position       string     `db:"position"`
	HireDate       time.Time  `db:"hire_date"`
	Status         string     `db:"status"`
	Phone          string     `db:"phone"`
	Address        string     `db:"address"`
	BaseSalary     float64    `db:"base_salary"`
	BankName       string     `db:"bank_name"`
	BankAccount    string     `db:"bank_account"`
	ContractType   string     `db:"contract_type"`
	ContractEnd    *time.Time `db:"contract_end"`
	Notes          string     `db:"notes"`
	CreatedAt      time.Time  `db:"created_at"`
	UpdatedAt      time.Time  `db:"updated_at"`
}

func (rec *employeeRecord) toDomain() *hrm.Employee {
	return &hrm.Employee{
		ID:             rec.ID,
		UserID:         rec.UserID,
		EmployeeNumber: rec.EmployeeNumber,
		DepartmentID:   rec.DepartmentID,
		Position:       rec.Position,
		HireDate:       rec.HireDate,
		Status:         rec.Status,
		Phone:          rec.Phone,
		Address:        rec.Address,
		BaseSalary:     rec.BaseSalary,
		BankName:       rec.BankName,
		BankAccount:    rec.BankAccount,
		ContractType:   rec.ContractType,
		ContractEnd:    rec.ContractEnd,
		Notes:          rec.Notes,
		CreatedAt:      rec.CreatedAt,
		UpdatedAt:      rec.UpdatedAt,
	}
}

type staffAttendanceRecord struct {
	ID         uuid.UUID  `db:"id"`
	EmployeeID uuid.UUID  `db:"employee_id"`
	Date       time.Time  `db:"date"`
	Status     string     `db:"status"`
	ClockIn    *time.Time `db:"clock_in"`
	ClockOut   *time.Time `db:"clock_out"`
	Note       string     `db:"note"`
	CreatedAt  time.Time  `db:"created_at"`
	UpdatedAt  time.Time  `db:"updated_at"`
}

func (rec *staffAttendanceRecord) toDomain() *hrm.StaffAttendance {
	return &hrm.StaffAttendance{
		ID:         rec.ID,
		EmployeeID: rec.EmployeeID,
		Date:       rec.Date,
		Status:     rec.Status,
		ClockIn:    rec.ClockIn,
		ClockOut:   rec.ClockOut,
		Note:       rec.Note,
		CreatedAt:  rec.CreatedAt,
		UpdatedAt:  rec.UpdatedAt,
	}
}

type leaveRequestRecord struct {
	ID         uuid.UUID  `db:"id"`
	EmployeeID uuid.UUID  `db:"employee_id"`
	LeaveType  string     `db:"leave_type"`
	StartDate  time.Time  `db:"start_date"`
	EndDate    time.Time  `db:"end_date"`
	Reason     string     `db:"reason"`
	Status     string     `db:"status"`
	ReviewedBy *uuid.UUID `db:"reviewed_by"`
	ReviewedAt *time.Time `db:"reviewed_at"`
	CreatedAt  time.Time  `db:"created_at"`
	UpdatedAt  time.Time  `db:"updated_at"`
}

func (rec *leaveRequestRecord) toDomain() *hrm.LeaveRequest {
	return &hrm.LeaveRequest{
		ID:         rec.ID,
		EmployeeID: rec.EmployeeID,
		LeaveType:  rec.LeaveType,
		StartDate:  rec.StartDate,
		EndDate:    rec.EndDate,
		Reason:     rec.Reason,
		Status:     rec.Status,
		ReviewedBy: rec.ReviewedBy,
		ReviewedAt: rec.ReviewedAt,
		CreatedAt:  rec.CreatedAt,
		UpdatedAt:  rec.UpdatedAt,
	}
}

type payrollPeriodRecord struct {
	ID          uuid.UUID  `db:"id"`
	Period      string     `db:"period"`
	StartDate   time.Time  `db:"start_date"`
	EndDate     time.Time  `db:"end_date"`
	Status      string     `db:"status"`
	ApprovedBy  *uuid.UUID `db:"approved_by"`
	ApprovedAt  *time.Time `db:"approved_at"`
	DisbursedAt *time.Time `db:"disbursed_at"`
	Notes       string     `db:"notes"`
	CreatedAt   time.Time  `db:"created_at"`
	UpdatedAt   time.Time  `db:"updated_at"`
}

func (rec *payrollPeriodRecord) toDomain() *hrm.PayrollPeriod {
	return &hrm.PayrollPeriod{
		ID:          rec.ID,
		Period:      rec.Period,
		StartDate:   rec.StartDate,
		EndDate:     rec.EndDate,
		Status:      rec.Status,
		ApprovedBy:  rec.ApprovedBy,
		ApprovedAt:  rec.ApprovedAt,
		DisbursedAt: rec.DisbursedAt,
		Notes:       rec.Notes,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}

type payrollItemRecord struct {
	ID                  uuid.UUID `db:"id"`
	PayrollPeriodID     uuid.UUID `db:"payroll_period_id"`
	EmployeeID          uuid.UUID `db:"employee_id"`
	BaseSalary          float64   `db:"base_salary"`
	FacilitatorSessions int       `db:"facilitator_sessions"`
	FacilitatorFee      float64   `db:"facilitator_fee"`
	AttendanceDeduction float64   `db:"attendance_deduction"`
	Bonus               float64   `db:"bonus"`
	TotalAmount         float64   `db:"total_amount"`
	Status              string    `db:"status"`
	Notes               string    `db:"notes"`
	CreatedAt           time.Time `db:"created_at"`
	UpdatedAt           time.Time `db:"updated_at"`
}

func (rec *payrollItemRecord) toDomain() *hrm.PayrollItem {
	return &hrm.PayrollItem{
		ID:                  rec.ID,
		PayrollPeriodID:     rec.PayrollPeriodID,
		EmployeeID:          rec.EmployeeID,
		BaseSalary:          rec.BaseSalary,
		FacilitatorSessions: rec.FacilitatorSessions,
		FacilitatorFee:      rec.FacilitatorFee,
		AttendanceDeduction: rec.AttendanceDeduction,
		Bonus:               rec.Bonus,
		TotalAmount:         rec.TotalAmount,
		Status:              rec.Status,
		Notes:               rec.Notes,
		CreatedAt:           rec.CreatedAt,
		UpdatedAt:           rec.UpdatedAt,
	}
}

// --- WriteRepository ---

func (r *HrmRepository) SaveEmployee(ctx context.Context, e *hrm.Employee) error {
	query := `
		INSERT INTO employees (id, user_id, employee_number, department_id, position, hire_date, status,
			phone, address, base_salary, bank_name, bank_account, contract_type, contract_end, notes, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`
	_, err := r.db.ExecContext(ctx, query,
		e.ID, e.UserID, e.EmployeeNumber, e.DepartmentID, e.Position, e.HireDate, e.Status,
		e.Phone, e.Address, e.BaseSalary, e.BankName, e.BankAccount, e.ContractType, e.ContractEnd,
		e.Notes, e.CreatedAt, e.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save employee: %w", err)
	}
	return nil
}

func (r *HrmRepository) UpdateEmployee(ctx context.Context, e *hrm.Employee) error {
	query := `
		UPDATE employees SET department_id=$1, position=$2, status=$3, phone=$4, address=$5,
			base_salary=$6, bank_name=$7, bank_account=$8, contract_type=$9, contract_end=$10,
			notes=$11, updated_at=$12
		WHERE id=$13`
	_, err := r.db.ExecContext(ctx, query,
		e.DepartmentID, e.Position, e.Status, e.Phone, e.Address,
		e.BaseSalary, e.BankName, e.BankAccount, e.ContractType, e.ContractEnd,
		e.Notes, e.UpdatedAt, e.ID)
	if err != nil {
		return fmt.Errorf("failed to update employee: %w", err)
	}
	return nil
}

func (r *HrmRepository) SaveAttendance(ctx context.Context, a *hrm.StaffAttendance) error {
	query := `
		INSERT INTO staff_attendance (id, employee_id, date, status, clock_in, clock_out, note, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`
	_, err := r.db.ExecContext(ctx, query,
		a.ID, a.EmployeeID, a.Date, a.Status, a.ClockIn, a.ClockOut, a.Note, a.CreatedAt, a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save attendance: %w", err)
	}
	return nil
}

func (r *HrmRepository) SaveLeaveRequest(ctx context.Context, lr *hrm.LeaveRequest) error {
	query := `
		INSERT INTO leave_requests (id, employee_id, leave_type, start_date, end_date, reason, status, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`
	_, err := r.db.ExecContext(ctx, query,
		lr.ID, lr.EmployeeID, lr.LeaveType, lr.StartDate, lr.EndDate, lr.Reason, lr.Status,
		lr.CreatedAt, lr.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save leave request: %w", err)
	}
	return nil
}

func (r *HrmRepository) UpdateLeaveRequestStatus(ctx context.Context, lr *hrm.LeaveRequest) error {
	query := `
		UPDATE leave_requests SET status=$1, reviewed_by=$2, reviewed_at=$3, updated_at=$4
		WHERE id=$5`
	_, err := r.db.ExecContext(ctx, query, lr.Status, lr.ReviewedBy, lr.ReviewedAt, lr.UpdatedAt, lr.ID)
	if err != nil {
		return fmt.Errorf("failed to update leave request status: %w", err)
	}
	return nil
}

func (r *HrmRepository) SavePayrollPeriod(ctx context.Context, pp *hrm.PayrollPeriod) error {
	query := `
		INSERT INTO payroll_periods (id, period, start_date, end_date, status, notes, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`
	_, err := r.db.ExecContext(ctx, query,
		pp.ID, pp.Period, pp.StartDate, pp.EndDate, pp.Status, pp.Notes, pp.CreatedAt, pp.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save payroll period: %w", err)
	}
	return nil
}

func (r *HrmRepository) UpdatePayrollPeriodStatus(ctx context.Context, pp *hrm.PayrollPeriod) error {
	query := `
		UPDATE payroll_periods SET status=$1, approved_by=$2, approved_at=$3, disbursed_at=$4, notes=$5, updated_at=$6
		WHERE id=$7`
	_, err := r.db.ExecContext(ctx, query,
		pp.Status, pp.ApprovedBy, pp.ApprovedAt, pp.DisbursedAt, pp.Notes, pp.UpdatedAt, pp.ID)
	if err != nil {
		return fmt.Errorf("failed to update payroll period: %w", err)
	}
	return nil
}

func (r *HrmRepository) SavePayrollItem(ctx context.Context, pi *hrm.PayrollItem) error {
	query := `
		INSERT INTO payroll_items (id, payroll_period_id, employee_id, base_salary, facilitator_sessions,
			facilitator_fee, attendance_deduction, bonus, total_amount, status, notes, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`
	_, err := r.db.ExecContext(ctx, query,
		pi.ID, pi.PayrollPeriodID, pi.EmployeeID, pi.BaseSalary, pi.FacilitatorSessions,
		pi.FacilitatorFee, pi.AttendanceDeduction, pi.Bonus, pi.TotalAmount, pi.Status,
		pi.Notes, pi.CreatedAt, pi.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save payroll item: %w", err)
	}
	return nil
}

func (r *HrmRepository) UpdatePayrollItem(ctx context.Context, pi *hrm.PayrollItem) error {
	query := `
		UPDATE payroll_items SET base_salary=$1, facilitator_sessions=$2, facilitator_fee=$3,
			attendance_deduction=$4, bonus=$5, total_amount=$6, status=$7, notes=$8, updated_at=$9
		WHERE id=$10`
	_, err := r.db.ExecContext(ctx, query,
		pi.BaseSalary, pi.FacilitatorSessions, pi.FacilitatorFee,
		pi.AttendanceDeduction, pi.Bonus, pi.TotalAmount, pi.Status,
		pi.Notes, pi.UpdatedAt, pi.ID)
	if err != nil {
		return fmt.Errorf("failed to update payroll item: %w", err)
	}
	return nil
}

// --- ReadRepository ---

func (r *HrmRepository) GetEmployeeByID(ctx context.Context, id uuid.UUID) (*hrm.Employee, error) {
	var rec employeeRecord
	query := `SELECT * FROM employees WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, hrm.ErrEmployeeNotFound
		}
		return nil, fmt.Errorf("failed to get employee: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *HrmRepository) GetEmployeeByUserID(ctx context.Context, userID uuid.UUID) (*hrm.Employee, error) {
	var rec employeeRecord
	query := `SELECT * FROM employees WHERE user_id = $1`
	if err := r.db.GetContext(ctx, &rec, query, userID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, hrm.ErrEmployeeNotFound
		}
		return nil, fmt.Errorf("failed to get employee by user id: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *HrmRepository) ListEmployees(ctx context.Context, offset, limit int, search, departmentID, status, sortBy, sortDir string) ([]*hrm.Employee, int, error) {
	_ = sortBy  // reserved for future dynamic sort support
	_ = sortDir // reserved for future dynamic sort support
	baseWhere := "WHERE 1=1"
	args := []interface{}{}
	argIdx := 1

	if search != "" {
		baseWhere += fmt.Sprintf(" AND (e.employee_number ILIKE $%d OR u.name ILIKE $%d)", argIdx, argIdx)
		args = append(args, "%"+search+"%")
		argIdx++
	}
	if departmentID != "" {
		baseWhere += fmt.Sprintf(" AND e.department_id = $%d", argIdx)
		depID, err := uuid.Parse(departmentID)
		if err != nil {
			return nil, 0, fmt.Errorf("invalid department_id: %w", err)
		}
		args = append(args, depID)
		argIdx++
	}
	if status != "" {
		baseWhere += fmt.Sprintf(" AND e.status = $%d", argIdx)
		args = append(args, status)
		argIdx++
	}

	var total int
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM employees e LEFT JOIN users u ON u.id = e.user_id %s`, baseWhere)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count employees: %w", err)
	}

	listArgs := append(args, limit, offset)
	query := fmt.Sprintf(`
		SELECT e.* FROM employees e
		LEFT JOIN users u ON u.id = e.user_id
		%s ORDER BY e.created_at DESC LIMIT $%d OFFSET $%d`, baseWhere, argIdx, argIdx+1)

	var recs []employeeRecord
	if err := r.db.SelectContext(ctx, &recs, query, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list employees: %w", err)
	}

	result := make([]*hrm.Employee, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, total, nil
}

func (r *HrmRepository) GetAttendanceByRange(ctx context.Context, employeeID uuid.UUID, from, to time.Time, sortBy, sortDir string) ([]*hrm.StaffAttendance, error) {
	_ = sortBy  // reserved for future dynamic sort support
	_ = sortDir // reserved for future dynamic sort support
	query := `SELECT * FROM staff_attendance WHERE employee_id = $1 AND date >= $2 AND date <= $3 ORDER BY date DESC`
	var recs []staffAttendanceRecord
	if err := r.db.SelectContext(ctx, &recs, query, employeeID, from, to); err != nil {
		return nil, fmt.Errorf("failed to get attendance: %w", err)
	}

	result := make([]*hrm.StaffAttendance, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, nil
}

func (r *HrmRepository) GetAttendanceSummary(ctx context.Context, period string) ([]*hrm.AttendanceSummary, error) {
	query := `
		SELECT
			e.id AS employee_id,
			COALESCE(u.name, '') AS employee_name,
			COUNT(CASE WHEN sa.status = 'present' THEN 1 END) AS present_days,
			COUNT(CASE WHEN sa.status = 'absent' THEN 1 END) AS absent_days,
			COUNT(CASE WHEN sa.status = 'late' THEN 1 END) AS late_days,
			COUNT(CASE WHEN sa.status = 'leave' THEN 1 END) AS leave_days,
			COUNT(sa.id) AS total_work_days
		FROM employees e
		LEFT JOIN users u ON u.id = e.user_id
		LEFT JOIN staff_attendance sa ON sa.employee_id = e.id
			AND sa.date >= (SELECT start_date FROM payroll_periods WHERE period = $1)
			AND sa.date <= (SELECT end_date FROM payroll_periods WHERE period = $1)
		WHERE e.status = 'active'
		GROUP BY e.id, u.name
		ORDER BY u.name`

	type summaryRecord struct {
		EmployeeID    uuid.UUID `db:"employee_id"`
		EmployeeName  string    `db:"employee_name"`
		PresentDays   int       `db:"present_days"`
		AbsentDays    int       `db:"absent_days"`
		LateDays      int       `db:"late_days"`
		LeaveDays     int       `db:"leave_days"`
		TotalWorkDays int       `db:"total_work_days"`
	}

	var recs []summaryRecord
	if err := r.db.SelectContext(ctx, &recs, query, period); err != nil {
		return nil, fmt.Errorf("failed to get attendance summary: %w", err)
	}

	result := make([]*hrm.AttendanceSummary, len(recs))
	for i, rec := range recs {
		result[i] = &hrm.AttendanceSummary{
			EmployeeID:    rec.EmployeeID,
			EmployeeName:  rec.EmployeeName,
			PresentDays:   rec.PresentDays,
			AbsentDays:    rec.AbsentDays,
			LateDays:      rec.LateDays,
			LeaveDays:     rec.LeaveDays,
			TotalWorkDays: rec.TotalWorkDays,
		}
	}
	return result, nil
}

func (r *HrmRepository) ListLeaveRequests(ctx context.Context, employeeID *uuid.UUID, status, sortBy, sortDir string, offset, limit int) ([]*hrm.LeaveRequest, int, error) {
	_ = sortBy  // reserved for future dynamic sort support
	_ = sortDir // reserved for future dynamic sort support
	baseWhere := "WHERE 1=1"
	args := []interface{}{}
	argIdx := 1

	if employeeID != nil {
		baseWhere += fmt.Sprintf(" AND employee_id = $%d", argIdx)
		args = append(args, *employeeID)
		argIdx++
	}
	if status != "" {
		baseWhere += fmt.Sprintf(" AND status = $%d", argIdx)
		args = append(args, status)
		argIdx++
	}

	var total int
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM leave_requests %s`, baseWhere)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count leave requests: %w", err)
	}

	listArgs := append(args, limit, offset)
	query := fmt.Sprintf(`SELECT * FROM leave_requests %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
		baseWhere, argIdx, argIdx+1)

	var recs []leaveRequestRecord
	if err := r.db.SelectContext(ctx, &recs, query, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list leave requests: %w", err)
	}

	result := make([]*hrm.LeaveRequest, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, total, nil
}

func (r *HrmRepository) GetLeaveRequestByID(ctx context.Context, id uuid.UUID) (*hrm.LeaveRequest, error) {
	var rec leaveRequestRecord
	query := `SELECT * FROM leave_requests WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, hrm.ErrLeaveRequestNotFound
		}
		return nil, fmt.Errorf("failed to get leave request: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *HrmRepository) GetPayrollPeriodByID(ctx context.Context, id uuid.UUID) (*hrm.PayrollPeriod, error) {
	var rec payrollPeriodRecord
	query := `SELECT * FROM payroll_periods WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, hrm.ErrPayrollPeriodNotFound
		}
		return nil, fmt.Errorf("failed to get payroll period: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *HrmRepository) ListPayrollPeriods(ctx context.Context, status, sortBy, sortDir string, offset, limit int) ([]*hrm.PayrollPeriod, int, error) {
	_ = sortBy  // reserved for future dynamic sort support
	_ = sortDir // reserved for future dynamic sort support
	baseWhere := "WHERE 1=1"
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		baseWhere += fmt.Sprintf(" AND status = $%d", argIdx)
		args = append(args, status)
		argIdx++
	}

	var total int
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM payroll_periods %s`, baseWhere)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count payroll periods: %w", err)
	}

	listArgs := append(args, limit, offset)
	query := fmt.Sprintf(`SELECT * FROM payroll_periods %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
		baseWhere, argIdx, argIdx+1)

	var recs []payrollPeriodRecord
	if err := r.db.SelectContext(ctx, &recs, query, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list payroll periods: %w", err)
	}

	result := make([]*hrm.PayrollPeriod, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, total, nil
}

func (r *HrmRepository) GetPayrollItemsByPeriod(ctx context.Context, payrollPeriodID uuid.UUID) ([]*hrm.PayrollItem, error) {
	query := `SELECT * FROM payroll_items WHERE payroll_period_id = $1 ORDER BY created_at`
	var recs []payrollItemRecord
	if err := r.db.SelectContext(ctx, &recs, query, payrollPeriodID); err != nil {
		return nil, fmt.Errorf("failed to get payroll items: %w", err)
	}

	result := make([]*hrm.PayrollItem, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, nil
}

func (r *HrmRepository) GetPayrollItemByID(ctx context.Context, id uuid.UUID) (*hrm.PayrollItem, error) {
	var rec payrollItemRecord
	query := `SELECT * FROM payroll_items WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, hrm.ErrPayrollItemNotFound
		}
		return nil, fmt.Errorf("failed to get payroll item: %w", err)
	}
	return rec.toDomain(), nil
}
