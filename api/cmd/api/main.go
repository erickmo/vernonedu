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
	// batch schedule commands
	createbatchschedule "github.com/vernonedu/entrepreneurship-api/internal/command/create_batch_schedule"
	// batch schedule queries
	listbatchschedules "github.com/vernonedu/entrepreneurship-api/internal/query/list_batch_schedules"
	// lead commands
	addcrmlog "github.com/vernonedu/entrepreneurship-api/internal/command/add_crm_log"
	convertleadtostudent "github.com/vernonedu/entrepreneurship-api/internal/command/convert_lead_to_student"
	createlead "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead"
	deletelead "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead"
	updatelead "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead"
	// location commands
	createbuilding "github.com/vernonedu/entrepreneurship-api/internal/command/create_building"
	deletebuilding "github.com/vernonedu/entrepreneurship-api/internal/command/delete_building"
	updatebuilding "github.com/vernonedu/entrepreneurship-api/internal/command/update_building"
	createroom "github.com/vernonedu/entrepreneurship-api/internal/command/create_room"
	deleteroom "github.com/vernonedu/entrepreneurship-api/internal/command/delete_room"
	updateroom "github.com/vernonedu/entrepreneurship-api/internal/command/update_room"
	// approval commands
	createapproval "github.com/vernonedu/entrepreneurship-api/internal/command/create_approval"
	approvestep "github.com/vernonedu/entrepreneurship-api/internal/command/approve_step"
	rejectstep "github.com/vernonedu/entrepreneurship-api/internal/command/reject_step"
	cancelapproval "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_approval"
	// notification commands
	createnotification "github.com/vernonedu/entrepreneurship-api/internal/command/create_notification"
	markallread "github.com/vernonedu/entrepreneurship-api/internal/command/mark_all_notifications_read"
	markread "github.com/vernonedu/entrepreneurship-api/internal/command/mark_notification_read"
	// notification queries
	getunreadcount "github.com/vernonedu/entrepreneurship-api/internal/query/get_unread_count"
	listnotifications "github.com/vernonedu/entrepreneurship-api/internal/query/list_notifications"
	// event handlers
	"github.com/vernonedu/entrepreneurship-api/internal/eventhandler"
	// accounting commands
	createtransaction "github.com/vernonedu/entrepreneurship-api/internal/command/create_transaction"
	cancelinvoice   "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_invoice"
	createinvoice   "github.com/vernonedu/entrepreneurship-api/internal/command/create_invoice"
	markpaid        "github.com/vernonedu/entrepreneurship-api/internal/command/mark_invoice_paid"
	sendinvoice     "github.com/vernonedu/entrepreneurship-api/internal/command/send_invoice"
	updateinvoicestatus "github.com/vernonedu/entrepreneurship-api/internal/command/update_invoice_status"
	// finance commands
	createfinanceaccount    "github.com/vernonedu/entrepreneurship-api/internal/command/create_finance_account"
	updatefinanceaccount    "github.com/vernonedu/entrepreneurship-api/internal/command/update_finance_account"
	createfinancetransaction "github.com/vernonedu/entrepreneurship-api/internal/command/create_finance_transaction"
	createjournalentry      "github.com/vernonedu/entrepreneurship-api/internal/command/create_journal_entry"
	// payable commands
	approvepayable  "github.com/vernonedu/entrepreneurship-api/internal/command/approve_payable"
	cancelpayable   "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_payable"
	createpayable   "github.com/vernonedu/entrepreneurship-api/internal/command/create_payable"
	markpayablepaid "github.com/vernonedu/entrepreneurship-api/internal/command/mark_payable_paid"
	// payable queries
	getpayable      "github.com/vernonedu/entrepreneurship-api/internal/query/get_payable"
	getpayablestats "github.com/vernonedu/entrepreneurship-api/internal/query/get_payable_stats"
	listpayables    "github.com/vernonedu/entrepreneurship-api/internal/query/list_payables"
	// biz-dev commands
	createpartner "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner"
	createmou "github.com/vernonedu/entrepreneurship-api/internal/command/create_mou"
	createpartnergroup "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner_group"
	updatepartnergroup "github.com/vernonedu/entrepreneurship-api/internal/command/update_partner_group"
	updatepartner "github.com/vernonedu/entrepreneurship-api/internal/command/update_partner"
	deletepartner "github.com/vernonedu/entrepreneurship-api/internal/command/delete_partner"
	updatemou "github.com/vernonedu/entrepreneurship-api/internal/command/update_mou"
	deletemou "github.com/vernonedu/entrepreneurship-api/internal/command/delete_mou"
	createbranch "github.com/vernonedu/entrepreneurship-api/internal/command/create_branch"
	createokrobjective "github.com/vernonedu/entrepreneurship-api/internal/command/create_okr_objective"
	createinvestmentplan "github.com/vernonedu/entrepreneurship-api/internal/command/create_investment_plan"
	acceptdelegation   "github.com/vernonedu/entrepreneurship-api/internal/command/accept_delegation"
	canceldelegation   "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_delegation"
	completedelegation "github.com/vernonedu/entrepreneurship-api/internal/command/complete_delegation"
	createdelegation   "github.com/vernonedu/entrepreneurship-api/internal/command/create_delegation"
	updatedelegation   "github.com/vernonedu/entrepreneurship-api/internal/command/update_delegation"
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
	// approval queries
	getapproval "github.com/vernonedu/entrepreneurship-api/internal/query/get_approval"
	listapprovals "github.com/vernonedu/entrepreneurship-api/internal/query/list_approvals"
	// lead queries
	getlead "github.com/vernonedu/entrepreneurship-api/internal/query/get_lead"
	listcrmlogs "github.com/vernonedu/entrepreneurship-api/internal/query/list_crm_logs"
	listlead "github.com/vernonedu/entrepreneurship-api/internal/query/list_lead"
	// location queries
	checkroomavailability "github.com/vernonedu/entrepreneurship-api/internal/query/check_room_availability"
	getbuilding "github.com/vernonedu/entrepreneurship-api/internal/query/get_building"
	getroom "github.com/vernonedu/entrepreneurship-api/internal/query/get_room"
	listbuildings "github.com/vernonedu/entrepreneurship-api/internal/query/list_buildings"
	listrooms "github.com/vernonedu/entrepreneurship-api/internal/query/list_rooms"
	// accounting queries
	getinvoice      "github.com/vernonedu/entrepreneurship-api/internal/query/get_invoice"
	getinvoicestats "github.com/vernonedu/entrepreneurship-api/internal/query/get_invoice_stats"
	getaccountingstats "github.com/vernonedu/entrepreneurship-api/internal/query/get_accounting_stats"
	getbatchprofitability "github.com/vernonedu/entrepreneurship-api/internal/query/get_batch_profitability"
	getbudgetvsactual "github.com/vernonedu/entrepreneurship-api/internal/query/get_budget_vs_actual"
	getcashforecast "github.com/vernonedu/entrepreneurship-api/internal/query/get_cash_forecast"
	getcostanalysis "github.com/vernonedu/entrepreneurship-api/internal/query/get_cost_analysis"
	getfinancialalerts "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_alerts"
	getfinancialratios "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_ratios"
	getfinancialsuggestions "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_suggestions"
	getrevenueanalysis "github.com/vernonedu/entrepreneurship-api/internal/query/get_revenue_analysis"
	listcoa "github.com/vernonedu/entrepreneurship-api/internal/query/list_coa"
	listinvoices "github.com/vernonedu/entrepreneurship-api/internal/query/list_invoices"
	listtransactions "github.com/vernonedu/entrepreneurship-api/internal/query/list_transactions"
	// finance queries
	listfinanceaccounts    "github.com/vernonedu/entrepreneurship-api/internal/query/list_finance_accounts"
	getfinanceaccount      "github.com/vernonedu/entrepreneurship-api/internal/query/get_finance_account"
	listfinancetransactions "github.com/vernonedu/entrepreneurship-api/internal/query/list_finance_transactions"
	listjournalentries     "github.com/vernonedu/entrepreneurship-api/internal/query/list_journal_entries"
	// biz-dev queries
	listpartners "github.com/vernonedu/entrepreneurship-api/internal/query/list_partners"
	getpartner "github.com/vernonedu/entrepreneurship-api/internal/query/get_partner"
	listpartnergroups "github.com/vernonedu/entrepreneurship-api/internal/query/list_partner_groups"
	listmous "github.com/vernonedu/entrepreneurship-api/internal/query/list_mous"
	listexpiringmous "github.com/vernonedu/entrepreneurship-api/internal/query/list_expiring_mous"
	listbranches "github.com/vernonedu/entrepreneurship-api/internal/query/list_branches"
	listokr "github.com/vernonedu/entrepreneurship-api/internal/query/list_okr"
	listinvestments "github.com/vernonedu/entrepreneurship-api/internal/query/list_investment_plans"
	getdelegation   "github.com/vernonedu/entrepreneurship-api/internal/query/get_delegation"
	listdelegations  "github.com/vernonedu/entrepreneurship-api/internal/query/list_delegations"
	// settings commands
	createholiday    "github.com/vernonedu/entrepreneurship-api/internal/command/create_holiday"
	deleteholiday    "github.com/vernonedu/entrepreneurship-api/internal/command/delete_holiday"
	updatebranch     "github.com/vernonedu/entrepreneurship-api/internal/command/update_branch"
	updatecommissioncfg "github.com/vernonedu/entrepreneurship-api/internal/command/update_commission_config"
	upsertfaclevels  "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_facilitator_levels"
	// settings queries
	getcommissioncfg "github.com/vernonedu/entrepreneurship-api/internal/query/get_commission_config"
	getfaclevels     "github.com/vernonedu/entrepreneurship-api/internal/query/get_facilitator_levels"
	listholidays     "github.com/vernonedu/entrepreneurship-api/internal/query/list_holidays"
	// finance report queries
	getbalancesheet  "github.com/vernonedu/entrepreneurship-api/internal/query/get_balance_sheet"
	getcashflow      "github.com/vernonedu/entrepreneurship-api/internal/query/get_cash_flow"
	getgeneralledger "github.com/vernonedu/entrepreneurship-api/internal/query/get_general_ledger"
	getprofitloss    "github.com/vernonedu/entrepreneurship-api/internal/query/get_profit_loss"
	gettrialbalance  "github.com/vernonedu/entrepreneurship-api/internal/query/get_trial_balance"
	// student app access commands
	grantappaccess  "github.com/vernonedu/entrepreneurship-api/internal/command/grant_app_access"
	revokeappaccess "github.com/vernonedu/entrepreneurship-api/internal/command/revoke_app_access"
	// certificate commands
	createcerttemplate "github.com/vernonedu/entrepreneurship-api/internal/command/create_certificate_template"
	updatecerttemplate "github.com/vernonedu/entrepreneurship-api/internal/command/update_certificate_template"
	issuecertificate   "github.com/vernonedu/entrepreneurship-api/internal/command/issue_certificate"
	revokecertificate  "github.com/vernonedu/entrepreneurship-api/internal/command/revoke_certificate"
	// certificate queries
	listcertificates  "github.com/vernonedu/entrepreneurship-api/internal/query/list_certificates"
	getcertificate    "github.com/vernonedu/entrepreneurship-api/internal/query/get_certificate"
	verifycertificate "github.com/vernonedu/entrepreneurship-api/internal/query/verify_certificate"
	// cms commands
	createcmsarticle     "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_article"
	createcmsfaq         "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_faq"
	createcmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/create_cms_testimonial"
	deletecmsarticle     "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_article"
	deletecmsfaq         "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_faq"
	deletecmsmedia       "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_media"
	deletecmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/delete_cms_testimonial"
	updatecmsarticle     "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_article"
	updatecmsfaq         "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_faq"
	updatecmspage        "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_page"
	updatecmstestimonial "github.com/vernonedu/entrepreneurship-api/internal/command/update_cms_testimonial"
	uploadcmsmedia       "github.com/vernonedu/entrepreneurship-api/internal/command/upload_cms_media"
	// cms queries
	getcmsarticle       "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_article"
	getcmspage          "github.com/vernonedu/entrepreneurship-api/internal/query/get_cms_page"
	listcmsarticles     "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_articles"
	listcmsfaq          "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_faq"
	listcmsmedia        "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_media"
	listcmspages        "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_pages"
	listcmstestimonials "github.com/vernonedu/entrepreneurship-api/internal/query/list_cms_testimonials"
	// marketing commands
	createpost       "github.com/vernonedu/entrepreneurship-api/internal/command/create_post"
	updatepost       "github.com/vernonedu/entrepreneurship-api/internal/command/update_post"
	submitposturl    "github.com/vernonedu/entrepreneurship-api/internal/command/submit_post_url"
	deletepost       "github.com/vernonedu/entrepreneurship-api/internal/command/delete_post"
	createpr         "github.com/vernonedu/entrepreneurship-api/internal/command/create_pr"
	updatepr         "github.com/vernonedu/entrepreneurship-api/internal/command/update_pr"
	deletepr         "github.com/vernonedu/entrepreneurship-api/internal/command/delete_pr"
	createrefpartner "github.com/vernonedu/entrepreneurship-api/internal/command/create_referral_partner"
	updaterefpartner "github.com/vernonedu/entrepreneurship-api/internal/command/update_referral_partner"
	// marketing queries
	listposts           "github.com/vernonedu/entrepreneurship-api/internal/query/list_posts"
	listclassdocs       "github.com/vernonedu/entrepreneurship-api/internal/query/list_class_docs"
	listprq             "github.com/vernonedu/entrepreneurship-api/internal/query/list_pr"
	listrefpartners     "github.com/vernonedu/entrepreneurship-api/internal/query/list_referral_partners"
	listreferrals       "github.com/vernonedu/entrepreneurship-api/internal/query/list_referrals"
	getmarketingstats   "github.com/vernonedu/entrepreneurship-api/internal/query/get_marketing_stats"
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
			// Location repositories
			func(db *sqlx.DB) *database.BuildingRepository {
				return database.NewBuildingRepository(db)
			},
			func(db *sqlx.DB) *database.RoomRepository {
				return database.NewRoomRepository(db)
			},
			// Payable repository
			func(db *sqlx.DB) *database.PayableRepository {
				return database.NewPayableRepository(db)
			},
			// Accounting repositories
			func(db *sqlx.DB) *database.AccountingTransactionRepository {
				return database.NewAccountingTransactionRepository(db)
			},
			func(db *sqlx.DB) *database.AccountingInvoiceRepository {
				return database.NewAccountingInvoiceRepository(db)
			},
			func(db *sqlx.DB) *database.CoaRepository {
				return database.NewCoaRepository(db)
			},
			func(db *sqlx.DB) *database.AccountingAnalysisRepository {
				return database.NewAccountingAnalysisRepository(db)
			},
			// Finance repositories
			func(db *sqlx.DB) *database.FinanceAccountRepository {
				return database.NewFinanceAccountRepository(db)
			},
			func(db *sqlx.DB) *database.FinanceTransactionRepository {
				return database.NewFinanceTransactionRepository(db)
			},
			func(db *sqlx.DB) *database.FinanceJournalRepository {
				return database.NewFinanceJournalRepository(db)
			},
			newFinanceHTTPHandler,
			// Approval repository
			func(db *sqlx.DB) *database.ApprovalRepository {
				return database.NewApprovalRepository(db)
			},
			// Notification repository
			func(db *sqlx.DB) *database.NotificationRepository {
				return database.NewNotificationRepository(db)
			},
			// Certificate repository
			func(db *sqlx.DB) *database.CertificateRepository {
				return database.NewCertificateRepository(db)
			},
			// CMS repository
			func(db *sqlx.DB) *database.CmsRepository {
				return database.NewCmsRepository(db)
			},
			// BatchSchedule repository
			func(db *sqlx.DB) *database.BatchScheduleRepository {
				return database.NewBatchScheduleRepository(db)
			},
			// Marketing repository
			func(db *sqlx.DB) *database.MarketingRepository {
				return database.NewMarketingRepository(db)
			},
			// Settings repository
			func(db *sqlx.DB) *database.SettingsRepository {
				return database.NewSettingsRepository(db)
			},
			func(r *database.SettingsRepository) *database.CommissionRepo {
				return database.NewCommissionRepo(r)
			},
			func(r *database.SettingsRepository) *database.FacilitatorRepo {
				return database.NewFacilitatorRepo(r)
			},
			func(r *database.SettingsRepository) *database.HolidayRepo {
				return database.NewHolidayRepo(r)
			},
			// Report repository
			func(db *sqlx.DB) *database.ReportRepository {
				return database.NewReportRepository(db)
			},
			// Student App Access repository
			func(db *sqlx.DB) *database.StudentAppAccessRepository {
				return database.NewStudentAppAccessRepository(db)
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
			// Location HTTP handler
			newLocationHTTPHandler,
			// BizDev HTTP handlers
			newPartnerHTTPHandler,
			newBranchHTTPHandler,
			newOkrHTTPHandler,
			newInvestmentHTTPHandler,
			newDelegationHTTPHandler,

			// Approval HTTP handler
			newApprovalHTTPHandler,
			// Notification HTTP handler
			newNotificationHTTPHandler,

			// Payable HTTP handler
			newPayableHTTPHandler,
			// Accounting HTTP handler
			newAccountingHTTPHandler,

			// Curriculum HTTP handlers
			newMasterCourseHTTPHandler,
			newCourseTypeHTTPHandler,
			newCourseVersionHTTPHandler,
			newCourseModuleHTTPHandler,
			newProgramKarirHTTPHandler,
			newTalentPoolHTTPHandler,

			// Certificate HTTP handler
			newCertificateHTTPHandler,

			// CMS HTTP handler
			newCmsHTTPHandler,
			// Public HTTP handler
			newPublicHTTPHandler,
			// Marketing HTTP handler
			newMarketingHTTPHandler,
			// Finance Report HTTP handler
			newFinanceReportHTTPHandler,

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

func newLocationHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.LocationHandler {
	return httphandler.NewLocationHandler(cmdBus, qryBus)
}

func newPayableHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.PayableHandler {
	return httphandler.NewPayableHandler(cmdBus, qryBus)
}

func newAccountingHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.AccountingHandler {
	return httphandler.NewAccountingHandler(cmdBus, qryBus)
}

func newApprovalHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.ApprovalHandler {
	return httphandler.NewApprovalHandler(cmdBus, qryBus)
}

func newNotificationHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.NotificationHandler {
	return httphandler.NewNotificationHandler(cmdBus, qryBus)
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

func newSettingsHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.SettingsHandler {
	return httphandler.NewSettingsHandler(cmdBus, qryBus)
}

func newCertificateHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CertificateHandler {
	return httphandler.NewCertificateHandler(cmdBus, qryBus)
}

func newCmsHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.CmsHandler {
	return httphandler.NewCmsHandler(cmdBus, qryBus)
}

func newPublicHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.PublicHandler {
	return httphandler.NewPublicHandler(cmdBus, qryBus)
}

func newMarketingHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.MarketingHandler {
	return httphandler.NewMarketingHandler(cmdBus, qryBus)
}

func newFinanceReportHTTPHandler(qryBus querybus.QueryBus) *httphandler.FinanceReportHandler {
	return httphandler.NewFinanceReportHandler(qryBus)
}

func newFinanceHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *httphandler.FinanceHandler {
	return httphandler.NewFinanceHandler(cmdBus, qryBus)
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
	locationHandler *httphandler.LocationHandler,
	partnerHandler *httphandler.PartnerHandler,
	branchHandler *httphandler.BranchHandler,
	okrHandler *httphandler.OkrHandler,
	investmentHandler *httphandler.InvestmentHandler,
	delegationHandler *httphandler.DelegationHTTPHandler,
	payableHandler *httphandler.PayableHandler,
	accountingHandler *httphandler.AccountingHandler,
	approvalHandler *httphandler.ApprovalHandler,
	notificationHandler *httphandler.NotificationHandler,
	settingsHandler *httphandler.SettingsHandler,
	certHandler *httphandler.CertificateHandler,
	cmsHandler *httphandler.CmsHandler,
	publicHandler *httphandler.PublicHandler,
	financeReportHandler *httphandler.FinanceReportHandler,
	financeHandler *httphandler.FinanceHandler,
	marketingHandler *httphandler.MarketingHandler,
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
		// Approval routes
		httphandler.RegisterApprovalRoutes(approvalHandler, r)
		// Notification routes
		httphandler.RegisterNotificationRoutes(notificationHandler, r)
		// Location routes
		httphandler.RegisterLocationRoutes(locationHandler, r)
		// Payable routes
		httphandler.RegisterPayableRoutes(payableHandler, r)
		// Accounting routes
		httphandler.RegisterAccountingRoutes(accountingHandler, r)
		// BizDev routes
		httphandler.RegisterPartnerRoutes(partnerHandler, r)
		httphandler.RegisterBranchRoutes(branchHandler, r)
		httphandler.RegisterOkrRoutes(okrHandler, r)
		httphandler.RegisterInvestmentRoutes(investmentHandler, r)
		httphandler.RegisterDelegationRoutes(delegationHandler, r)
		// Settings routes
		httphandler.RegisterSettingsRoutes(settingsHandler, r)
		// Certificate routes (protected)
		httphandler.RegisterCertificateRoutes(certHandler, r)
		// CMS routes
		httphandler.RegisterCmsRoutes(cmsHandler, r)
		// Finance Report routes
		httphandler.RegisterFinanceReportRoutes(financeReportHandler, r)
		// Finance routes (CoA, Transactions, Journal)
		httphandler.RegisterFinanceRoutes(financeHandler, r)
		// Marketing routes
		httphandler.RegisterMarketingRoutes(marketingHandler, r)
	})

	// Certificate public routes (no auth)
	httphandler.RegisterCertificatePublicRoutes(certHandler, r)

	// Public routes (no auth — consumed by app-website)
	httphandler.RegisterPublicRoutes(publicHandler, r)

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
	// BatchSchedule repository
	BatchScheduleRepo *database.BatchScheduleRepository
	// BizDev repositories
	PartnerRepo    *database.PartnerRepository
	BranchRepo     *database.BranchRepository
	OkrRepo        *database.OkrRepository
	InvestmentRepo *database.InvestmentRepository
	DelegationRepo *database.DelegationRepository
	// Lead repository
	LeadRepo *database.LeadRepository
	// Location repositories
	BuildingRepo *database.BuildingRepository
	RoomRepo     *database.RoomRepository
	// Payable repository
	PayableRepo *database.PayableRepository
	// Accounting repositories
	AccountingTransactionRepo *database.AccountingTransactionRepository
	AccountingInvoiceRepo     *database.AccountingInvoiceRepository
	CoaRepo                   *database.CoaRepository
	AccountingAnalysisRepo    *database.AccountingAnalysisRepository
	// Finance repositories
	FinanceAccountRepo     *database.FinanceAccountRepository
	FinanceTransactionRepo *database.FinanceTransactionRepository
	FinanceJournalRepo     *database.FinanceJournalRepository
	// Approval repository
	ApprovalRepo     *database.ApprovalRepository
	NotificationRepo *database.NotificationRepository
	// Certificate repository
	CertRepo         *database.CertificateRepository
	// CMS repository
	CmsRepo          *database.CmsRepository
	// Marketing repository
	MarketingRepo    *database.MarketingRepository
	// Settings repositories
	CommissionRepo  *database.CommissionRepo
	FacilitatorRepo *database.FacilitatorRepo
	HolidayRepo     *database.HolidayRepo
	ReportRepo      *database.ReportRepository
	AppAccessRepo   *database.StudentAppAccessRepository
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
		createcoursebatch.NewHandler(p.CourseBatchRepo, p.EventBus, p.ApprovalRepo)); err != nil {
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

	// BatchSchedule
	if err := p.CmdBus.Register(&createbatchschedule.CreateBatchScheduleCommand{},
		createbatchschedule.NewHandler(p.BatchScheduleRepo, p.BatchScheduleRepo)); err != nil {
		return err
	}
	listBatchSchedulesH := listbatchschedules.NewHandler(p.BatchScheduleRepo)
	if err := p.QryBus.Register(&listbatchschedules.ListBatchSchedulesQuery{}, adaptQueryHandler(listBatchSchedulesH.Handle)); err != nil {
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

	// ===== LOCATION =====

	// Building
	if err := p.CmdBus.Register(&createbuilding.CreateBuildingCommand{},
		createbuilding.NewHandler(p.BuildingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatebuilding.UpdateBuildingCommand{},
		updatebuilding.NewHandler(p.BuildingRepo, p.BuildingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletebuilding.DeleteBuildingCommand{},
		deletebuilding.NewHandler(p.BuildingRepo, p.EventBus)); err != nil {
		return err
	}
	getBuildingH := getbuilding.NewHandler(p.BuildingRepo)
	if err := p.QryBus.Register(&getbuilding.GetBuildingQuery{}, adaptQueryHandler(getBuildingH.Handle)); err != nil {
		return err
	}
	listBuildingsH := listbuildings.NewHandler(p.BuildingRepo)
	if err := p.QryBus.Register(&listbuildings.ListBuildingsQuery{}, adaptQueryHandler(listBuildingsH.Handle)); err != nil {
		return err
	}

	// Room
	if err := p.CmdBus.Register(&createroom.CreateRoomCommand{},
		createroom.NewHandler(p.RoomRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateroom.UpdateRoomCommand{},
		updateroom.NewHandler(p.RoomRepo, p.RoomRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteroom.DeleteRoomCommand{},
		deleteroom.NewHandler(p.RoomRepo, p.EventBus)); err != nil {
		return err
	}
	getRoomH := getroom.NewHandler(p.RoomRepo)
	if err := p.QryBus.Register(&getroom.GetRoomQuery{}, adaptQueryHandler(getRoomH.Handle)); err != nil {
		return err
	}
	listRoomsH := listrooms.NewHandler(p.RoomRepo)
	if err := p.QryBus.Register(&listrooms.ListRoomsQuery{}, adaptQueryHandler(listRoomsH.Handle)); err != nil {
		return err
	}
	checkAvailabilityH := checkroomavailability.NewHandler(p.RoomRepo)
	if err := p.QryBus.Register(&checkroomavailability.CheckRoomAvailabilityQuery{}, adaptQueryHandler(checkAvailabilityH.Handle)); err != nil {
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
	if err := p.CmdBus.Register(&addcrmlog.AddCrmLogCommand{},
		addcrmlog.NewHandler(p.LeadRepo, p.LeadRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&convertleadtostudent.ConvertLeadToStudentCommand{},
		convertleadtostudent.NewHandler(p.LeadRepo, p.LeadRepo, p.StudentRepo, p.EventBus)); err != nil {
		return err
	}
	listCrmLogsH := listcrmlogs.NewHandler(p.LeadRepo)
	if err := p.QryBus.Register(&listcrmlogs.ListCrmLogsQuery{}, adaptQueryHandler(listCrmLogsH.Handle)); err != nil {
		return err
	}

	// ===== BIZ DEV =====

	// Partner
	if err := p.CmdBus.Register(&createpartner.CreatePartnerCommand{},
		createpartner.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatepartner.UpdatePartnerCommand{},
		updatepartner.NewHandler(p.PartnerRepo, p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletepartner.DeletePartnerCommand{},
		deletepartner.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createpartnergroup.CreatePartnerGroupCommand{},
		createpartnergroup.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatepartnergroup.UpdatePartnerGroupCommand{},
		updatepartnergroup.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createmou.CreateMOUCommand{},
		createmou.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatemou.UpdateMOUCommand{},
		updatemou.NewHandler(p.PartnerRepo, p.PartnerRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletemou.DeleteMOUCommand{},
		deletemou.NewHandler(p.PartnerRepo, p.EventBus)); err != nil {
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
	listPartnerGroupsH := listpartnergroups.NewHandler(p.PartnerRepo)
	if err := p.QryBus.Register(&listpartnergroups.ListPartnerGroupsQuery{}, adaptQueryHandler(listPartnerGroupsH.Handle)); err != nil {
		return err
	}
	listMOUsH := listmous.NewHandler(p.PartnerRepo)
	if err := p.QryBus.Register(&listmous.ListMOUsQuery{}, adaptQueryHandler(listMOUsH.Handle)); err != nil {
		return err
	}
	listExpiringMOUsH := listexpiringmous.NewHandler(p.PartnerRepo)
	if err := p.QryBus.Register(&listexpiringmous.ListExpiringMOUsQuery{}, adaptQueryHandler(listExpiringMOUsH.Handle)); err != nil {
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
	if err := p.CmdBus.Register(&acceptdelegation.AcceptDelegationCommand{},
		acceptdelegation.NewHandler(p.DelegationRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&completedelegation.CompleteDelegationCommand{},
		completedelegation.NewHandler(p.DelegationRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&canceldelegation.CancelDelegationCommand{},
		canceldelegation.NewHandler(p.DelegationRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatedelegation.UpdateDelegationCommand{},
		updatedelegation.NewHandler(p.DelegationRepo, p.EventBus)); err != nil {
		return err
	}
	listDelegationsH := listdelegations.NewHandler(p.DelegationRepo)
	if err := p.QryBus.Register(&listdelegations.ListDelegationsQuery{}, adaptQueryHandler(listDelegationsH.Handle)); err != nil {
		return err
	}
	getDelegationH := getdelegation.NewHandler(p.DelegationRepo)
	if err := p.QryBus.Register(&getdelegation.GetDelegationQuery{}, adaptQueryHandler(getDelegationH.Handle)); err != nil {
		return err
	}

	// ===== ACCOUNTING =====

	// Transaction
	if err := p.CmdBus.Register(&createtransaction.CreateTransactionCommand{},
		createtransaction.NewHandler(p.AccountingTransactionRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updateinvoicestatus.UpdateInvoiceStatusCommand{},
		updateinvoicestatus.NewHandler(p.AccountingInvoiceRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createinvoice.CreateInvoiceCommand{},
		createinvoice.NewHandler(p.AccountingInvoiceRepo, p.AccountingTransactionRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&markpaid.MarkInvoicePaidCommand{},
		markpaid.NewHandler(p.AccountingInvoiceRepo, p.AccountingInvoiceRepo, p.AccountingTransactionRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&cancelinvoice.CancelInvoiceCommand{},
		cancelinvoice.NewHandler(p.AccountingInvoiceRepo, p.AccountingInvoiceRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&sendinvoice.SendInvoiceCommand{},
		sendinvoice.NewHandler(p.AccountingInvoiceRepo, p.AccountingInvoiceRepo, p.EventBus)); err != nil {
		return err
	}

	getStatsH := getaccountingstats.NewHandler(p.AccountingTransactionRepo)
	if err := p.QryBus.Register(&getaccountingstats.GetAccountingStatsQuery{}, adaptQueryHandler(getStatsH.Handle)); err != nil {
		return err
	}
	listTransactionsH := listtransactions.NewHandler(p.AccountingTransactionRepo)
	if err := p.QryBus.Register(&listtransactions.ListTransactionsQuery{}, adaptQueryHandler(listTransactionsH.Handle)); err != nil {
		return err
	}
	listInvoicesH := listinvoices.NewHandler(p.AccountingInvoiceRepo)
	if err := p.QryBus.Register(&listinvoices.ListInvoicesQuery{}, adaptQueryHandler(listInvoicesH.Handle)); err != nil {
		return err
	}
	getInvoiceH := getinvoice.NewHandler(p.AccountingInvoiceRepo)
	if err := p.QryBus.Register(&getinvoice.GetInvoiceQuery{}, adaptQueryHandler(getInvoiceH.Handle)); err != nil {
		return err
	}
	getInvoiceStatsH := getinvoicestats.NewHandler(p.AccountingInvoiceRepo)
	if err := p.QryBus.Register(&getinvoicestats.GetInvoiceStatsQuery{}, adaptQueryHandler(getInvoiceStatsH.Handle)); err != nil {
		return err
	}
	listCoaH := listcoa.NewHandler(p.CoaRepo)
	if err := p.QryBus.Register(&listcoa.ListCoaQuery{}, adaptQueryHandler(listCoaH.Handle)); err != nil {
		return err
	}
	getBudgetH := getbudgetvsactual.NewHandler(p.AccountingTransactionRepo)
	if err := p.QryBus.Register(&getbudgetvsactual.GetBudgetVsActualQuery{}, adaptQueryHandler(getBudgetH.Handle)); err != nil {
		return err
	}

	// Financial Analysis queries
	getRatiosH := getfinancialratios.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getfinancialratios.GetFinancialRatiosQuery{}, adaptQueryHandler(getRatiosH.Handle)); err != nil {
		return err
	}
	getRevenueH := getrevenueanalysis.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getrevenueanalysis.GetRevenueAnalysisQuery{}, adaptQueryHandler(getRevenueH.Handle)); err != nil {
		return err
	}
	getCostH := getcostanalysis.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getcostanalysis.GetCostAnalysisQuery{}, adaptQueryHandler(getCostH.Handle)); err != nil {
		return err
	}
	getBatchProfitH := getbatchprofitability.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getbatchprofitability.GetBatchProfitabilityQuery{}, adaptQueryHandler(getBatchProfitH.Handle)); err != nil {
		return err
	}
	getCashForecastH := getcashforecast.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getcashforecast.GetCashForecastQuery{}, adaptQueryHandler(getCashForecastH.Handle)); err != nil {
		return err
	}
	getAlertsH := getfinancialalerts.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getfinancialalerts.GetFinancialAlertsQuery{}, adaptQueryHandler(getAlertsH.Handle)); err != nil {
		return err
	}
	getSuggestionsH := getfinancialsuggestions.NewHandler(p.AccountingAnalysisRepo)
	if err := p.QryBus.Register(&getfinancialsuggestions.GetFinancialSuggestionsQuery{}, adaptQueryHandler(getSuggestionsH.Handle)); err != nil {
		return err
	}

	// ===== FINANCE =====

	// Finance Account
	if err := p.CmdBus.Register(&createfinanceaccount.CreateFinanceAccountCommand{},
		createfinanceaccount.NewHandler(p.FinanceAccountRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatefinanceaccount.UpdateFinanceAccountCommand{},
		updatefinanceaccount.NewHandler(p.FinanceAccountRepo, p.FinanceAccountRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createfinancetransaction.CreateFinanceTransactionCommand{},
		createfinancetransaction.NewHandler(p.FinanceTransactionRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createjournalentry.CreateJournalEntryCommand{},
		createjournalentry.NewHandler(p.FinanceJournalRepo, p.EventBus)); err != nil {
		return err
	}

	listFinanceAccountsH := listfinanceaccounts.NewHandler(p.FinanceAccountRepo)
	if err := p.QryBus.Register(&listfinanceaccounts.ListFinanceAccountsQuery{}, adaptQueryHandler(listFinanceAccountsH.Handle)); err != nil {
		return err
	}
	getFinanceAccountH := getfinanceaccount.NewHandler(p.FinanceAccountRepo)
	if err := p.QryBus.Register(&getfinanceaccount.GetFinanceAccountQuery{}, adaptQueryHandler(getFinanceAccountH.Handle)); err != nil {
		return err
	}
	listFinanceTxH := listfinancetransactions.NewHandler(p.FinanceTransactionRepo)
	if err := p.QryBus.Register(&listfinancetransactions.ListFinanceTransactionsQuery{}, adaptQueryHandler(listFinanceTxH.Handle)); err != nil {
		return err
	}
	listJournalH := listjournalentries.NewHandler(p.FinanceJournalRepo)
	if err := p.QryBus.Register(&listjournalentries.ListJournalEntriesQuery{}, adaptQueryHandler(listJournalH.Handle)); err != nil {
		return err
	}

	// ===== APPROVAL =====

	if err := p.CmdBus.Register(&createapproval.CreateApprovalCommand{},
		createapproval.NewHandler(p.ApprovalRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&approvestep.ApproveStepCommand{},
		approvestep.NewHandler(p.ApprovalRepo, p.ApprovalRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&rejectstep.RejectStepCommand{},
		rejectstep.NewHandler(p.ApprovalRepo, p.ApprovalRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&cancelapproval.CancelApprovalCommand{},
		cancelapproval.NewHandler(p.ApprovalRepo, p.ApprovalRepo, p.EventBus)); err != nil {
		return err
	}

	listApprovalsH := listapprovals.NewHandler(p.ApprovalRepo)
	if err := p.QryBus.Register(&listapprovals.ListApprovalsQuery{}, adaptQueryHandler(listApprovalsH.Handle)); err != nil {
		return err
	}
	getApprovalH := getapproval.NewHandler(p.ApprovalRepo)
	if err := p.QryBus.Register(&getapproval.GetApprovalQuery{}, adaptQueryHandler(getApprovalH.Handle)); err != nil {
		return err
	}

	// ===== NOTIFICATIONS =====

	if err := p.CmdBus.Register(&createnotification.CreateNotificationCommand{},
		createnotification.NewHandler(p.NotificationRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&markread.MarkNotificationReadCommand{},
		markread.NewHandler(p.NotificationRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&markallread.MarkAllNotificationsReadCommand{},
		markallread.NewHandler(p.NotificationRepo, p.EventBus)); err != nil {
		return err
	}

	listNotificationsH := listnotifications.NewHandler(p.NotificationRepo)
	if err := p.QryBus.Register(&listnotifications.ListNotificationsQuery{}, adaptQueryHandler(listNotificationsH.Handle)); err != nil {
		return err
	}
	getUnreadCountH := getunreadcount.NewHandler(p.NotificationRepo)
	if err := p.QryBus.Register(&getunreadcount.GetUnreadCountQuery{}, adaptQueryHandler(getUnreadCountH.Handle)); err != nil {
		return err
	}

	// Subscribe approval notification event handlers
	approvalNotifH := eventhandler.NewApprovalNotificationHandler(p.NotificationRepo)
	ctxBg := context.Background()
	if err := p.EventBus.Subscribe(ctxBg, "ApprovalCreated", approvalNotifH.OnApprovalCreated); err != nil {
		return err
	}
	if err := p.EventBus.Subscribe(ctxBg, "ApprovalStepApproved", approvalNotifH.OnApprovalStepApproved); err != nil {
		return err
	}
	if err := p.EventBus.Subscribe(ctxBg, "ApprovalRejected", approvalNotifH.OnApprovalRejected); err != nil {
		return err
	}

	// Subscribe invoice event handlers
	invoiceEvtH := eventhandler.NewInvoiceEventHandler(
		p.AccountingInvoiceRepo,
		p.CourseBatchRepo,
		p.AccountingTransactionRepo,
		p.EnrollmentRepo,
	)
	if err := p.EventBus.Subscribe(ctxBg, "EnrollmentCreated", invoiceEvtH.OnEnrollmentCreated); err != nil {
		return err
	}

	// Subscribe MOU expiry notification handler (no fixed recipient IDs at startup;
	// pass empty slice — actual user resolution happens per-notification in production).
	mouExpiryH := eventhandler.NewMouExpiryHandler(p.NotificationRepo, nil)
	if err := p.EventBus.Subscribe(ctxBg, "MouExpiring", mouExpiryH.OnMouExpiring); err != nil {
		return err
	}

	// ===== SETTINGS =====

	// Commission config
	if err := p.CmdBus.Register(&updatecommissioncfg.UpdateCommissionConfigCommand{},
		updatecommissioncfg.NewHandler(p.CommissionRepo)); err != nil {
		return err
	}
	getCommissionH := getcommissioncfg.NewHandler(p.CommissionRepo)
	if err := p.QryBus.Register(&getcommissioncfg.GetCommissionConfigQuery{}, adaptQueryHandler(getCommissionH.Handle)); err != nil {
		return err
	}

	// Facilitator levels
	if err := p.CmdBus.Register(&upsertfaclevels.UpsertFacilitatorLevelsCommand{},
		upsertfaclevels.NewHandler(p.FacilitatorRepo)); err != nil {
		return err
	}
	getFacLevelsH := getfaclevels.NewHandler(p.FacilitatorRepo)
	if err := p.QryBus.Register(&getfaclevels.GetFacilitatorLevelsQuery{}, adaptQueryHandler(getFacLevelsH.Handle)); err != nil {
		return err
	}

	// Holidays
	if err := p.CmdBus.Register(&createholiday.CreateHolidayCommand{},
		createholiday.NewHandler(p.HolidayRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deleteholiday.DeleteHolidayCommand{},
		deleteholiday.NewHandler(p.HolidayRepo)); err != nil {
		return err
	}
	listHolidaysH := listholidays.NewHandler(p.HolidayRepo)
	if err := p.QryBus.Register(&listholidays.ListHolidaysQuery{}, adaptQueryHandler(listHolidaysH.Handle)); err != nil {
		return err
	}

	// Branch update (settings)
	if err := p.CmdBus.Register(&updatebranch.UpdateBranchCommand{},
		updatebranch.NewHandler(p.BranchRepo, p.BranchRepo)); err != nil {
		return err
	}

	// ===== CERTIFICATE =====

	if err := p.CmdBus.Register(&createcerttemplate.CreateCertificateTemplateCommand{},
		createcerttemplate.NewHandler(p.CertRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecerttemplate.UpdateCertificateTemplateCommand{},
		updatecerttemplate.NewHandler(p.CertRepo, p.CertRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&issuecertificate.IssueCertificateCommand{},
		issuecertificate.NewHandler(p.CertRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&revokecertificate.RevokeCertificateCommand{},
		revokecertificate.NewHandler(p.CertRepo, p.CertRepo, p.EventBus)); err != nil {
		return err
	}

	listCertsH := listcertificates.NewHandler(p.CertRepo)
	if err := p.QryBus.Register(&listcertificates.ListCertificatesQuery{}, adaptQueryHandler(listCertsH.Handle)); err != nil {
		return err
	}
	getCertH := getcertificate.NewHandler(p.CertRepo)
	if err := p.QryBus.Register(&getcertificate.GetCertificateQuery{}, adaptQueryHandler(getCertH.Handle)); err != nil {
		return err
	}
	verifyCertH := verifycertificate.NewHandler(p.CertRepo)
	if err := p.QryBus.Register(&verifycertificate.VerifyCertificateQuery{}, adaptQueryHandler(verifyCertH.Handle)); err != nil {
		return err
	}

	// ===== CMS =====

	// CMS Page
	if err := p.CmdBus.Register(&updatecmspage.UpdateCmsPageCommand{},
		updatecmspage.NewHandler(p.CmsRepo)); err != nil {
		return err
	}

	// CMS Article
	if err := p.CmdBus.Register(&createcmsarticle.CreateCmsArticleCommand{},
		createcmsarticle.NewHandler(p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecmsarticle.UpdateCmsArticleCommand{},
		updatecmsarticle.NewHandler(p.CmsRepo, p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecmsarticle.DeleteCmsArticleCommand{},
		deletecmsarticle.NewHandler(p.CmsRepo)); err != nil {
		return err
	}

	// CMS Testimonial
	if err := p.CmdBus.Register(&createcmstestimonial.CreateCmsTestimonialCommand{},
		createcmstestimonial.NewHandler(p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecmstestimonial.UpdateCmsTestimonialCommand{},
		updatecmstestimonial.NewHandler(p.CmsRepo, p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecmstestimonial.DeleteCmsTestimonialCommand{},
		deletecmstestimonial.NewHandler(p.CmsRepo)); err != nil {
		return err
	}

	// CMS FAQ
	if err := p.CmdBus.Register(&createcmsfaq.CreateCmsFaqCommand{},
		createcmsfaq.NewHandler(p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatecmsfaq.UpdateCmsFaqCommand{},
		updatecmsfaq.NewHandler(p.CmsRepo, p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecmsfaq.DeleteCmsFaqCommand{},
		deletecmsfaq.NewHandler(p.CmsRepo)); err != nil {
		return err
	}

	// CMS Media
	if err := p.CmdBus.Register(&uploadcmsmedia.UploadCmsMediaCommand{},
		uploadcmsmedia.NewHandler(p.CmsRepo)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletecmsmedia.DeleteCmsMediaCommand{},
		deletecmsmedia.NewHandler(p.CmsRepo)); err != nil {
		return err
	}


	// ===== FINANCE REPORTS =====

	getBalanceSheetH := getbalancesheet.NewHandler(p.ReportRepo)
	if err := p.QryBus.Register(&getbalancesheet.GetBalanceSheetQuery{}, adaptQueryHandler(getBalanceSheetH.Handle)); err != nil {
		return err
	}
	getProfitLossH := getprofitloss.NewHandler(p.ReportRepo)
	if err := p.QryBus.Register(&getprofitloss.GetProfitLossQuery{}, adaptQueryHandler(getProfitLossH.Handle)); err != nil {
		return err
	}
	getCashFlowH := getcashflow.NewHandler(p.ReportRepo)
	if err := p.QryBus.Register(&getcashflow.GetCashFlowQuery{}, adaptQueryHandler(getCashFlowH.Handle)); err != nil {
		return err
	}
	getGeneralLedgerH := getgeneralledger.NewHandler(p.ReportRepo)
	if err := p.QryBus.Register(&getgeneralledger.GetGeneralLedgerQuery{}, adaptQueryHandler(getGeneralLedgerH.Handle)); err != nil {
		return err
	}
	getTrialBalanceH := gettrialbalance.NewHandler(p.ReportRepo)
	if err := p.QryBus.Register(&gettrialbalance.GetTrialBalanceQuery{}, adaptQueryHandler(getTrialBalanceH.Handle)); err != nil {
		return err
	}
	// CMS Queries
	listCmsPagesH := listcmspages.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&listcmspages.ListCmsPagesQuery{}, adaptQueryHandler(listCmsPagesH.Handle)); err != nil {
		return err
	}
	getCmsPageH := getcmspage.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&getcmspage.GetCmsPageQuery{}, adaptQueryHandler(getCmsPageH.Handle)); err != nil {
		return err
	}
	listCmsArticlesH := listcmsarticles.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&listcmsarticles.ListCmsArticlesQuery{}, adaptQueryHandler(listCmsArticlesH.Handle)); err != nil {
		return err
	}
	getCmsArticleH := getcmsarticle.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&getcmsarticle.GetCmsArticleQuery{}, adaptQueryHandler(getCmsArticleH.Handle)); err != nil {
		return err
	}
	listCmsTestimonialsH := listcmstestimonials.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&listcmstestimonials.ListCmsTestimonialsQuery{}, adaptQueryHandler(listCmsTestimonialsH.Handle)); err != nil {
		return err
	}
	listCmsFaqH := listcmsfaq.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&listcmsfaq.ListCmsFaqQuery{}, adaptQueryHandler(listCmsFaqH.Handle)); err != nil {
		return err
	}
	listCmsMediaH := listcmsmedia.NewHandler(p.CmsRepo)
	if err := p.QryBus.Register(&listcmsmedia.ListCmsMediaQuery{}, adaptQueryHandler(listCmsMediaH.Handle)); err != nil {
		return err
	}

	// ===== PAYABLES =====

	if err := p.CmdBus.Register(&createpayable.CreatePayableCommand{},
		createpayable.NewHandler(p.PayableRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&approvepayable.ApprovePayableCommand{},
		approvepayable.NewHandler(p.PayableRepo, p.PayableRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&cancelpayable.CancelPayableCommand{},
		cancelpayable.NewHandler(p.PayableRepo, p.PayableRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&markpayablepaid.MarkPayablePaidCommand{},
		markpayablepaid.NewHandler(p.PayableRepo, p.PayableRepo, p.AccountingTransactionRepo, p.EventBus)); err != nil {
		return err
	}

	getPayableH := getpayable.NewHandler(p.PayableRepo)
	if err := p.QryBus.Register(&getpayable.GetPayableQuery{}, adaptQueryHandler(getPayableH.Handle)); err != nil {
		return err
	}
	listPayablesH := listpayables.NewHandler(p.PayableRepo)
	if err := p.QryBus.Register(&listpayables.ListPayablesQuery{}, adaptQueryHandler(listPayablesH.Handle)); err != nil {
		return err
	}
	getPayableStatsH := getpayablestats.NewHandler(p.PayableRepo)
	if err := p.QryBus.Register(&getpayablestats.GetPayableStatsQuery{}, adaptQueryHandler(getPayableStatsH.Handle)); err != nil {
		return err
	}

	// Subscribe payable event handlers
	payableEvtH := eventhandler.NewPayableEventHandler(
		p.PayableRepo,
		p.CommissionRepo,
		p.FacilitatorRepo,
		p.AccountingTransactionRepo,
	)
	if err := p.EventBus.Subscribe(ctxBg, "AttendanceSubmitted", payableEvtH.OnAttendanceSubmitted); err != nil {
		return err
	}
	if err := p.EventBus.Subscribe(ctxBg, "BatchCompleted", payableEvtH.OnBatchCompleted); err != nil {
		return err
	}
	if err := p.EventBus.Subscribe(ctxBg, "EnrollmentCreated", payableEvtH.OnEnrollmentCreated); err != nil {
		return err
	}

	// ===== MARKETING =====

	if err := p.CmdBus.Register(&createpost.CreatePostCommand{},
		createpost.NewHandler(p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatepost.UpdatePostCommand{},
		updatepost.NewHandler(p.MarketingRepo, p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&submitposturl.SubmitPostUrlCommand{},
		submitposturl.NewHandler(p.MarketingRepo, p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletepost.DeletePostCommand{},
		deletepost.NewHandler(p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createpr.CreatePrCommand{},
		createpr.NewHandler(p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updatepr.UpdatePrCommand{},
		updatepr.NewHandler(p.MarketingRepo, p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&deletepr.DeletePrCommand{},
		deletepr.NewHandler(p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&createrefpartner.CreateReferralPartnerCommand{},
		createrefpartner.NewHandler(p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&updaterefpartner.UpdateReferralPartnerCommand{},
		updaterefpartner.NewHandler(p.MarketingRepo, p.MarketingRepo, p.EventBus)); err != nil {
		return err
	}

	listPostsH := listposts.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&listposts.ListPostsQuery{}, adaptQueryHandler(listPostsH.Handle)); err != nil {
		return err
	}
	listClassDocsH := listclassdocs.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&listclassdocs.ListClassDocsQuery{}, adaptQueryHandler(listClassDocsH.Handle)); err != nil {
		return err
	}
	listPrH := listprq.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&listprq.ListPrQuery{}, adaptQueryHandler(listPrH.Handle)); err != nil {
		return err
	}
	listRefPartnersH := listrefpartners.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&listrefpartners.ListReferralPartnersQuery{}, adaptQueryHandler(listRefPartnersH.Handle)); err != nil {
		return err
	}
	listReferralsH := listreferrals.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&listreferrals.ListReferralsQuery{}, adaptQueryHandler(listReferralsH.Handle)); err != nil {
		return err
	}
	getMarketingStatsH := getmarketingstats.NewHandler(p.MarketingRepo)
	if err := p.QryBus.Register(&getmarketingstats.GetMarketingStatsQuery{}, adaptQueryHandler(getMarketingStatsH.Handle)); err != nil {
		return err
	}

	// Subscribe SessionCompleted event handler
	sessionCompletedH := eventhandler.NewSessionCompletedHandler(p.MarketingRepo, p.HolidayRepo)
	if err := p.EventBus.Subscribe(ctxBg, "SessionCompleted", sessionCompletedH.OnSessionCompleted); err != nil {
		return err
	}

	// Student App Access
	if err := p.CmdBus.Register(&grantappaccess.GrantAppAccessCommand{},
		grantappaccess.NewHandler(p.AppAccessRepo, p.EventBus)); err != nil {
		return err
	}
	revokeH := revokeappaccess.NewHandler(p.AppAccessRepo, p.EventBus)
	if err := p.CmdBus.Register(&revokeappaccess.RevokeAppAccessCommand{}, revokeH); err != nil {
		return err
	}
	if err := p.CmdBus.Register(&revokeappaccess.RevokeAllBatchAccessCommand{}, revokeH); err != nil {
		return err
	}

	// Subscribe app access event handlers
	appAccessH := eventhandler.NewAppAccessHandler(p.CmdBus)
	if err := p.EventBus.Subscribe(ctxBg, "EnrollmentCreated", appAccessH.OnEnrollmentCreated); err != nil {
		log.Warn().Err(err).Msg("failed to subscribe EnrollmentCreated for app access")
	}
	if err := p.EventBus.Subscribe(ctxBg, "CourseBatchCompleted", appAccessH.OnBatchCompleted); err != nil {
		log.Warn().Err(err).Msg("failed to subscribe CourseBatchCompleted for app access")
	}
	if err := p.EventBus.Subscribe(ctxBg, "EnrollmentStatusUpdated", appAccessH.OnEnrollmentStatusUpdated); err != nil {
		log.Warn().Err(err).Msg("failed to subscribe EnrollmentStatusUpdated for app access")
	}
	if err := p.EventBus.Subscribe(ctxBg, "InvoiceOverdue", appAccessH.OnInvoiceOverdue); err != nil {
		log.Warn().Err(err).Msg("failed to subscribe InvoiceOverdue for app access")
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
