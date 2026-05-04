package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createattendance "github.com/vernonedu/entrepreneurship-api/internal/command/create_attendance"
	createemployee "github.com/vernonedu/entrepreneurship-api/internal/command/create_employee"
	createleave "github.com/vernonedu/entrepreneurship-api/internal/command/create_leave_request"
	createpayrollitem "github.com/vernonedu/entrepreneurship-api/internal/command/create_payroll_item"
	createpayrollperiod "github.com/vernonedu/entrepreneurship-api/internal/command/create_payroll_period"
	reviewleave "github.com/vernonedu/entrepreneurship-api/internal/command/review_leave_request"
	updateemployee "github.com/vernonedu/entrepreneurship-api/internal/command/update_employee"
	updatepayrollitem "github.com/vernonedu/entrepreneurship-api/internal/command/update_payroll_item"
	updatepayrollperiod "github.com/vernonedu/entrepreneurship-api/internal/command/update_payroll_period"
	getattendancesummary "github.com/vernonedu/entrepreneurship-api/internal/query/get_attendance_summary"
	getemployee "github.com/vernonedu/entrepreneurship-api/internal/query/get_employee"
	getpayrollperiod "github.com/vernonedu/entrepreneurship-api/internal/query/get_payroll_period"
	listattendance "github.com/vernonedu/entrepreneurship-api/internal/query/list_attendance"
	listemployees "github.com/vernonedu/entrepreneurship-api/internal/query/list_employees"
	listleaverequests "github.com/vernonedu/entrepreneurship-api/internal/query/list_leave_requests"
	listpayrollitems "github.com/vernonedu/entrepreneurship-api/internal/query/list_payroll_items"
	listpayrollperiods "github.com/vernonedu/entrepreneurship-api/internal/query/list_payroll_periods"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type HrmHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewHrmHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *HrmHandler {
	return &HrmHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// --- Request structs ---

type CreateEmployeeRequest struct {
	UserID         string  `json:"user_id" validate:"required"`
	EmployeeNumber string  `json:"employee_number" validate:"required"`
	DepartmentID   *string `json:"department_id"`
	Position       string  `json:"position" validate:"required"`
	HireDate       string  `json:"hire_date" validate:"required"`
	Phone          string  `json:"phone"`
	Address        string  `json:"address"`
	BaseSalary     float64 `json:"base_salary"`
	BankName       string  `json:"bank_name"`
	BankAccount    string  `json:"bank_account"`
	ContractType   string  `json:"contract_type"`
	ContractEnd    *string `json:"contract_end"`
	Notes          string  `json:"notes"`
}

type UpdateEmployeeRequest struct {
	DepartmentID *string `json:"department_id"`
	Position     string  `json:"position" validate:"required"`
	Status       string  `json:"status" validate:"required"`
	Phone        string  `json:"phone"`
	Address      string  `json:"address"`
	BaseSalary   float64 `json:"base_salary"`
	BankName     string  `json:"bank_name"`
	BankAccount  string  `json:"bank_account"`
	ContractType string  `json:"contract_type"`
	ContractEnd  *string `json:"contract_end"`
	Notes        string  `json:"notes"`
}

type CreateAttendanceRequest struct {
	EmployeeID string  `json:"employee_id" validate:"required"`
	Date       string  `json:"date" validate:"required"`
	Status     string  `json:"status" validate:"required"`
	ClockIn    *string `json:"clock_in"`
	ClockOut   *string `json:"clock_out"`
	Note       string  `json:"note"`
}

type CreateLeaveRequestRequest struct {
	EmployeeID string `json:"employee_id" validate:"required"`
	LeaveType  string `json:"leave_type" validate:"required"`
	StartDate  string `json:"start_date" validate:"required"`
	EndDate    string `json:"end_date" validate:"required"`
	Reason     string `json:"reason" validate:"required"`
}

type ReviewLeaveRequestRequest struct {
	Status     string `json:"status" validate:"required"`
	ReviewedBy string `json:"reviewed_by" validate:"required"`
}

type CreatePayrollPeriodRequest struct {
	Period    string `json:"period" validate:"required"`
	StartDate string `json:"start_date" validate:"required"`
	EndDate   string `json:"end_date" validate:"required"`
	Notes     string `json:"notes"`
}

type UpdatePayrollPeriodRequest struct {
	Status     string `json:"status" validate:"required"`
	ApprovedBy string `json:"approved_by"`
	Notes      string `json:"notes"`
}

type CreatePayrollItemRequest struct {
	EmployeeID          string  `json:"employee_id" validate:"required"`
	BaseSalary          float64 `json:"base_salary"`
	FacilitatorSessions int     `json:"facilitator_sessions"`
	FacilitatorFee      float64 `json:"facilitator_fee"`
	AttendanceDeduction float64 `json:"attendance_deduction"`
	Bonus               float64 `json:"bonus"`
	TotalAmount         float64 `json:"total_amount"`
	Notes               string  `json:"notes"`
}

type UpdatePayrollItemRequest struct {
	BaseSalary          float64 `json:"base_salary"`
	FacilitatorSessions int     `json:"facilitator_sessions"`
	FacilitatorFee      float64 `json:"facilitator_fee"`
	AttendanceDeduction float64 `json:"attendance_deduction"`
	Bonus               float64 `json:"bonus"`
	TotalAmount         float64 `json:"total_amount"`
	Status              string  `json:"status"`
	Notes               string  `json:"notes"`
}

// --- Employee handlers ---

// CreateEmployee godoc
// @Summary      Create a new employee
// @Description  Register a user as an employee with HR details
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        body  body  CreateEmployeeRequest  true  "Employee creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/employees [post]
func (h *HrmHandler) CreateEmployee(w http.ResponseWriter, r *http.Request) {
	var req CreateEmployeeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createemployee.CreateEmployeeCommand{
		UserID: req.UserID, EmployeeNumber: req.EmployeeNumber,
		DepartmentID: req.DepartmentID, Position: req.Position,
		HireDate: req.HireDate, Phone: req.Phone, Address: req.Address,
		BaseSalary: req.BaseSalary, BankName: req.BankName, BankAccount: req.BankAccount,
		ContractType: req.ContractType, ContractEnd: req.ContractEnd, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create employee")
		writeError(w, http.StatusInternalServerError, "failed to create employee")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "employee created successfully"})
}

// ListEmployees godoc
// @Summary      List employees
// @Description  Retrieve a paginated list of employees with optional filters
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        offset         query  int     false  "Pagination offset"
// @Param        limit          query  int     false  "Pagination limit (default 10)"
// @Param        search         query  string  false  "Search by employee number or name"
// @Param        department_id  query  string  false  "Filter by department ID"
// @Param        status         query  string  false  "Filter by status"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/employees [get]
func (h *HrmHandler) ListEmployees(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &listemployees.ListEmployeesQuery{
		Offset: offset, Limit: limit,
		Search: r.URL.Query().Get("search"), DepartmentID: r.URL.Query().Get("department_id"),
		Status: r.URL.Query().Get("status"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list employees")
		writeError(w, http.StatusInternalServerError, "failed to list employees")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// GetEmployee godoc
// @Summary      Get employee by ID
// @Description  Retrieve a single employee by UUID
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Employee ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/employees/{id} [get]
func (h *HrmHandler) GetEmployee(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid employee id")
		return
	}

	query := &getemployee.GetEmployeeQuery{EmployeeID: id}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get employee")
		writeError(w, http.StatusInternalServerError, "failed to get employee")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdateEmployee godoc
// @Summary      Update employee
// @Description  Update employee HR details
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id    path  string                   true  "Employee ID (UUID)"
// @Param        body  body  UpdateEmployeeRequest    true  "Employee update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/employees/{id} [put]
func (h *HrmHandler) UpdateEmployee(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid employee id")
		return
	}

	var req UpdateEmployeeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updateemployee.UpdateEmployeeCommand{
		ID: id.String(), DepartmentID: req.DepartmentID, Position: req.Position,
		Status: req.Status, Phone: req.Phone, Address: req.Address,
		BaseSalary: req.BaseSalary, BankName: req.BankName, BankAccount: req.BankAccount,
		ContractType: req.ContractType, ContractEnd: req.ContractEnd, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update employee")
		writeError(w, http.StatusInternalServerError, "failed to update employee")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "employee updated successfully"})
}

// --- Attendance handlers ---

// CreateAttendance godoc
// @Summary      Create attendance record
// @Description  Record staff attendance for a given date
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        body  body  CreateAttendanceRequest  true  "Attendance payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/attendance [post]
func (h *HrmHandler) CreateAttendance(w http.ResponseWriter, r *http.Request) {
	var req CreateAttendanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createattendance.CreateAttendanceCommand{
		EmployeeID: req.EmployeeID, Date: req.Date, Status: req.Status,
		ClockIn: req.ClockIn, ClockOut: req.ClockOut, Note: req.Note,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create attendance")
		writeError(w, http.StatusInternalServerError, "failed to create attendance")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "attendance created successfully"})
}

// ListAttendance godoc
// @Summary      List attendance records
// @Description  Retrieve attendance records with optional filters
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        employee_id  query  string  false  "Filter by employee ID"
// @Param        from         query  string  false  "From date (YYYY-MM-DD)"
// @Param        to           query  string  false  "To date (YYYY-MM-DD)"
// @Param        status       query  string  false  "Filter by status"
// @Param        offset       query  int     false  "Pagination offset"
// @Param        limit        query  int     false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/attendance [get]
func (h *HrmHandler) ListAttendance(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &listattendance.ListAttendanceQuery{
		EmployeeID: r.URL.Query().Get("employee_id"),
		From: r.URL.Query().Get("from"), To: r.URL.Query().Get("to"),
		Status: r.URL.Query().Get("status"), Offset: offset, Limit: limit,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list attendance")
		writeError(w, http.StatusInternalServerError, "failed to list attendance")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// GetAttendanceSummary godoc
// @Summary      Get attendance summary
// @Description  Get aggregated attendance stats for a payroll period
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        period  query  string  true  "Payroll period (e.g. 2026-01)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/attendance/summary [get]
func (h *HrmHandler) GetAttendanceSummary(w http.ResponseWriter, r *http.Request) {
	period := r.URL.Query().Get("period")
	if period == "" {
		writeError(w, http.StatusBadRequest, "period query parameter is required")
		return
	}

	query := &getattendancesummary.AttendanceSummaryQuery{Period: period}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get attendance summary")
		writeError(w, http.StatusInternalServerError, "failed to get attendance summary")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// --- Leave Request handlers ---

// CreateLeaveRequest godoc
// @Summary      Create leave request
// @Description  Submit a new leave request for an employee
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        body  body  CreateLeaveRequestRequest  true  "Leave request payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/leave-requests [post]
func (h *HrmHandler) CreateLeaveRequest(w http.ResponseWriter, r *http.Request) {
	var req CreateLeaveRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createleave.CreateLeaveRequestCommand{
		EmployeeID: req.EmployeeID, LeaveType: req.LeaveType,
		StartDate: req.StartDate, EndDate: req.EndDate, Reason: req.Reason,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create leave request")
		writeError(w, http.StatusInternalServerError, "failed to create leave request")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "leave request created successfully"})
}

// ListLeaveRequests godoc
// @Summary      List leave requests
// @Description  Retrieve a paginated list of leave requests with optional filters
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        employee_id  query  string  false  "Filter by employee ID"
// @Param        status       query  string  false  "Filter by status"
// @Param        offset       query  int     false  "Pagination offset"
// @Param        limit        query  int     false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/leave-requests [get]
func (h *HrmHandler) ListLeaveRequests(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &listleaverequests.ListLeaveRequestsQuery{
		EmployeeID: r.URL.Query().Get("employee_id"),
		Status: r.URL.Query().Get("status"), Offset: offset, Limit: limit,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list leave requests")
		writeError(w, http.StatusInternalServerError, "failed to list leave requests")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// ReviewLeaveRequest godoc
// @Summary      Review leave request
// @Description  Approve or reject a pending leave request
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id    path  string                       true  "Leave Request ID (UUID)"
// @Param        body  body  ReviewLeaveRequestRequest    true  "Review payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/leave-requests/{id}/review [put]
func (h *HrmHandler) ReviewLeaveRequest(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid leave request id")
		return
	}

	var req ReviewLeaveRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &reviewleave.ReviewLeaveRequestCommand{
		ID: id.String(), Status: req.Status, ReviewedBy: req.ReviewedBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to review leave request")
		writeError(w, http.StatusInternalServerError, "failed to review leave request")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "leave request reviewed successfully"})
}

// --- Payroll Period handlers ---

// CreatePayrollPeriod godoc
// @Summary      Create payroll period
// @Description  Create a new payroll period (e.g. monthly)
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        body  body  CreatePayrollPeriodRequest  true  "Payroll period payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods [post]
func (h *HrmHandler) CreatePayrollPeriod(w http.ResponseWriter, r *http.Request) {
	var req CreatePayrollPeriodRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createpayrollperiod.CreatePayrollPeriodCommand{
		Period: req.Period, StartDate: req.StartDate, EndDate: req.EndDate, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create payroll period")
		writeError(w, http.StatusInternalServerError, "failed to create payroll period")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "payroll period created successfully"})
}

// ListPayrollPeriods godoc
// @Summary      List payroll periods
// @Description  Retrieve a paginated list of payroll periods
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        status  query  string  false  "Filter by status"
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods [get]
func (h *HrmHandler) ListPayrollPeriods(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &listpayrollperiods.ListPayrollPeriodsQuery{
		Status: r.URL.Query().Get("status"), Offset: offset, Limit: limit,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list payroll periods")
		writeError(w, http.StatusInternalServerError, "failed to list payroll periods")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// GetPayrollPeriod godoc
// @Summary      Get payroll period by ID
// @Description  Retrieve a single payroll period with its details
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Payroll Period ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods/{id} [get]
func (h *HrmHandler) GetPayrollPeriod(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll period id")
		return
	}

	query := &getpayrollperiod.GetPayrollPeriodQuery{PeriodID: id}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get payroll period")
		writeError(w, http.StatusInternalServerError, "failed to get payroll period")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ApprovePayroll godoc
// @Summary      Approve payroll period
// @Description  Approve a draft payroll period
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id    path  string                        true  "Payroll Period ID (UUID)"
// @Param        body  body  UpdatePayrollPeriodRequest    true  "Approval payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods/{id}/approve [put]
func (h *HrmHandler) ApprovePayroll(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll period id")
		return
	}

	var req UpdatePayrollPeriodRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatepayrollperiod.UpdatePayrollPeriodCommand{
		ID: id.String(), Status: "approved", ApprovedBy: req.ApprovedBy, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to approve payroll")
		writeError(w, http.StatusInternalServerError, "failed to approve payroll")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "payroll approved successfully"})
}

// DisbursePayroll godoc
// @Summary      Disburse payroll
// @Description  Mark an approved payroll period as disbursed
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id    path  string                        true  "Payroll Period ID (UUID)"
// @Param        body  body  UpdatePayrollPeriodRequest    true  "Disbursement payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods/{id}/disburse [put]
func (h *HrmHandler) DisbursePayroll(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll period id")
		return
	}

	var req UpdatePayrollPeriodRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatepayrollperiod.UpdatePayrollPeriodCommand{
		ID: id.String(), Status: "disbursed", ApprovedBy: req.ApprovedBy, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to disburse payroll")
		writeError(w, http.StatusInternalServerError, "failed to disburse payroll")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "payroll disbursed successfully"})
}

// --- Payroll Item handlers ---

// GeneratePayroll godoc
// @Summary      Generate payroll item
// @Description  Create a payroll item for an employee in a payroll period
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id    path  string                       true  "Payroll Period ID (UUID)"
// @Param        body  body  CreatePayrollItemRequest     true  "Payroll item payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods/{id}/items [post]
func (h *HrmHandler) GeneratePayroll(w http.ResponseWriter, r *http.Request) {
	periodIDStr := chi.URLParam(r, "id")
	periodID, err := uuid.Parse(periodIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll period id")
		return
	}

	var req CreatePayrollItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createpayrollitem.CreatePayrollItemCommand{
		PayrollPeriodID: periodID.String(), EmployeeID: req.EmployeeID,
		BaseSalary: req.BaseSalary, FacilitatorSessions: req.FacilitatorSessions,
		FacilitatorFee: req.FacilitatorFee, AttendanceDeduction: req.AttendanceDeduction,
		Bonus: req.Bonus, TotalAmount: req.TotalAmount, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to generate payroll item")
		writeError(w, http.StatusInternalServerError, "failed to generate payroll item")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "payroll item created successfully"})
}

// GetPayrollItems godoc
// @Summary      Get payroll items
// @Description  Retrieve all payroll items for a payroll period
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Payroll Period ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-periods/{id}/items [get]
func (h *HrmHandler) GetPayrollItems(w http.ResponseWriter, r *http.Request) {
	periodIDStr := chi.URLParam(r, "id")
	_, err := uuid.Parse(periodIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll period id")
		return
	}

	query := &listpayrollitems.ListPayrollItemsQuery{PayrollPeriodID: periodIDStr}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get payroll items")
		writeError(w, http.StatusInternalServerError, "failed to get payroll items")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdatePayrollItem godoc
// @Summary      Update payroll item
// @Description  Update a specific payroll item
// @Tags         hrm
// @Accept       json
// @Produce      json
// @Param        itemId  path  string                       true  "Payroll Item ID (UUID)"
// @Param        body    body  UpdatePayrollItemRequest     true  "Payroll item update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hrm/payroll-items/{itemId} [put]
func (h *HrmHandler) UpdatePayrollItem(w http.ResponseWriter, r *http.Request) {
	itemIDStr := chi.URLParam(r, "itemId")
	itemID, err := uuid.Parse(itemIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payroll item id")
		return
	}

	var req UpdatePayrollItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatepayrollitem.UpdatePayrollItemCommand{
		ID: itemID.String(), BaseSalary: req.BaseSalary,
		FacilitatorSessions: req.FacilitatorSessions, FacilitatorFee: req.FacilitatorFee,
		AttendanceDeduction: req.AttendanceDeduction, Bonus: req.Bonus,
		TotalAmount: req.TotalAmount, Status: req.Status, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update payroll item")
		writeError(w, http.StatusInternalServerError, "failed to update payroll item")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "payroll item updated successfully"})
}

// --- Route Registration ---

func RegisterHrmRoutes(h *HrmHandler, r chi.Router) {
	// Employee routes
	r.Post("/api/v1/hrm/employees", h.CreateEmployee)
	r.Get("/api/v1/hrm/employees", h.ListEmployees)
	r.Get("/api/v1/hrm/employees/{id}", h.GetEmployee)
	r.Put("/api/v1/hrm/employees/{id}", h.UpdateEmployee)

	// Attendance routes
	r.Post("/api/v1/hrm/attendance", h.CreateAttendance)
	r.Get("/api/v1/hrm/attendance", h.ListAttendance)
	r.Get("/api/v1/hrm/attendance/summary", h.GetAttendanceSummary)

	// Leave request routes
	r.Post("/api/v1/hrm/leave-requests", h.CreateLeaveRequest)
	r.Get("/api/v1/hrm/leave-requests", h.ListLeaveRequests)
	r.Put("/api/v1/hrm/leave-requests/{id}/review", h.ReviewLeaveRequest)

	// Payroll period routes
	r.Post("/api/v1/hrm/payroll-periods", h.CreatePayrollPeriod)
	r.Get("/api/v1/hrm/payroll-periods", h.ListPayrollPeriods)
	r.Get("/api/v1/hrm/payroll-periods/{id}", h.GetPayrollPeriod)
	r.Put("/api/v1/hrm/payroll-periods/{id}/approve", h.ApprovePayroll)
	r.Put("/api/v1/hrm/payroll-periods/{id}/disburse", h.DisbursePayroll)
	r.Post("/api/v1/hrm/payroll-periods/{id}/items", h.GeneratePayroll)
	r.Get("/api/v1/hrm/payroll-periods/{id}/items", h.GetPayrollItems)

	// Payroll item routes
	r.Put("/api/v1/hrm/payroll-items/{itemId}", h.UpdatePayrollItem)
}
