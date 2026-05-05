package hrm

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidEmployeeNumber = errors.New("invalid employee number")
	ErrInvalidUserID         = errors.New("invalid user id")
	ErrEmployeeNotFound      = errors.New("employee not found")
	ErrAttendanceNotFound    = errors.New("attendance record not found")
	ErrLeaveRequestNotFound  = errors.New("leave request not found")
	ErrPayrollPeriodNotFound = errors.New("payroll period not found")
	ErrPayrollItemNotFound   = errors.New("payroll item not found")
	ErrInvalidPeriod         = errors.New("invalid payroll period")
	ErrInvalidDateRange      = errors.New("invalid date range")
	ErrAlreadyReviewed       = errors.New("leave request already reviewed")
)

// --- Employee ---

type Employee struct {
	ID             uuid.UUID
	UserID         uuid.UUID
	EmployeeNumber string
	DepartmentID   *uuid.UUID
	Position       string
	HireDate       time.Time
	Status         string
	Phone          string
	Address        string
	BaseSalary     float64
	BankName       string
	BankAccount    string
	ContractType   string
	ContractEnd    *time.Time
	Notes          string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

func NewEmployee(userID uuid.UUID, employeeNumber string, position string, hireDate time.Time) (*Employee, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if employeeNumber == "" {
		return nil, ErrInvalidEmployeeNumber
	}
	if position == "" {
		return nil, errors.New("position is required")
	}

	return &Employee{
		ID:             uuid.New(),
		UserID:         userID,
		EmployeeNumber: employeeNumber,
		Position:       position,
		HireDate:       hireDate,
		Status:         "active",
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}, nil
}

func (e *Employee) UpdatePosition(position string) {
	e.Position = position
	e.UpdatedAt = time.Now()
}

func (e *Employee) UpdateStatus(status string) {
	e.Status = status
	e.UpdatedAt = time.Now()
}

// --- StaffAttendance ---

type StaffAttendance struct {
	ID         uuid.UUID
	EmployeeID uuid.UUID
	Date       time.Time
	Status     string
	ClockIn    *time.Time
	ClockOut   *time.Time
	Note       string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

func NewStaffAttendance(employeeID uuid.UUID, date time.Time, status string) *StaffAttendance {
	return &StaffAttendance{
		ID:         uuid.New(),
		EmployeeID: employeeID,
		Date:       date,
		Status:     status,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
}

// --- LeaveRequest ---

type LeaveRequest struct {
	ID         uuid.UUID
	EmployeeID uuid.UUID
	LeaveType  string
	StartDate  time.Time
	EndDate    time.Time
	Reason     string
	Status     string
	ReviewedBy *uuid.UUID
	ReviewedAt *time.Time
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

func NewLeaveRequest(employeeID uuid.UUID, leaveType string, startDate, endDate time.Time, reason string) (*LeaveRequest, error) {
	if endDate.Before(startDate) {
		return nil, ErrInvalidDateRange
	}
	return &LeaveRequest{
		ID:         uuid.New(),
		EmployeeID: employeeID,
		LeaveType:  leaveType,
		StartDate:  startDate,
		EndDate:    endDate,
		Reason:     reason,
		Status:     "pending",
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}, nil
}

// --- PayrollPeriod ---

type PayrollPeriod struct {
	ID          uuid.UUID
	Period      string
	StartDate   time.Time
	EndDate     time.Time
	Status      string
	ApprovedBy  *uuid.UUID
	ApprovedAt  *time.Time
	DisbursedAt *time.Time
	Notes       string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func NewPayrollPeriod(period string, startDate, endDate time.Time) (*PayrollPeriod, error) {
	if period == "" {
		return nil, ErrInvalidPeriod
	}
	if endDate.Before(startDate) {
		return nil, ErrInvalidDateRange
	}
	return &PayrollPeriod{
		ID:        uuid.New(),
		Period:    period,
		StartDate: startDate,
		EndDate:   endDate,
		Status:    "draft",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

// --- PayrollItem ---

type PayrollItem struct {
	ID                  uuid.UUID
	PayrollPeriodID     uuid.UUID
	EmployeeID          uuid.UUID
	BaseSalary          float64
	FacilitatorSessions int
	FacilitatorFee      float64
	AttendanceDeduction float64
	Bonus               float64
	TotalAmount         float64
	Status              string
	Notes               string
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

func NewPayrollItem(payrollPeriodID, employeeID uuid.UUID, baseSalary, facilitatorFee, attendanceDeduction, bonus, totalAmount float64) *PayrollItem {
	return &PayrollItem{
		ID:                  uuid.New(),
		PayrollPeriodID:     payrollPeriodID,
		EmployeeID:          employeeID,
		BaseSalary:          baseSalary,
		FacilitatorFee:      facilitatorFee,
		AttendanceDeduction: attendanceDeduction,
		Bonus:               bonus,
		TotalAmount:         totalAmount,
		Status:              "pending",
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}
}

// --- AttendanceSummary ---

type AttendanceSummary struct {
	EmployeeID   uuid.UUID
	EmployeeName string
	PresentDays  int
	AbsentDays   int
	LateDays     int
	LeaveDays    int
	TotalWorkDays int
}

// --- Repository Interfaces ---

type WriteRepository interface {
	SaveEmployee(ctx context.Context, e *Employee) error
	UpdateEmployee(ctx context.Context, e *Employee) error
	SaveAttendance(ctx context.Context, a *StaffAttendance) error
	SaveLeaveRequest(ctx context.Context, lr *LeaveRequest) error
	UpdateLeaveRequestStatus(ctx context.Context, lr *LeaveRequest) error
	SavePayrollPeriod(ctx context.Context, pp *PayrollPeriod) error
	UpdatePayrollPeriodStatus(ctx context.Context, pp *PayrollPeriod) error
	SavePayrollItem(ctx context.Context, pi *PayrollItem) error
	UpdatePayrollItem(ctx context.Context, pi *PayrollItem) error
}

type ReadRepository interface {
	GetEmployeeByID(ctx context.Context, id uuid.UUID) (*Employee, error)
	GetEmployeeByUserID(ctx context.Context, userID uuid.UUID) (*Employee, error)
	ListEmployees(ctx context.Context, offset, limit int, search, departmentID, status, sortBy, sortDir string) ([]*Employee, int, error)
	GetAttendanceByRange(ctx context.Context, employeeID uuid.UUID, from, to time.Time, sortBy, sortDir string) ([]*StaffAttendance, error)
	GetAttendanceSummary(ctx context.Context, period string) ([]*AttendanceSummary, error)
	ListLeaveRequests(ctx context.Context, employeeID *uuid.UUID, status, sortBy, sortDir string, offset, limit int) ([]*LeaveRequest, int, error)
	GetLeaveRequestByID(ctx context.Context, id uuid.UUID) (*LeaveRequest, error)
	GetPayrollPeriodByID(ctx context.Context, id uuid.UUID) (*PayrollPeriod, error)
	ListPayrollPeriods(ctx context.Context, status, sortBy, sortDir string, offset, limit int) ([]*PayrollPeriod, int, error)
	GetPayrollItemsByPeriod(ctx context.Context, payrollPeriodID uuid.UUID) ([]*PayrollItem, error)
	GetPayrollItemByID(ctx context.Context, id uuid.UUID) (*PayrollItem, error)
}
