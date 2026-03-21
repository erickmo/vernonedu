package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"go.uber.org/fx"

	// infrastructure
	"github.com/vernonedu/entrepreneurship-api/infrastructure/config"
	"github.com/vernonedu/entrepreneurship-api/infrastructure/database"
	// pkg
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/hooks"
	"github.com/vernonedu/entrepreneurship-api/pkg/jwtutil"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	// commands
	createbusiness "github.com/vernonedu/entrepreneurship-api/internal/command/create_business"
	createcanvas "github.com/vernonedu/entrepreneurship-api/internal/command/create_canvas"
	createdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/create_designthinking"
	createitem "github.com/vernonedu/entrepreneurship-api/internal/command/create_item"
	createuser "github.com/vernonedu/entrepreneurship-api/internal/command/create_user"
	deletebusiness "github.com/vernonedu/entrepreneurship-api/internal/command/delete_business"
	deletecanvas "github.com/vernonedu/entrepreneurship-api/internal/command/delete_canvas"
	deletedesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/delete_designthinking"
	deleteitem "github.com/vernonedu/entrepreneurship-api/internal/command/delete_item"
	deleteuser "github.com/vernonedu/entrepreneurship-api/internal/command/delete_user"
	registeruser "github.com/vernonedu/entrepreneurship-api/internal/command/register_user"
	updatebusiness "github.com/vernonedu/entrepreneurship-api/internal/command/update_business"
	updatecanvas "github.com/vernonedu/entrepreneurship-api/internal/command/update_canvas"
	updatedesignthinking "github.com/vernonedu/entrepreneurship-api/internal/command/update_designthinking"
	updateitem "github.com/vernonedu/entrepreneurship-api/internal/command/update_item"
	updateuser "github.com/vernonedu/entrepreneurship-api/internal/command/update_user"
	assignbatchfacilitator "github.com/vernonedu/entrepreneurship-api/internal/command/assign_batch_facilitator"
	createcoursebatch "github.com/vernonedu/entrepreneurship-api/internal/command/create_course_batch"
	createcourse "github.com/vernonedu/entrepreneurship-api/internal/command/create_course"
	createdepartment "github.com/vernonedu/entrepreneurship-api/internal/command/create_department"
	createenrollment "github.com/vernonedu/entrepreneurship-api/internal/command/create_enrollment"
	updateenrollmentpayment "github.com/vernonedu/entrepreneurship-api/internal/command/update_enrollment_payment_status"
	updateenrollmentstatus "github.com/vernonedu/entrepreneurship-api/internal/command/update_enrollment_status"
	createstudent "github.com/vernonedu/entrepreneurship-api/internal/command/create_student"
	deletecoursebatch "github.com/vernonedu/entrepreneurship-api/internal/command/delete_course_batch"
	deletecourse "github.com/vernonedu/entrepreneurship-api/internal/command/delete_course"
	deletedepartment "github.com/vernonedu/entrepreneurship-api/internal/command/delete_department"
	deletestudent "github.com/vernonedu/entrepreneurship-api/internal/command/delete_student"
	updatecoursebatch "github.com/vernonedu/entrepreneurship-api/internal/command/update_course_batch"
	updatecourse "github.com/vernonedu/entrepreneurship-api/internal/command/update_course"
	updatedepartment "github.com/vernonedu/entrepreneurship-api/internal/command/update_department"
	updatestudent "github.com/vernonedu/entrepreneurship-api/internal/command/update_student"
	// curriculum commands
	archivemastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/archive_mastercourse"
	createcoursetype "github.com/vernonedu/entrepreneurship-api/internal/command/create_coursetype"
	createcoursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/create_coursemodule"
	createcourseversion "github.com/vernonedu/entrepreneurship-api/internal/command/create_courseversion"
	createmastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/create_mastercourse"
	deletecoursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/delete_coursemodule"
	deletemastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/delete_mastercourse"
	promotecourseversion "github.com/vernonedu/entrepreneurship-api/internal/command/promote_courseversion"
	submitresult "github.com/vernonedu/entrepreneurship-api/internal/command/submit_testresult"
	togglecoursetype "github.com/vernonedu/entrepreneurship-api/internal/command/toggle_coursetype"
	updatecoursetype "github.com/vernonedu/entrepreneurship-api/internal/command/update_coursetype"
	updatecoursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/update_coursemodule"
	updatefailureconfig "github.com/vernonedu/entrepreneurship-api/internal/command/update_failureconfig"
	updatemastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/update_mastercourse"
	upsertchartest "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_character_test_config"
	upsertinternship "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_internship_config"
	updatetalentpool "github.com/vernonedu/entrepreneurship-api/internal/command/update_talentpool_status"
	// lead commands
	createlead "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead"
	deletelead "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead"
	updatelead "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead"
	// biz-dev commands
	createpartner "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner"
	createmou "github.com/vernonedu/entrepreneurship-api/internal/command/create_mou"
	createbranch "github.com/vernonedu/entrepreneurship-api/internal/command/create_branch"
	createokrobjective "github.com/vernonedu/entrepreneurship-api/internal/command/create_okr_objective"
	createinvestmentplan "github.com/vernonedu/entrepreneurship-api/internal/command/create_investment_plan"
	createdelegation "github.com/vernonedu/entrepreneurship-api/internal/command/create_delegation"
	// queries
	getbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/get_business"
	getcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/get_canvas"
	getdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/get_designthinking"
	getitem "github.com/vernonedu/entrepreneurship-api/internal/query/get_item"
	getuser "github.com/vernonedu/entrepreneurship-api/internal/query/get_user"
	listbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/list_business"
	listcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/list_canvas"
	listdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/list_designthinking"
	listitemsbycanvas "github.com/vernonedu/entrepreneurship-api/internal/query/list_items_by_canvas"
	listuser "github.com/vernonedu/entrepreneurship-api/internal/query/list_user"
	searchbusiness "github.com/vernonedu/entrepreneurship-api/internal/query/search_business"
	searchcanvas "github.com/vernonedu/entrepreneurship-api/internal/query/search_canvas"
	searchdesignthinking "github.com/vernonedu/entrepreneurship-api/internal/query/search_designthinking"
	searchuser "github.com/vernonedu/entrepreneurship-api/internal/query/search_user"
	getcoursebatch "github.com/vernonedu/entrepreneurship-api/internal/query/get_course_batch"
	getcoursebatchdetail "github.com/vernonedu/entrepreneurship-api/internal/query/get_course_batch_detail"
	getcourse "github.com/vernonedu/entrepreneurship-api/internal/query/get_course"
	getdepartment "github.com/vernonedu/entrepreneurship-api/internal/query/get_department"
	getdeptbatches "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_batches"
	getdeptcourses "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_courses"
	getdeptstudents "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_students"
	getdepttalentpool "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_talentpool"
	getenrollment "github.com/vernonedu/entrepreneurship-api/internal/query/get_enrollment"
	getstudent "github.com/vernonedu/entrepreneurship-api/internal/query/get_student"
	getstudenthistory "github.com/vernonedu/entrepreneurship-api/internal/query/get_student_enrollment_history"
	getstudentrecos "github.com/vernonedu/entrepreneurship-api/internal/query/get_student_recommendations"
	getstudentnotes "github.com/vernonedu/entrepreneurship-api/internal/query/get_student_notes"
	listcoursebatch "github.com/vernonedu/entrepreneurship-api/internal/query/list_course_batch"
	listcourse "github.com/vernonedu/entrepreneurship-api/internal/query/list_course"
	listdepartment "github.com/vernonedu/entrepreneurship-api/internal/query/list_department"
	listdeptsummary "github.com/vernonedu/entrepreneurship-api/internal/query/list_department_summary"
	listenrollment "github.com/vernonedu/entrepreneurship-api/internal/query/list_enrollment"
	listenrollmentsummary "github.com/vernonedu/entrepreneurship-api/internal/query/list_enrollment_summary"
	liststudent "github.com/vernonedu/entrepreneurship-api/internal/query/list_student"
	// curriculum queries
	getchartest "github.com/vernonedu/entrepreneurship-api/internal/query/get_character_test_config"
	getcoursetype "github.com/vernonedu/entrepreneurship-api/internal/query/get_coursetype"
	getcoursemodule "github.com/vernonedu/entrepreneurship-api/internal/query/get_coursemodule"
	getcourseversion "github.com/vernonedu/entrepreneurship-api/internal/query/get_courseversion"
	getinternship "github.com/vernonedu/entrepreneurship-api/internal/query/get_internship_config"
	getmastercourse "github.com/vernonedu/entrepreneurship-api/internal/query/get_mastercourse"
	gettalentpool "github.com/vernonedu/entrepreneurship-api/internal/query/get_talentpool"
	listcoursetype "github.com/vernonedu/entrepreneurship-api/internal/query/list_coursetype"
	listcoursemodule "github.com/vernonedu/entrepreneurship-api/internal/query/list_coursemodule"
	listcourseversion "github.com/vernonedu/entrepreneurship-api/internal/query/list_courseversion"
	listmastercourse "github.com/vernonedu/entrepreneurship-api/internal/query/list_mastercourse"
	listtalentpool "github.com/vernonedu/entrepreneurship-api/internal/query/list_talentpool"
	// lead queries
	getlead "github.com/vernonedu/entrepreneurship-api/internal/query/get_lead"
	listlead "github.com/vernonedu/entrepreneurship-api/internal/query/list_lead"
	// biz-dev queries
	listpartners "github.com/vernonedu/entrepreneurship-api/internal/query/list_partners"
	getpartner "github.com/vernonedu/entrepreneurship-api/internal/query/get_partner"
	listbranches "github.com/vernonedu/entrepreneurship-api/internal/query/list_branches"
	listokr "github.com/vernonedu/entrepreneurship-api/internal/query/list_okr"
	listinvestments "github.com/vernonedu/entrepreneurship-api/internal/query/list_investment_plans"
	listdelegations "github.com/vernonedu/entrepreneurship-api/internal/query/list_delegations"
	// handlers
	httphandler "github.com/vernonedu/entrepreneurship-api/internal/delivery/http"
)

// queryHandlerAdapter adapts handlers that accept interface{} to querybus.QueryHandler
type queryHandlerAdapter struct {
	fn func(ctx context.Context, q interface{}) (interface{}, error)
}

func (a *queryHandlerAdapter) Handle(ctx context.Context, q querybus.Query) (interface{}, error) {
	return a.fn(ctx, q)
}

func adaptQueryHandler(fn func(ctx context.Context, q interface{}) (interface{}, error)) querybus.QueryHandler {
	return &queryHandlerAdapter{fn: fn}
}

func main() {
	app := fx.New(
		fx.Provide(
			// Config
			config.Load,

			// Database
			newDB,

			// EventBus
			func() eventbus.EventBus {
				return eventbus.NewInMemoryEventBus()
			},

			// CommandBus with ValidationHook and LoggingHook
			func() *commandbus.SimpleCommandBus {
				cb := commandbus.NewCommandBus()
				cb.AddHook(hooks.NewValidationHook())
				cb.AddHook(hooks.NewLoggingHook())
				return cb
			},
			func(cb *commandbus.SimpleCommandBus) commandbus.CommandBus {
				return cb
			},

			// QueryBus
			func() *querybus.SimpleQueryBus {
				return querybus.NewQueryBus()
			},
			func(qb *querybus.SimpleQueryBus) querybus.QueryBus {
				return qb
			},

			// JWT
			newJWTUtil,

			// Repositories — provided as concrete types for direct use in Invoke
			func(db *sqlx.DB) *database.UserRepository {
				return database.NewUserRepository(db)
			},
			func(db *sqlx.DB) *database.BusinessRepository {
				return database.NewBusinessRepository(db)
			},
			func(db *sqlx.DB) *database.ItemRepository {
				return database.NewItemRepository(db)
			},
			func(db *sqlx.DB) *database.CanvasRepository {
				return database.NewCanvasRepository(db)
			},
			func(db *sqlx.DB) *database.DesignThinkingRepository {
				return database.NewDesignThinkingRepository(db)
			},
			func(db *sqlx.DB) *database.DepartmentRepository {
				return database.NewDepartmentRepository(db)
			},
			func(db *sqlx.DB) *database.CourseRepository {
				return database.NewCourseRepository(db)
			},
			func(db *sqlx.DB) *database.CourseBatchRepository {
				return database.NewCourseBatchRepository(db)
			},
			func(db *sqlx.DB) *database.StudentRepository {
				return database.NewStudentRepository(db)
			},
			func(db *sqlx.DB) *database.EnrollmentRepository {
				return database.NewEnrollmentRepository(db)
			},
			// Curriculum repositories
			func(db *sqlx.DB) *database.MasterCourseRepository {
				return database.NewMasterCourseRepository(db)
			},
			func(db *sqlx.DB) *database.CourseTypeRepository {
				return database.NewCourseTypeRepository(db)
			},
			func(db *sqlx.DB) *database.CourseVersionRepository {
				return database.NewCourseVersionRepository(db)
			},
			func(db *sqlx.DB) *database.CourseModuleRepository {
				return database.NewCourseModuleRepository(db)
			},
			func(db *sqlx.DB) *database.InternshipConfigRepository {
				return database.NewInternshipConfigRepository(db)
			},
			func(db *sqlx.DB) *database.CharacterTestConfigRepository {
				return database.NewCharacterTestConfigRepository(db)
			},
			func(db *sqlx.DB) *database.TalentPoolRepository {
				return database.NewTalentPoolRepository(db)
			},
			// BizDev repositories
			func(db *sqlx.DB) *database.PartnerRepository {
				return database.NewPartnerRepository(db)
			},
			func(db *sqlx.DB) *database.BranchRepository {
				return database.NewBranchRepository(db)
			},
			func(db *sqlx.DB) *database.OkrRepository {
				return database.NewOkrRepository(db)
			},
			func(db *sqlx.DB) *database.InvestmentRepository {
				return database.NewInvestmentRepository(db)
			},
			func(db *sqlx.DB) *database.DelegationRepository {
				return database.NewDelegationRepository(db)
			},
			func(db *sqlx.DB) *database.LeadRepository {
				return database.NewLeadRepository(db)
			},

			// HTTP handlers
			newUserHTTPHandler,
			newBusinessHTTPHandler,
			newItemHTTPHandler,
			newCanvasHTTPHandler,
			newDesignThinkingHTTPHandler,
			newAuthHTTPHandler,
			newDepartmentHTTPHandler,
			newCourseHTTPHandler,
			newCourseBatchHTTPHandler,
			newStudentHTTPHandler,
			newEnrollmentHTTPHandler,
			// Lead HTTP handler
			newLeadHTTPHandler,
			// BizDev HTTP handlers
			newPartnerHTTPHandler,
			newBranchHTTPHandler,
			newOkrHTTPHandler,
			newInvestmentHTTPHandler,
			newDelegationHTTPHandler,

			// Curriculum HTTP handlers
			newMasterCourseHTTPHandler,
			newCourseTypeHTTPHandler,
			newCourseVersionHTTPHandler,
			newCourseModuleHTTPHandler,
			newProgramKarirHTTPHandler,
			newTalentPoolHTTPHandler,

			// Router
			newRouter,
		),
		fx.Invoke(
			registerHandlers,
			startServer,
		),
	)

	app.Run()
}

func newDB(cfg *config.Config) (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", cfg.Database.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	db.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	db.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.Database.ConnMaxLifetime)
	return db, nil
}

func newJWTUtil(cfg *config.Config) *jwtutil.JWTUtil {
	return jwtutil.NewJWTUtil(cfg.App.JWTSecret)
}

func newUserHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.UserHandler {
	return httphandler.NewUserHandler(cmdBus, qryBus)
}

func newBusinessHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.BusinessHandler {
	return httphandler.NewBusinessHandler(cmdBus, qryBus)
}

func newItemHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.ItemHandler {
	return httphandler.NewItemHandler(cmdBus, qryBus)
}

func newCanvasHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CanvasHandler {
	return httphandler.NewCanvasHandler(cmdBus, qryBus)
}

func newDesignThinkingHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.DesignThinkingHandler {
	return httphandler.NewDesignThinkingHandler(cmdBus, qryBus)
}

func newAuthHTTPHandler(
	cmdBus commandbus.CommandBus,
	qryBus querybus.QueryBus,
	db *sqlx.DB,
	jwtUtil *jwtutil.JWTUtil,
) *httphandler.AuthHandler {
	repo := database.NewUserRepository(db)
	return httphandler.NewAuthHandler(cmdBus, qryBus, repo, jwtUtil)
}

func newStudentHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, studentRepo *database.StudentRepository) *httphandler.StudentHandler {
	return httphandler.NewStudentHandler(cmdBus, qryBus, studentRepo)
}

func newEnrollmentHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.EnrollmentHandler {
	return httphandler.NewEnrollmentHandler(cmdBus, qryBus)
}

func newDepartmentHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.DepartmentHandler {
	return httphandler.NewDepartmentHandler(cmdBus, qryBus)
}

func newCourseHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CourseHandler {
	return httphandler.NewCourseHandler(cmdBus, qryBus)
}

func newCourseBatchHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CourseBatchHandler {
	return httphandler.NewCourseBatchHandler(cmdBus, qryBus)
}

func newMasterCourseHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, repo *database.MasterCourseRepository) *httphandler.MasterCourseHandler {
	return httphandler.NewMasterCourseHandler(cmdBus, qryBus, repo)
}

func newCourseTypeHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CourseTypeHandler {
	return httphandler.NewCourseTypeHandler(cmdBus, qryBus)
}

func newCourseVersionHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CourseVersionHandler {
	return httphandler.NewCourseVersionHandler(cmdBus, qryBus)
}

func newCourseModuleHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CourseModuleHandler {
	return httphandler.NewCourseModuleHandler(cmdBus, qryBus)
}

func newProgramKarirHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.ProgramKarirHandler {
	return httphandler.NewProgramKarirHandler(cmdBus, qryBus)
}

func newTalentPoolHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.TalentPoolHandler {
	return httphandler.NewTalentPoolHandler(cmdBus, qryBus)
}

func newLeadHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.LeadHandler {
	return httphandler.NewLeadHandler(cmdBus, qryBus)
}

func newPartnerHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.PartnerHandler {
	return httphandler.NewPartnerHandler(cmdBus, qryBus)
}

func newBranchHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.BranchHandler {
	return httphandler.NewBranchHandler(cmdBus, qryBus)
}

func newOkrHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.OkrHandler {
	return httphandler.NewOkrHandler(cmdBus, qryBus)
}

func newInvestmentHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.InvestmentHandler {
	return httphandler.NewInvestmentHandler(cmdBus, qryBus)
}

func newDelegationHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.DelegationHTTPHandler {
	return httphandler.NewDelegationHTTPHandler(cmdBus, qryBus)
}

func newRouter(
	userHandler *httphandler.UserHandler,
	businessHandler *httphandler.BusinessHandler,
	itemHandler *httphandler.ItemHandler,
	canvasHandler *httphandler.CanvasHandler,
	dtHandler *httphandler.DesignThinkingHandler,
	authHandler *httphandler.AuthHandler,
	departmentHandler *httphandler.DepartmentHandler,
	courseHandler *httphandler.CourseHandler,
	courseBatchHandler *httphandler.CourseBatchHandler,
	studentHandler *httphandler.StudentHandler,
	enrollmentHandler *httphandler.EnrollmentHandler,
	masterCourseHandler *httphandler.MasterCourseHandler,
	courseTypeHandler *httphandler.CourseTypeHandler,
	courseVersionHandler *httphandler.CourseVersionHandler,
	courseModuleHandler *httphandler.CourseModuleHandler,
	programKarirHandler *httphandler.ProgramKarirHandler,
	talentPoolHandler *httphandler.TalentPoolHandler,
	leadHandler *httphandler.LeadHandler,
	partnerHandler *httphandler.PartnerHandler,
	branchHandler *httphandler.BranchHandler,
	okrHandler *httphandler.OkrHandler,
	investmentHandler *httphandler.InvestmentHandler,
	delegationHandler *httphandler.DelegationHTTPHandler,
	jwtUtil *jwtutil.JWTUtil,
) *chi.Mux {
	r := chi.NewRouter()
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(pkgmiddleware.CORS)

	zerolog.SetGlobalLevel(zerolog.DebugLevel)

	// Health check
	r.Get("/health", func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	})

	jwtMW := pkgmiddleware.JWTAuth(jwtUtil)

	// Auth routes (public register/login + protected /me)
	httphandler.RegisterAuthRoutes(authHandler, r, jwtMW)

	// Protected routes
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		httphandler.RegisterUserRoutes(userHandler, r)
		httphandler.RegisterBusinessRoutes(businessHandler, r)
		httphandler.RegisterItemRoutes(itemHandler, r)
		httphandler.RegisterCanvasRoutes(canvasHandler, r)
		httphandler.RegisterDesignThinkingRoutes(dtHandler, r)
		httphandler.RegisterDepartmentRoutes(departmentHandler, r)
		httphandler.RegisterCourseRoutes(courseHandler, r)
		httphandler.RegisterCourseBatchRoutes(courseBatchHandler, r)
		httphandler.RegisterStudentRoutes(studentHandler, r)
		httphandler.RegisterEnrollmentRoutes(enrollmentHandler, r)
		// Curriculum routes
		httphandler.RegisterMasterCourseRoutes(masterCourseHandler, r)
		httphandler.RegisterCourseTypeRoutes(courseTypeHandler, r)
		httphandler.RegisterCourseVersionRoutes(courseVersionHandler, r)
		httphandler.RegisterCourseModuleRoutes(courseModuleHandler, r)
		httphandler.RegisterProgramKarirRoutes(programKarirHandler, r)
		httphandler.RegisterTalentPoolRoutes(talentPoolHandler, r)
		// Lead routes
		httphandler.RegisterLeadRoutes(leadHandler, r)
		// BizDev routes
		httphandler.RegisterPartnerRoutes(partnerHandler, r)
		httphandler.RegisterBranchRoutes(branchHandler, r)
		httphandler.RegisterOkrRoutes(okrHandler, r)
		httphandler.RegisterInvestmentRoutes(investmentHandler, r)
		httphandler.RegisterDelegationRoutes(delegationHandler, r)
	})

	return r
}

type registerParams struct {
	fx.In

	CmdBus         *commandbus.SimpleCommandBus
	QryBus         *querybus.SimpleQueryBus
	UserRepo        *database.UserRepository
	BizRepo         *database.BusinessRepository
	ItemRepo        *database.ItemRepository
	CanvasRepo      *database.CanvasRepository
	DTRepo          *database.DesignThinkingRepository
	DepartmentRepo  *database.DepartmentRepository
	CourseRepo      *database.CourseRepository
	CourseBatchRepo *database.CourseBatchRepository
	StudentRepo     *database.StudentRepository
	EnrollmentRepo  *database.EnrollmentRepository
	// Curriculum repositories
	MasterCourseRepo      *database.MasterCourseRepository
	CourseTypeRepo        *database.CourseTypeRepository
	CourseVersionRepo     *database.CourseVersionRepository
	CourseModuleRepo      *database.CourseModuleRepository
	InternshipConfigRepo  *database.InternshipConfigRepository
	CharTestConfigRepo    *database.CharacterTestConfigRepository
	TalentPoolRepo        *database.TalentPoolRepository
	// BizDev repositories
	PartnerRepo    *database.PartnerRepository
	BranchRepo     *database.BranchRepository
	OkrRepo        *database.OkrRepository
	InvestmentRepo *database.InvestmentRepository
	DelegationRepo *database.DelegationRepository
	// Lead repository
	LeadRepo *database.LeadRepository
	EventBus eventbus.EventBus
}

func registerHandlers(p registerParams) error {
	// ---- Command Handlers ----

	// User
	if err := p.CmdBus.Register(&createuser.CreateUserCommand{},
		createuser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&registeruser.RegisterUserCommand{},
		registeruser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateuser.UpdateUserCommand{},
		updateuser.NewHandler(p.UserRepo, p.UserRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteuser.DeleteUserCommand{},
		deleteuser.NewHandler(p.UserRepo, p.EventBus)); err != nil {
		return err
	}

	// Business
	if err := p.CmdBus.Register(&createbusiness.CreateBusinessCommand{},
		createbusiness.NewHandler(p.BizRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatebusiness.UpdateBusinessCommand{},
		updatebusiness.NewHandler(p.BizRepo, p.BizRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletebusiness.DeleteBusinessCommand{},
		deletebusiness.NewHandler(p.BizRepo, p.EventBus)); err != nil {
		return err
	}

	// Item
	if err := p.CmdBus.Register(&createitem.CreateItemCommand{},
		createitem.NewHandler(p.ItemRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateitem.UpdateItemCommand{},
		updateitem.NewHandler(p.ItemRepo, p.ItemRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteitem.DeleteItemCommand{},
		deleteitem.NewHandler(p.ItemRepo, p.EventBus)); err != nil {
		return err
	}

	// Canvas
	if err := p.CmdBus.Register(&createcanvas.CreateCanvasCommand{},
		createcanvas.NewHandler(p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecanvas.UpdateCanvasCommand{},
		updatecanvas.NewHandler(p.CanvasRepo, p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecanvas.DeleteCanvasCommand{},
		deletecanvas.NewHandler(p.CanvasRepo, p.EventBus)); err != nil {
		return err
	}

	// DesignThinking
	if err := p.CmdBus.Register(&createdesignthinking.CreateDesignThinkingCommand{},
		createdesignthinking.NewHandler(p.DTRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatedesignthinking.UpdateDesignThinkingCommand{},
		updatedesignthinking.NewHandler(p.DTRepo, p.DTRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletedesignthinking.DeleteDesignThinkingCommand{},
		deletedesignthinking.NewHandler(p.DTRepo, p.EventBus)); err != nil {
		return err
	}

	// ---- Query Handlers ----

	// User
	getUserH := getuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&getuser.GetUserQuery{}, adaptQueryHandler(getUserH.Handle)); err != nil {
		return err
	}
	listUserH := listuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&listuser.ListUserQuery{}, adaptQueryHandler(listUserH.Handle)); err != nil {
		return err
	}
	searchUserH := searchuser.NewHandler(p.UserRepo)
	if err := p.QryBus.Register(&searchuser.SearchUserQuery{}, adaptQueryHandler(searchUserH.Handle)); err != nil {
		return err
	}

	// Business
	getBizH := getbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&getbusiness.GetBusinessQuery{}, adaptQueryHandler(getBizH.Handle)); err != nil {
		return err
	}
	listBizH := listbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&listbusiness.ListBusinessQuery{}, adaptQueryHandler(listBizH.Handle)); err != nil {
		return err
	}
	searchBizH := searchbusiness.NewHandler(p.BizRepo)
	if err := p.QryBus.Register(&searchbusiness.SearchBusinessQuery{}, adaptQueryHandler(searchBizH.Handle)); err != nil {
		return err
	}

	// Item
	getItemH := getitem.NewHandler(p.ItemRepo)
	if err := p.QryBus.Register(&getitem.GetItemQuery{}, adaptQueryHandler(getItemH.Handle)); err != nil {
		return err
	}
	listItemsByCanvasH := listitemsbycanvas.NewHandler(p.ItemRepo)
	if err := p.QryBus.Register(&listitemsbycanvas.ListItemsByCanvasQuery{}, adaptQueryHandler(listItemsByCanvasH.Handle)); err != nil {
		return err
	}

	// Canvas
	getCanvasH := getcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&getcanvas.GetCanvasQuery{}, adaptQueryHandler(getCanvasH.Handle)); err != nil {
		return err
	}
	listCanvasH := listcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&listcanvas.ListCanvasQuery{}, adaptQueryHandler(listCanvasH.Handle)); err != nil {
		return err
	}
	searchCanvasH := searchcanvas.NewHandler(p.CanvasRepo)
	if err := p.QryBus.Register(&searchcanvas.SearchCanvasQuery{}, adaptQueryHandler(searchCanvasH.Handle)); err != nil {
		return err
	}

	// DesignThinking
	getDTH := getdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&getdesignthinking.GetDesignThinkingQuery{}, adaptQueryHandler(getDTH.Handle)); err != nil {
		return err
	}
	listDTH := listdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&listdesignthinking.ListDesignThinkingQuery{}, adaptQueryHandler(listDTH.Handle)); err != nil {
		return err
	}
	searchDTH := searchdesignthinking.NewHandler(p.DTRepo)
	if err := p.QryBus.Register(&searchdesignthinking.SearchDesignThinkingQuery{}, adaptQueryHandler(searchDTH.Handle)); err != nil {
		return err
	}

	// Department
	if err := p.CmdBus.Register(&createdepartment.CreateDepartmentCommand{},
		createdepartment.NewHandler(p.DepartmentRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatedepartment.UpdateDepartmentCommand{},
		updatedepartment.NewHandler(p.DepartmentRepo, p.DepartmentRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletedepartment.DeleteDepartmentCommand{},
		deletedepartment.NewHandler(p.DepartmentRepo, p.EventBus)); err != nil {
		return err
	}
	getDepartmentH := getdepartment.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&getdepartment.GetDepartmentQuery{}, adaptQueryHandler(getDepartmentH.Handle)); err != nil {
		return err
	}
	listDepartmentH := listdepartment.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&listdepartment.ListDepartmentQuery{}, adaptQueryHandler(listDepartmentH.Handle)); err != nil {
		return err
	}
	listDeptSummaryH := listdeptsummary.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&listdeptsummary.ListDepartmentSummaryQuery{}, adaptQueryHandler(listDeptSummaryH.Handle)); err != nil {
		return err
	}
	getDeptBatchesH := getdeptbatches.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&getdeptbatches.GetDepartmentBatchesQuery{}, adaptQueryHandler(getDeptBatchesH.Handle)); err != nil {
		return err
	}
	getDeptCoursesH := getdeptcourses.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&getdeptcourses.GetDepartmentCoursesQuery{}, adaptQueryHandler(getDeptCoursesH.Handle)); err != nil {
		return err
	}
	getDeptStudentsH := getdeptstudents.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&getdeptstudents.GetDepartmentStudentsQuery{}, adaptQueryHandler(getDeptStudentsH.Handle)); err != nil {
		return err
	}
	getDeptTalentPoolH := getdepttalentpool.NewHandler(p.DepartmentRepo)
	if err := p.QryBus.Register(&getdepttalentpool.GetDepartmentTalentPoolQuery{}, adaptQueryHandler(getDeptTalentPoolH.Handle)); err != nil {
		return err
	}

	// Course
	if err := p.CmdBus.Register(&createcourse.CreateCourseCommand{},
		createcourse.NewHandler(p.CourseRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecourse.UpdateCourseCommand{},
		updatecourse.NewHandler(p.CourseRepo, p.CourseRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecourse.DeleteCourseCommand{},
		deletecourse.NewHandler(p.CourseRepo, p.EventBus)); err != nil {
		return err
	}
	getCourseH := getcourse.NewHandler(p.CourseRepo)
	if err := p.QryBus.Register(&getcourse.GetCourseQuery{}, adaptQueryHandler(getCourseH.Handle)); err != nil {
		return err
	}
	listCourseH := listcourse.NewHandler(p.CourseRepo)
	if err := p.QryBus.Register(&listcourse.ListCourseQuery{}, adaptQueryHandler(listCourseH.Handle)); err != nil {
		return err
	}

	// CourseBatch
	if err := p.CmdBus.Register(&assignbatchfacilitator.AssignBatchFacilitatorCommand{},
		assignbatchfacilitator.NewHandler(p.CourseBatchRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createcoursebatch.CreateCourseBatchCommand{},
		createcoursebatch.NewHandler(p.CourseBatchRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecoursebatch.UpdateCourseBatchCommand{},
		updatecoursebatch.NewHandler(p.CourseBatchRepo, p.CourseBatchRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecoursebatch.DeleteCourseBatchCommand{},
		deletecoursebatch.NewHandler(p.CourseBatchRepo, p.EventBus)); err != nil {
		return err
	}
	getCourseBatchH := getcoursebatch.NewHandler(p.CourseBatchRepo)
	if err := p.QryBus.Register(&getcoursebatch.GetCourseBatchQuery{}, adaptQueryHandler(getCourseBatchH.Handle)); err != nil {
		return err
	}
	getCourseBatchDetailH := getcoursebatchdetail.NewHandler(p.CourseBatchRepo)
	if err := p.QryBus.Register(&getcoursebatchdetail.GetCourseBatchDetailQuery{}, adaptQueryHandler(getCourseBatchDetailH.Handle)); err != nil {
		return err
	}
	listCourseBatchH := listcoursebatch.NewHandler(p.CourseBatchRepo)
	if err := p.QryBus.Register(&listcoursebatch.ListCourseBatchQuery{}, adaptQueryHandler(listCourseBatchH.Handle)); err != nil {
		return err
	}

	// Student
	if err := p.CmdBus.Register(&createstudent.CreateStudentCommand{},
		createstudent.NewHandler(p.StudentRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatestudent.UpdateStudentCommand{},
		updatestudent.NewHandler(p.StudentRepo, p.StudentRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletestudent.DeleteStudentCommand{},
		deletestudent.NewHandler(p.StudentRepo, p.EventBus)); err != nil {
		return err
	}

	getStudentH := getstudent.NewHandler(p.StudentRepo)
	if err := p.QryBus.Register(&getstudent.GetStudentQuery{}, adaptQueryHandler(getStudentH.Handle)); err != nil {
		return err
	}
	listStudentH := liststudent.NewHandler(p.StudentRepo)
	if err := p.QryBus.Register(&liststudent.ListStudentQuery{}, adaptQueryHandler(listStudentH.Handle)); err != nil {
		return err
	}
	getStudentHistoryH := getstudenthistory.NewHandler(p.StudentRepo)
	if err := p.QryBus.Register(&getstudenthistory.GetStudentEnrollmentHistoryQuery{}, adaptQueryHandler(getStudentHistoryH.Handle)); err != nil {
		return err
	}
	getStudentRecosH := getstudentrecos.NewHandler(p.StudentRepo)
	if err := p.QryBus.Register(&getstudentrecos.GetStudentRecommendationsQuery{}, adaptQueryHandler(getStudentRecosH.Handle)); err != nil {
		return err
	}
	getStudentNotesH := getstudentnotes.NewHandler(p.StudentRepo)
	if err := p.QryBus.Register(&getstudentnotes.GetStudentNotesQuery{}, adaptQueryHandler(getStudentNotesH.Handle)); err != nil {
		return err
	}

	// Enrollment
	if err := p.CmdBus.Register(&createenrollment.CreateEnrollmentCommand{},
		createenrollment.NewHandler(p.EnrollmentRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateenrollmentstatus.UpdateEnrollmentStatusCommand{},
		updateenrollmentstatus.NewHandler(p.EnrollmentRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateenrollmentpayment.UpdateEnrollmentPaymentStatusCommand{},
		updateenrollmentpayment.NewHandler(p.EnrollmentRepo)); err != nil {
		return err
	}

	getEnrollmentH := getenrollment.NewHandler(p.EnrollmentRepo)
	if err := p.QryBus.Register(&getenrollment.GetEnrollmentQuery{}, adaptQueryHandler(getEnrollmentH.Handle)); err != nil {
		return err
	}
	listEnrollmentH := listenrollment.NewHandler(p.EnrollmentRepo)
	if err := p.QryBus.Register(&listenrollment.ListEnrollmentQuery{}, adaptQueryHandler(listEnrollmentH.Handle)); err != nil {
		return err
	}
	listEnrollmentSummaryH := listenrollmentsummary.NewHandler(p.EnrollmentRepo)
	if err := p.QryBus.Register(&listenrollmentsummary.ListEnrollmentSummaryQuery{}, adaptQueryHandler(listEnrollmentSummaryH.Handle)); err != nil {
		return err
	}

	// ===== CURRICULUM =====

	// MasterCourse
	if err := p.CmdBus.Register(&createmastercourse.CreateMasterCourseCommand{},
		createmastercourse.NewHandler(p.MasterCourseRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatemastercourse.UpdateMasterCourseCommand{},
		updatemastercourse.NewHandler(p.MasterCourseRepo, p.MasterCourseRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletemastercourse.DeleteMasterCourseCommand{},
		deletemastercourse.NewHandler(p.MasterCourseRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&archivemastercourse.ArchiveMasterCourseCommand{},
		archivemastercourse.NewHandler(p.MasterCourseRepo, p.MasterCourseRepo, p.EventBus)); err != nil {
		return err
	}
	getMCH := getmastercourse.NewHandler(p.MasterCourseRepo)
	if err := p.QryBus.Register(&getmastercourse.GetMasterCourseQuery{}, adaptQueryHandler(getMCH.Handle)); err != nil {
		return err
	}
	listMCH := listmastercourse.NewHandler(p.MasterCourseRepo)
	if err := p.QryBus.Register(&listmastercourse.ListMasterCourseQuery{}, adaptQueryHandler(listMCH.Handle)); err != nil {
		return err
	}

	// CourseType
	if err := p.CmdBus.Register(&createcoursetype.CreateCourseTypeCommand{},
		createcoursetype.NewHandler(p.CourseTypeRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecoursetype.UpdateCourseTypeCommand{},
		updatecoursetype.NewHandler(p.CourseTypeRepo, p.CourseTypeRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&togglecoursetype.ToggleCourseTypeCommand{},
		togglecoursetype.NewHandler(p.CourseTypeRepo, p.CourseTypeRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatefailureconfig.UpdateFailureConfigCommand{},
		updatefailureconfig.NewHandler(p.CourseTypeRepo, p.CourseTypeRepo, p.EventBus)); err != nil {
		return err
	}
	getCTH := getcoursetype.NewHandler(p.CourseTypeRepo)
	if err := p.QryBus.Register(&getcoursetype.GetCourseTypeQuery{}, adaptQueryHandler(getCTH.Handle)); err != nil {
		return err
	}
	listCTH := listcoursetype.NewHandler(p.CourseTypeRepo)
	if err := p.QryBus.Register(&listcoursetype.ListCourseTypeQuery{}, adaptQueryHandler(listCTH.Handle)); err != nil {
		return err
	}

	// CourseVersion
	if err := p.CmdBus.Register(&createcourseversion.CreateCourseVersionCommand{},
		createcourseversion.NewHandler(p.CourseVersionRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&promotecourseversion.PromoteCourseVersionCommand{},
		promotecourseversion.NewHandler(p.CourseVersionRepo, p.CourseVersionRepo, p.EventBus)); err != nil {
		return err
	}
	getCVH := getcourseversion.NewHandler(p.CourseVersionRepo)
	if err := p.QryBus.Register(&getcourseversion.GetCourseVersionQuery{}, adaptQueryHandler(getCVH.Handle)); err != nil {
		return err
	}
	listCVH := listcourseversion.NewHandler(p.CourseVersionRepo)
	if err := p.QryBus.Register(&listcourseversion.ListCourseVersionQuery{}, adaptQueryHandler(listCVH.Handle)); err != nil {
		return err
	}

	// CourseModule
	if err := p.CmdBus.Register(&createcoursemodule.CreateCourseModuleCommand{},
		createcoursemodule.NewHandler(p.CourseModuleRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecoursemodule.UpdateCourseModuleCommand{},
		updatecoursemodule.NewHandler(p.CourseModuleRepo, p.CourseModuleRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecoursemodule.DeleteCourseModuleCommand{},
		deletecoursemodule.NewHandler(p.CourseModuleRepo, p.EventBus)); err != nil {
		return err
	}
	getCMH := getcoursemodule.NewHandler(p.CourseModuleRepo)
	if err := p.QryBus.Register(&getcoursemodule.GetCourseModuleQuery{}, adaptQueryHandler(getCMH.Handle)); err != nil {
		return err
	}
	listCMH := listcoursemodule.NewHandler(p.CourseModuleRepo)
	if err := p.QryBus.Register(&listcoursemodule.ListCourseModuleQuery{}, adaptQueryHandler(listCMH.Handle)); err != nil {
		return err
	}

	// InternshipConfig (program_karir)
	if err := p.CmdBus.Register(&upsertinternship.UpsertInternshipConfigCommand{},
		upsertinternship.NewHandler(p.InternshipConfigRepo, p.InternshipConfigRepo, p.EventBus)); err != nil {
		return err
	}
	getInternH := getinternship.NewHandler(p.InternshipConfigRepo)
	if err := p.QryBus.Register(&getinternship.GetInternshipConfigQuery{}, adaptQueryHandler(getInternH.Handle)); err != nil {
		return err
	}

	// CharacterTestConfig (program_karir)
	if err := p.CmdBus.Register(&upsertchartest.UpsertCharacterTestConfigCommand{},
		upsertchartest.NewHandler(p.CharTestConfigRepo, p.CharTestConfigRepo, p.EventBus)); err != nil {
		return err
	}
	getCharTestH := getchartest.NewHandler(p.CharTestConfigRepo)
	if err := p.QryBus.Register(&getchartest.GetCharacterTestConfigQuery{}, adaptQueryHandler(getCharTestH.Handle)); err != nil {
		return err
	}

	// TalentPool
	if err := p.CmdBus.Register(&submitresult.SubmitTestResultCommand{},
		submitresult.NewHandler(p.TalentPoolRepo, p.TalentPoolRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatetalentpool.UpdateTalentPoolStatusCommand{},
		updatetalentpool.NewHandler(p.TalentPoolRepo, p.TalentPoolRepo, p.EventBus)); err != nil {
		return err
	}
	getTPH := gettalentpool.NewHandler(p.TalentPoolRepo)
	if err := p.QryBus.Register(&gettalentpool.GetTalentPoolQuery{}, adaptQueryHandler(getTPH.Handle)); err != nil {
		return err
	}
	listTPH := listtalentpool.NewHandler(p.TalentPoolRepo)
	if err := p.QryBus.Register(&listtalentpool.ListTalentPoolQuery{}, adaptQueryHandler(listTPH.Handle)); err != nil {
		return err
	}

	// ===== LEAD =====

	// Lead
	if err := p.CmdBus.Register(&createlead.CreateLeadCommand{},
		createlead.NewHandler(p.LeadRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatelead.UpdateLeadCommand{},
		updatelead.NewHandler(p.LeadRepo, p.LeadRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletelead.DeleteLeadCommand{},
		deletelead.NewHandler(p.LeadRepo, p.EventBus)); err != nil {
		return err
	}
	getLeadH := getlead.NewHandler(p.LeadRepo)
	if err := p.QryBus.Register(&getlead.GetLeadQuery{}, adaptQueryHandler(getLeadH.Handle)); err != nil {
		return err
	}
	listLeadH := listlead.NewHandler(p.LeadRepo)
	if err := p.QryBus.Register(&listlead.ListLeadQuery{}, adaptQueryHandler(listLeadH.Handle)); err != nil {
		return err
	}

	// ===== BIZ DEV =====

	// Partner
	if err := p.CmdBus.Register(&createpartner.CreatePartnerCommand{},
		createpartner.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createmou.CreateMOUCommand{},
		createmou.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	listPartnersH := listpartners.NewHandler(p.PartnerRepo)
	if err := p.QryBus.Register(&listpartners.ListPartnersQuery{}, adaptQueryHandler(listPartnersH.Handle)); err != nil {
		return err
	}
	getPartnerH := getpartner.NewHandler(p.PartnerRepo)
	if err := p.QryBus.Register(&getpartner.GetPartnerQuery{}, adaptQueryHandler(getPartnerH.Handle)); err != nil {
		return err
	}

	// Branch
	if err := p.CmdBus.Register(&createbranch.CreateBranchCommand{},
		createbranch.NewHandler(p.BranchRepo, p.EventBus)); err != nil {
		return err
	}
	listBranchesH := listbranches.NewHandler(p.BranchRepo)
	if err := p.QryBus.Register(&listbranches.ListBranchesQuery{}, adaptQueryHandler(listBranchesH.Handle)); err != nil {
		return err
	}

	// OKR
	if err := p.CmdBus.Register(&createokrobjective.CreateOkrObjectiveCommand{},
		createokrobjective.NewHandler(p.OkrRepo, p.EventBus)); err != nil {
		return err
	}
	listOkrH := listokr.NewHandler(p.OkrRepo)
	if err := p.QryBus.Register(&listokr.ListOkrQuery{}, adaptQueryHandler(listOkrH.Handle)); err != nil {
		return err
	}

	// Investment
	if err := p.CmdBus.Register(&createinvestmentplan.CreateInvestmentPlanCommand{},
		createinvestmentplan.NewHandler(p.InvestmentRepo, p.EventBus)); err != nil {
		return err
	}
	listInvestmentsH := listinvestments.NewHandler(p.InvestmentRepo)
	if err := p.QryBus.Register(&listinvestments.ListInvestmentPlansQuery{}, adaptQueryHandler(listInvestmentsH.Handle)); err != nil {
		return err
	}

	// Delegation
	if err := p.CmdBus.Register(&createdelegation.CreateDelegationCommand{},
		createdelegation.NewHandler(p.DelegationRepo, p.EventBus)); err != nil {
		return err
	}
	listDelegationsH := listdelegations.NewHandler(p.DelegationRepo)
	if err := p.QryBus.Register(&listdelegations.ListDelegationsQuery{}, adaptQueryHandler(listDelegationsH.Handle)); err != nil {
		return err
	}

	return nil
}

func startServer(lc fx.Lifecycle, r *chi.Mux, cfg *config.Config) {
	server := &http.Server{
		Addr:         ":" + cfg.App.HTTPPort,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			log.Info().Str("port", cfg.App.HTTPPort).Msg("starting HTTP server")
			go func() {
				if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					log.Fatal().Err(err).Msg("HTTP server error")
				}
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			log.Info().Msg("shutting down HTTP server")
			return server.Shutdown(ctx)
		},
	})
}
