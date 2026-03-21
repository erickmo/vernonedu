# VernonEdu Dashboard — CLAUDE.md

> Internal management dashboard for VernonEdu. Flutter Web.
> **Language rule:** All UI strings/labels in Bahasa Indonesia. Comments and documentation in English.
> **Domain specs:** See `docs/requirements/` for per-domain details.

---

## Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41.4 + Dart 3.11.1, Platform: Web only |
| State | BLoC / Cubit (flutter_bloc) |
| Navigation | go_router (v12) |
| DI | get_it — `registerSingleton` for datasource/repo, `registerFactory` for usecase/cubit |
| Network | Dio + pretty_dio_logger. `ApiClient` injects Bearer token via `_AuthInterceptor` |
| Storage | shared_preferences — **never flutter_secure_storage** (web incompatible) |
| Charts | fl_chart |
| Tables | data_table_2 |

**Ports:** App `http://localhost:3001` · API `http://localhost:8081/api/v1`

---

## Architecture

Clean Architecture: `lib/features/[domain]/data|domain|presentation/`

```
data/
  datasources/   → [feature]_remote_datasource.dart  (abstract + impl)
  models/        → [feature]_model.dart               (fromJson, toEntity)
  repositories/  → [feature]_repository_impl.dart
domain/
  entities/      → [feature]_entity.dart              (Equatable, pure Dart)
  repositories/  → [feature]_repository.dart          (abstract)
  usecases/      → verb_noun_usecase.dart              (single call() method)
presentation/
  cubit/         → [feature]_cubit.dart + [feature]_state.dart
  pages/         → [feature]_page.dart
  widgets/       → [feature]_*.dart
```

---

## Core Rules

- **No business logic in `build()`**
- **No hardcoded string/color/dimension** — use `AppStrings`, `AppColors`, `AppDimensions`
- **Repository returns `Either<Failure, T>`** (dartz)
- **Handle all UI states:** loading / success / error / empty
- **Error propagation:** Let `DioException` propagate from datasource; catch in repository impl. SDM feature uses `throw ServerFailure(...)` pattern — both styles exist.
- **Response parsing pattern:**
  ```dart
  final raw = res.data;
  final json = (raw is Map && raw['data'] != null)
      ? raw['data'] as Map<String, dynamic>
      : raw as Map<String, dynamic>;
  ```
- **Page pattern:** `BlocProvider(create: (_) => getIt<XCubit>()..loadX())` → child `_XView`
- **Hover on web:** `MouseRegion` + `StatefulWidget`, track `_isHovered`, `SystemMouseCursors.click`
- **Parallel loading:** `Future.wait([useCase1(), useCase2()])` inside cubit
- **Code generation:** Run `make gen` after adding/modifying models with freezed
- **All code written by AI** — developer does not write manually

---

## AppColors (key tokens)

```dart
// Primary — Indigo
AppColors.primary          // #1A237E
AppColors.primaryLight     // #534BAE
AppColors.primaryDark      // #000051
AppColors.primarySurface   // #E8EAF6

// Secondary — Teal
AppColors.secondary        // #00695C
AppColors.secondaryLight   // #439889
AppColors.secondaryDark    // #003D33

// Sidebar (dark indigo theme)
AppColors.sidebarBg        // #1A237E
AppColors.sidebarActive    // #283593
AppColors.sidebarHover     // #3949AB
AppColors.sidebarText      // #E8EAF6
AppColors.sidebarTextMuted // #9FA8DA
AppColors.sidebarDivider   // #283593

// Brand accent
AppColors.lavender         // #EDE9FF
AppColors.lavenderMid      // #C8B4E8

// Background & Surface
AppColors.background       // #F5F5F5
AppColors.surface          // #FFFFFF
AppColors.surfaceVariant   // #F8F9FA
AppColors.border           // #E8E4F0
AppColors.divider          // #F0EDF8

// Text
AppColors.textPrimary      // #1C2536
AppColors.textSecondary    // #637381
AppColors.textHint         // #B0BEC5
AppColors.textOnPrimary    // #FFFFFF

// Status
AppColors.success / .successSurface   // #2E7D32 / #E8F5E9
AppColors.warning / .warningSurface   // #E65100 / #FFF3E0
AppColors.error   / .errorSurface     // #C62828 / #FFEBEE
AppColors.info    / .infoSurface      // #0277BD / #E1F5FE

// Role colors
AppColors.roleDirector     // #4A148C
AppColors.roleDeptLeader   // #1565C0
AppColors.roleCourseOwner  // #00695C
AppColors.roleFacilitator  // #558B2F
AppColors.roleCS           // #6A1B9A
AppColors.roleStudent      // #0277BD
AppColors.rolePartner      // #4E342E

// Chart palette (7 colors)
AppColors.chartColors      // [#1A237E, #00695C, #F57F17, #C62828, #6A1B9A, #0277BD, #558B2F]
```

## AppDimensions (key tokens)

```dart
// Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
// BorderRadius: radiusSm=4, radiusMd=8, radiusLg=12, radiusXl=16, radiusCircle=999
// Icons: iconSm=16, iconMd=20, iconLg=24
// Layout: sidebarWidth=260, sidebarCollapsed=68, topbarHeight=64
// Card & Button: cardElevation=0, buttonHeight=40, buttonHeightLg=48
// Table: tableRowHeight=52, tableHeaderHeight=44
// Avatars: avatarSm=28, avatarMd=36, avatarLg=48
// Breakpoints: mobile=768, tablet=1024, desktop=1280
```

---

## Roles (Dashboard)

| Key | Label UI | Scope |
|---|---|---|
| `director` | Direktur | Full access |
| `education_leader` | Education Leader | All education domains |
| `dept_leader` | Kepala Departemen | Department scope |
| `course_owner` | Course Owner | Course + batch + enrollment |
| `facilitator` | Fasilitator | Assigned batches |
| `operation_leader` | Operation Leader | Operations domains |
| `operation_admin` | Operation Administrator | Batch creation, scheduling, location |
| `customer_service` | Customer Service | Students + enrollment + payment |
| `marketing` | Marketing Team | CRM + ads templates |
| `accounting_leader` | Accounting Leader | All financial |
| `accounting_staff` | Accounting Staff | Accounting operations |

> A single employee can hold multiple roles.

---

## Navigation (go_router)

```
/login                              → LoginPage (unauthenticated)
/dashboard                          → DashboardPage
/curriculum                         → CoursePage
  /curriculum/types/:typeId         → CourseVersionPage
  /curriculum/versions/:versionId   → CourseModulePage
  /curriculum/:courseId             → CourseDashboardPage
/courses/:id                        → CourseDashboardPage (backward compat)
/course-batches                     → CourseBatchPage
  /course-batches/:batchId          → CourseBatchDetailPage
/enrollments                        → EnrollmentPage
/evaluations                        → EvaluationPage
/students                           → StudentPage
  /students/:studentId              → StudentDashboardPage
/talentpool                         → TalentPoolPage (4 tabs)
/certificates                       → CertificatePage
/payments                           → PaymentPage
/departments                        → DepartmentPage
  /departments/:departmentId        → DepartmentDashboardPage
/accounting                         → (deprecated — redirect to /finance)
/finance                            → FinanceMainPage (dashboard)
  /finance/transactions             → TransactionPage
  /finance/transactions/new         → TransactionFormPage
  /finance/journal                  → JournalPage
  /finance/coa                      → ChartOfAccountsPage
  /finance/invoices                 → InvoicePage
  /finance/payables                 → PayablePage
  /finance/reports                  → ReportNavigationPage
    /finance/reports/balance-sheet  → BalanceSheetPage
    /finance/reports/profit-loss    → ProfitLossPage
    /finance/reports/cash-flow      → CashFlowPage
    /finance/reports/ledger         → GeneralLedgerPage
    /finance/reports/trial-balance  → TrialBalancePage
  /finance/analysis                 → FinancialAnalysisPage
/hrm                                → HrmPage
  /hrm/:sdmId                       → SdmDetailPage
/projects                           → ProjectPage
/crm                                → CrmPage
/marketing                          → MarketingPage (leads, social media, PR, referral, calendar)
/partners                           → PartnerPage (partner data + MOU tracking)
/leads                              → LeadsPage (potential customer tracking)
/locations                          → LocationPage (buildings & rooms)
/business-development               → BusinessDevelopmentPage (overview)
  /business-development/canvas      → BMCPage (Business Model Canvas)
  /business-development/branches    → BranchManagementPage
  /business-development/franchises  → FranchiseManagementPage
  /business-development/okr         → OkrPage (OKR & KPI)
  /business-development/investments → InvestmentPlanPage
  /business-development/projections → ProjectionReportsPage
  /business-development/delegations → DelegationPage
/notifications                      → NotificationPage
/approvals                          → ApprovalPage (pending approvals queue)
/settings                           → SettingsPage (certificate templates, commission, CoA, domains, etc.)
/cms                                → CmsPage (website content management)
  /cms/pages/:slug/edit             → PageEditorPage
  /cms/articles                     → ArticleListPage
  /cms/articles/new                 → ArticleEditorPage
  /cms/articles/:id/edit            → ArticleEditorPage
```

Auth redirect: unauthenticated → `/login`; authenticated on `/login` → `/dashboard`
All routes use `NoTransitionPage` (no animation).

---

## Domain Status

| Domain | Status | Spec |
|--------|--------|------|
| Auth | ✅ Functional | [auth.md](docs/requirements/auth.md) |
| Curriculum (Course→Module) | ✅ Functional | [curriculum.md](docs/requirements/curriculum.md) |
| CourseBatch + Enrollment | ✅ Functional (needs v2 updates) | [batch-enrollment.md](docs/requirements/batch-enrollment.md) |
| Student + StudentDetail | ✅ Functional | [student.md](docs/requirements/student.md) |
| TalentPool | ✅ Functional | [talent-pool.md](docs/requirements/talent-pool.md) |
| Department | ✅ Functional | [department.md](docs/requirements/department.md) |
| HRM/SDM | ✅ Functional | [hrm.md](docs/requirements/hrm.md) |
| Certificate | ⚠️ Violates cubit pattern | [certificate.md](docs/requirements/certificate.md) |
| Accounting | ⚠️ Mock data only | [accounting.md](docs/requirements/accounting.md) |
| Operations (Location, Ads, Leads) | 🔴 Not implemented | [operations.md](docs/requirements/operations.md) |
| Notifications | 🔴 Not implemented | [notifications.md](docs/requirements/notifications.md) |
| Approvals | 🔴 Not implemented | [approvals.md](docs/requirements/approvals.md) |
| Partner & MOU | 🔴 Not implemented | [future.md](docs/requirements/future.md) |
| Project (Events) | 🔴 Shell only | [future.md](docs/requirements/future.md) |
| Business Development (BMC, Branch, OKR, Projections) | 🔴 Not implemented | [business-development.md](docs/requirements/business-development.md) |
| Evaluation, Payment, CRM | 🔴 Shell only | [future.md](docs/requirements/future.md) |

> **Dashboard is role-based.** Each user sees a dashboard tailored to their role(s). See [business-development.md](docs/requirements/business-development.md) for role access matrix and [operations.md](docs/requirements/operations.md) for the operational team's today + 7-day prep view.

### Screen Layout Specs

| Domain | Spec |
|--------|------|
| Education (Course, Batch, Version) | [education-screens.md](docs/requirements/education-screens.md) |
| Student List | [screen-student-list.md](docs/requirements/screen-student-list.md) |
| Student Detail | [screen-student-detail.md](docs/requirements/screen-student-detail.md) |
| Student Form | [screen-student-form.md](docs/requirements/screen-student-form.md) |
| Business Development | [screen-bizdev.md](docs/requirements/screen-bizdev.md) |
| Partner Detail | [screen-partner-detail.md](docs/requirements/screen-partner-detail.md) |
| Marketing | [screen-marketing.md](docs/requirements/screen-marketing.md) |
| Finance Main | [screen-finance-main.md](docs/requirements/screen-finance-main.md) |
| Finance Reports | [screen-finance-reports.md](docs/requirements/screen-finance-reports.md) |
| Finance Invoices | [screen-finance-invoices.md](docs/requirements/screen-finance-invoices.md) |
| Finance Payables | [screen-finance-payables.md](docs/requirements/screen-finance-payables.md) |
| Finance Transactions & CoA | [screen-finance-transactions.md](docs/requirements/screen-finance-transactions.md) |
| Finance Analysis | [screen-finance-analysis.md](docs/requirements/screen-finance-analysis.md) |
| Finance Automation Hooks | [finance-automation.md](docs/requirements/finance-automation.md) |
| CMS (Website Content) | [screen-cms.md](docs/requirements/screen-cms.md) |

---

## Commands

```bash
make get        # flutter pub get
make gen        # flutter pub run build_runner build --delete-conflicting-outputs
make run-dev    # flutter run -d chrome --web-port 3001
make test       # flutter test
make analyze    # flutter analyze
make build-web  # flutter build web --release
```

---

## Common Patterns

### Adding a new domain

1. Create entity → model (fromJson + toEntity) → datasource (abstract + impl) → repository (abstract + impl) → usecases
2. Register in `injection.dart` (singleton for datasource/repo, factory for usecase/cubit)
3. Add route in `app_router.dart` inside `ShellRoute.routes`
4. Add sidebar entry in shell widget

### Cubit loadAll with parallel data

```dart
Future<void> loadAll() async {
  emit(const XLoading());
  final results = await Future.wait([useCase1(), useCase2()]);
  final a = results[0].fold((_) => <A>[], (d) => d as List<A>);
  final b = results[1].fold((f) { emit(XError(f.message)); return <B>[]; }, (d) => d as List<B>);
  if (state is XError) return;
  emit(XLoaded(a: a, b: b));
}
```

### Response parsing (nullable data wrapper)

```dart
final raw = res.data;
final json = (raw is Map && raw['data'] != null)
    ? raw['data'] as Map<String, dynamic>
    : raw as Map<String, dynamic>;
// For lists:
final list = (raw is Map && raw['data'] != null)
    ? raw['data'] as List
    : raw is List ? raw : <dynamic>[];
```

---

**Last Updated:** Maret 2026
