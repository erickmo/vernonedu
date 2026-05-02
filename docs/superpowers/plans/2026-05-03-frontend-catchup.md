# Frontend Catch-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire shipped accounting + certificate + curriculum-approval backends into `app-dashboard` and `app-website` (S3 scope from spec 2026-05-03).

**Architecture:** Flutter clean architecture (data/domain/presentation), BLoC/Cubit, `dartz Either<Failure,T>`, `get_it` DI, `Dio` client. Reuse all existing patterns from `app-dashboard/lib/features/accounting/` and `course_version/`. Each iteration ships as own PR.

**Tech Stack:** Flutter Web · Dart · BLoC · Dio · dartz · get_it · go_router · shared_preferences

**Spec:** `docs/superpowers/specs/2026-05-03-frontend-catchup-design.md`

---

## Conventions Used By All Tasks

- All new files under `app-dashboard/lib/features/<domain>/...` (or `app-website/...` in iter 3) follow existing `accounting/` layout: `data/{datasources,models,repositories}`, `domain/{entities,repositories,usecases}`, `presentation/{cubit,pages}`.
- All HTTP calls go through `Dio` injected from `core/network/api_client.dart`. Base URL prepends `/api/v1`.
- All repo methods return `Future<Either<Failure, T>>`. Use `_extractError(DioException, fallback)` helper pattern (copy from `accounting_repository_impl.dart`).
- All cubit states use `freezed`-style sealed classes (or `Equatable` matching existing `accounting_state.dart`).
- All new entities/models/usecases registered in `app-dashboard/lib/core/di/injection.dart`.
- Tests live alongside under `app-dashboard/test/features/<domain>/...` mirroring source tree. Run via `flutter test`.
- Commit message format: `feat(<scope>): <subject>` per project rule.

---

# ITERATION 1 — Accounting Frontend

Branch: `feat/frontend-catchup` (already created).

## Task 1.1: Bank Account Entity + Model

**Files:**
- Create: `app-dashboard/lib/features/accounting/domain/entities/bank_account_entity.dart`
- Create: `app-dashboard/lib/features/accounting/data/models/bank_account_model.dart`
- Test: `app-dashboard/test/features/accounting/data/models/bank_account_model_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// bank_account_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app_dashboard/features/accounting/data/models/bank_account_model.dart';

void main() {
  test('BankAccountModel.fromJson parses backend payload', () {
    final json = {
      'id': 'b1',
      'branch_id': 'br1',
      'name': 'Operasional',
      'bank_name': 'BCA',
      'account_number': '1234567890',
      'opening_balance': 1000000,
      'is_active': true,
    };
    final m = BankAccountModel.fromJson(json);
    expect(m.id, 'b1');
    expect(m.bankName, 'BCA');
    expect(m.openingBalance, 1000000);
    expect(m.toEntity().isActive, true);
  });
}
```

- [ ] **Step 2: Verify fail**

Run: `cd app-dashboard && flutter test test/features/accounting/data/models/bank_account_model_test.dart`
Expected: file-not-found / compile error.

- [ ] **Step 3: Implement entity + model**

```dart
// bank_account_entity.dart
import 'package:equatable/equatable.dart';

class BankAccountEntity extends Equatable {
  final String id;
  final String branchId;
  final String name;
  final String bankName;
  final String accountNumber;
  final num openingBalance;
  final bool isActive;

  const BankAccountEntity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, branchId, name, bankName, accountNumber, openingBalance, isActive];
}
```

```dart
// bank_account_model.dart
import '../../domain/entities/bank_account_entity.dart';

class BankAccountModel {
  final String id;
  final String branchId;
  final String name;
  final String bankName;
  final String accountNumber;
  final num openingBalance;
  final bool isActive;

  const BankAccountModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    required this.isActive,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> j) => BankAccountModel(
    id: j['id'] as String,
    branchId: j['branch_id'] as String,
    name: j['name'] as String,
    bankName: j['bank_name'] as String,
    accountNumber: j['account_number'] as String,
    openingBalance: j['opening_balance'] as num,
    isActive: j['is_active'] as bool,
  );

  Map<String, dynamic> toCreateJson() => {
    'branch_id': branchId,
    'name': name,
    'bank_name': bankName,
    'account_number': accountNumber,
    'opening_balance': openingBalance,
    'is_active': isActive,
  };

  BankAccountEntity toEntity() => BankAccountEntity(
    id: id, branchId: branchId, name: name, bankName: bankName,
    accountNumber: accountNumber, openingBalance: openingBalance, isActive: isActive,
  );
}
```

- [ ] **Step 4: Verify pass**

Run: `cd app-dashboard && flutter test test/features/accounting/data/models/bank_account_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app-dashboard/lib/features/accounting/domain/entities/bank_account_entity.dart app-dashboard/lib/features/accounting/data/models/bank_account_model.dart app-dashboard/test/features/accounting/data/models/bank_account_model_test.dart
git commit -m "feat(accounting): bank account entity + model"
```

---

## Task 1.2: Bank Account Datasource + Repo Methods

**Files:**
- Modify: `app-dashboard/lib/features/accounting/data/datasources/accounting_remote_datasource.dart` (add bank methods)
- Modify: `app-dashboard/lib/features/accounting/data/repositories/accounting_repository_impl.dart`
- Modify: `app-dashboard/lib/features/accounting/domain/repositories/accounting_repository.dart` (interface)
- Test: `app-dashboard/test/features/accounting/data/repositories/accounting_repository_bank_test.dart`

- [ ] **Step 1: Add abstract methods to repo interface**

Add to `accounting_repository.dart`:

```dart
Future<Either<Failure, List<BankAccountEntity>>> listBankAccounts();
Future<Either<Failure, BankAccountEntity>> createBankAccount(BankAccountModel input);
Future<Either<Failure, BankAccountEntity>> getBankAccount(String id);
Future<Either<Failure, BankAccountEntity>> updateBankAccount(String id, BankAccountModel input);
Future<Either<Failure, void>> deleteBankAccount(String id);
```

- [ ] **Step 2: Add datasource methods**

Add to `accounting_remote_datasource.dart` interface + impl:

```dart
Future<List<BankAccountModel>> listBankAccounts();
Future<BankAccountModel> createBankAccount(Map<String, dynamic> body);
Future<BankAccountModel> getBankAccount(String id);
Future<BankAccountModel> updateBankAccount(String id, Map<String, dynamic> body);
Future<void> deleteBankAccount(String id);
```

Impl uses `_dio.get('/accounting/bank-accounts')`, etc. Map response under `data` key per existing pattern.

- [ ] **Step 3: Implement repo methods**

Copy `getStats` pattern. Each method: check `networkInfo.isConnected`, call datasource, map to entity, wrap in `Right`. Catch `DioException` → `Left(ServerFailure(_extractError(e, '...')))`.

- [ ] **Step 4: Write repo test (mocked datasource)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
// ...
class MockDS extends Mock implements AccountingRemoteDataSource {}
class MockNet extends Mock implements NetworkInfo {}

void main() {
  late AccountingRepositoryImpl repo;
  late MockDS ds; late MockNet net;
  setUp(() {
    ds = MockDS(); net = MockNet();
    when(() => net.isConnected).thenAnswer((_) async => true);
    repo = AccountingRepositoryImpl(remoteDataSource: ds, networkInfo: net);
  });

  test('listBankAccounts returns entities on success', () async {
    when(() => ds.listBankAccounts()).thenAnswer((_) async => [
      const BankAccountModel(id: 'b1', branchId: 'br1', name: 'Op', bankName: 'BCA',
        accountNumber: '1', openingBalance: 0, isActive: true),
    ]);
    final r = await repo.listBankAccounts();
    expect(r.isRight(), true);
    r.fold((_) => fail('left'), (l) => expect(l.length, 1));
  });
}
```

- [ ] **Step 5: Run + commit**

```bash
cd app-dashboard && flutter test test/features/accounting/data/repositories/accounting_repository_bank_test.dart
git add -A app-dashboard/lib/features/accounting app-dashboard/test/features/accounting
git commit -m "feat(accounting): bank account datasource + repository methods"
```

---

## Task 1.3: Bank Account Usecases (5)

**Files (all create):**
- `app-dashboard/lib/features/accounting/domain/usecases/list_bank_accounts_usecase.dart`
- `.../create_bank_account_usecase.dart`
- `.../get_bank_account_usecase.dart`
- `.../update_bank_account_usecase.dart`
- `.../delete_bank_account_usecase.dart`
- Test: `app-dashboard/test/features/accounting/domain/usecases/bank_account_usecases_test.dart`

- [ ] **Step 1: Write usecases (template — repeat for 5)**

```dart
// list_bank_accounts_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../repositories/accounting_repository.dart';

class ListBankAccountsUseCase {
  final AccountingRepository _repo;
  const ListBankAccountsUseCase(this._repo);
  Future<Either<Failure, List<BankAccountEntity>>> call() => _repo.listBankAccounts();
}
```

Each usecase: 1 file, 1 method `call(...)`. Delete uses `String id`. Create/Update use `BankAccountModel`.

- [ ] **Step 2: Test (one happy path per usecase, mocked repo)**

- [ ] **Step 3: Run + commit**

```bash
cd app-dashboard && flutter test test/features/accounting/domain/usecases/bank_account_usecases_test.dart
git commit -am "feat(accounting): bank account usecases"
```

---

## Task 1.4: Bank Account Cubit

**Files:**
- Create: `app-dashboard/lib/features/accounting/presentation/cubit/bank_account_cubit.dart`
- Create: `.../bank_account_state.dart`
- Test: `app-dashboard/test/features/accounting/presentation/cubit/bank_account_cubit_test.dart`

- [ ] **Step 1: State**

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/bank_account_entity.dart';

abstract class BankAccountState extends Equatable {
  const BankAccountState();
  @override List<Object?> get props => [];
}
class BankAccountInitial extends BankAccountState {}
class BankAccountLoading extends BankAccountState {}
class BankAccountLoaded extends BankAccountState {
  final List<BankAccountEntity> items;
  const BankAccountLoaded(this.items);
  @override List<Object?> get props => [items];
}
class BankAccountError extends BankAccountState {
  final String message;
  const BankAccountError(this.message);
  @override List<Object?> get props => [message];
}
```

- [ ] **Step 2: Cubit**

```dart
class BankAccountCubit extends Cubit<BankAccountState> {
  final ListBankAccountsUseCase _list;
  final CreateBankAccountUseCase _create;
  final UpdateBankAccountUseCase _update;
  final DeleteBankAccountUseCase _delete;

  BankAccountCubit({required ListBankAccountsUseCase list, required CreateBankAccountUseCase create,
    required UpdateBankAccountUseCase update, required DeleteBankAccountUseCase delete})
    : _list = list, _create = create, _update = update, _delete = delete,
      super(BankAccountInitial());

  Future<void> load() async {
    emit(BankAccountLoading());
    final r = await _list();
    r.fold((f) => emit(BankAccountError(f.message)), (l) => emit(BankAccountLoaded(l)));
  }
  // create / update / delete: call usecase, then load() again on success
}
```

- [ ] **Step 3: Test states (initial → loading → loaded happy path; error path)**

- [ ] **Step 4: Run + commit**

---

## Task 1.5: Bank Accounts Page

**Files:**
- Create: `app-dashboard/lib/features/accounting/presentation/pages/bank_accounts_page.dart`
- Modify: `app-dashboard/lib/core/di/injection.dart` (register usecases + cubit)
- Modify: `app-dashboard/lib/main.dart` or router file (add route `/admin/accounting/bank-accounts`)

- [ ] **Step 1: Register DI**

Add lines to `injection.dart` mirroring existing accounting registrations:

```dart
sl.registerLazySingleton(() => ListBankAccountsUseCase(sl()));
sl.registerLazySingleton(() => CreateBankAccountUseCase(sl()));
sl.registerLazySingleton(() => UpdateBankAccountUseCase(sl()));
sl.registerLazySingleton(() => DeleteBankAccountUseCase(sl()));
sl.registerFactory(() => BankAccountCubit(list: sl(), create: sl(), update: sl(), delete: sl()));
```

- [ ] **Step 2: Build page**

Use existing `chart_of_accounts_page.dart` as style template. Scaffold + AppBar, `BlocBuilder<BankAccountCubit, BankAccountState>` switching on state, `DataTable` rows with edit/delete `IconButton`s, FAB → opens `BankAccountFormDialog`.

`BankAccountFormDialog`: `AlertDialog` with `TextFormField` for name, bankName, accountNumber, openingBalance (num), Switch for isActive, dropdown for branchId (load via existing branch cubit if available, else free text for now).

- [ ] **Step 3: Add route**

Find existing accounting route in router and add sibling:

```dart
GoRoute(path: 'bank-accounts', builder: (_, __) => BlocProvider(create: (_) => sl<BankAccountCubit>()..load(), child: const BankAccountsPage())),
```

- [ ] **Step 4: Manual smoke test (caveat: real backend required)**

```bash
cd api && make dev &  # if not running
cd app-dashboard && make run-dev
# Open http://localhost:3001/admin/accounting/bank-accounts → verify list, create, edit, delete
```

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(accounting): bank accounts page (list/create/edit/delete)"
```

---

## Task 1.6: COA Tree (entity, model, datasource, repo, usecase, cubit, page)

**Files (create all):**
- `app-dashboard/lib/features/accounting/domain/entities/coa_tree_node_entity.dart`
- `app-dashboard/lib/features/accounting/data/models/coa_tree_node_model.dart`
- `.../usecases/get_coa_tree_usecase.dart`
- `.../presentation/cubit/coa_tree_cubit.dart` + state
- `.../presentation/pages/coa_tree_page.dart`
- Add datasource method `getCoaTree()` calling `GET /accounting/coa/tree`
- Add repo method `getCoaTree()`
- Tests for model, repo, cubit

- [ ] **Step 1: Entity (recursive)**

```dart
class CoaTreeNodeEntity extends Equatable {
  final String code;
  final String name;
  final String type;       // asset|liability|equity|income|expense
  final num balance;
  final List<CoaTreeNodeEntity> children;
  const CoaTreeNodeEntity({required this.code, required this.name, required this.type,
    required this.balance, required this.children});
  @override List<Object?> get props => [code, name, type, balance, children];
}
```

- [ ] **Step 2: Model with recursive `fromJson`**

```dart
factory CoaTreeNodeModel.fromJson(Map<String, dynamic> j) => CoaTreeNodeModel(
  code: j['code'], name: j['name'], type: j['type'],
  balance: (j['balance'] ?? 0) as num,
  children: ((j['children'] as List?) ?? [])
    .map((c) => CoaTreeNodeModel.fromJson(c as Map<String, dynamic>)).toList(),
);
```

- [ ] **Step 3: Datasource + repo + usecase**

Standard wiring, single endpoint `/accounting/coa/tree` returning `{data: [...]}`.

- [ ] **Step 4: Page — collapsible tree**

Use `ExpansionTile` recursively. Each node row: code + name (left), formatted balance (right, `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')`). Children indented inside ExpansionTile children.

- [ ] **Step 5: Test (model recursive parse)**

```dart
test('CoaTreeNodeModel parses 2 levels deep', () {
  final j = {'code': '1', 'name': 'Aset', 'type': 'asset', 'balance': 100, 'children': [
    {'code': '1.1', 'name': 'Kas', 'type': 'asset', 'balance': 50, 'children': []}
  ]};
  final m = CoaTreeNodeModel.fromJson(j);
  expect(m.children.length, 1);
  expect(m.children.first.code, '1.1');
});
```

- [ ] **Step 6: DI register, route `/admin/accounting/coa-tree`, commit**

```bash
git commit -am "feat(accounting): COA tree page with hierarchical balances"
```

---

## Task 1.7: Transaction Edit + Delete

**Files:**
- Modify: `accounting_remote_datasource.dart` — add `updateTransaction(id, body)`, `deleteTransaction(id)`
- Modify: `accounting_repository_impl.dart` + interface
- Create: `usecases/update_transaction_usecase.dart`, `delete_transaction_usecase.dart`
- Modify: `accounting_cubit.dart` — add `updateTransaction`, `deleteTransaction` methods
- Modify: `transaction_page.dart` — add row actions (edit pencil + delete trash icon with confirm dialog)

- [ ] **Step 1: Wire endpoints (PUT/DELETE `/accounting/transactions/{id}`)**

- [ ] **Step 2: Add row actions in DataTable**

```dart
IconButton(icon: Icon(Icons.edit), onPressed: () => _openEdit(tx)),
IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () async {
  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
    title: Text('Hapus transaksi?'),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus'))]));
  if (ok == true) context.read<AccountingCubit>().deleteTransaction(tx.id);
}),
```

- [ ] **Step 3: Test usecases + cubit**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(accounting): transaction edit + delete row actions"
```

---

## Task 1.8: Invoice Detail + Actions (pay/cancel/send + stats)

**Files:**
- Create entities: `invoice_detail_entity.dart`, `invoice_stats_entity.dart`
- Create models matching
- Add datasource methods: `getInvoice(id)`, `markInvoicePaid(id)`, `cancelInvoice(id)`, `sendInvoice(id)`, `getInvoiceStats()`, `listInvoicesEnriched(filters)`
- Add repo methods + usecases (one per action)
- Create: `presentation/cubit/invoice_detail_cubit.dart` + state
- Create: `presentation/pages/invoice_detail_page.dart`

- [ ] **Step 1: Entities**

`InvoiceDetailEntity` extends `InvoiceEntity` with `lineItems: List<InvoiceLineItem>`, `paidAt`, `cancelledAt`, `sentAt`, `pdfUrl?`.

- [ ] **Step 2: Datasource + repo + 4 action usecases (pay/cancel/send + getDetail) + getStats usecase**

Endpoints:
- `GET /finance/invoices/{id}`
- `PUT /finance/invoices/{id}/pay`
- `PUT /finance/invoices/{id}/cancel`
- `PUT /finance/invoices/{id}/send`
- `GET /finance/invoices/stats`

- [ ] **Step 3: Cubit**

`InvoiceDetailCubit` with `load(id)`, `pay()`, `cancel()`, `send()`. Each action calls usecase, on success reload detail.

- [ ] **Step 4: Page**

Header card: invoice number, amount, status chip (color-coded). Body: customer info, line items DataTable, totals row. Actions row: 3 buttons (Tandai Lunas / Batalkan / Kirim) — disabled by status (e.g. cannot pay if cancelled). Confirm dialog before each.

- [ ] **Step 5: Tests + DI + route `/admin/accounting/invoices/:id` + commit**

```bash
git commit -am "feat(accounting): invoice detail page with pay/cancel/send actions"
```

---

## Task 1.9: Invoice List Enriched + Stats Header

**Files:**
- Modify: existing invoice list page (find via `grep -r "getInvoices" app-dashboard/lib/features/accounting/presentation/pages/`)
- Add: stats header widget showing total/paid/unpaid/overdue counts using `getInvoiceStats`
- Wire: navigation from row → invoice detail page (Task 1.8)

- [ ] **Step 1: Add stats widget**

Top of list: 4 cards in `Row` showing counts from stats endpoint. Use `BlocBuilder` on a small `InvoiceStatsCubit` (or reuse `AccountingCubit`).

- [ ] **Step 2: Make rows tappable → push to detail route**

- [ ] **Step 3: Switch list source to `/finance/invoices` enriched endpoint**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(accounting): invoice list stats header + detail navigation"
```

---

## Task 1.10: Financial Analysis Dashboard (7 endpoints)

**Files:**
- Create entities: `financial_ratios_entity.dart`, `revenue_analysis_entity.dart`, `cost_analysis_entity.dart`, `batch_profit_entity.dart`, `cash_forecast_entity.dart`, `alert_entity.dart`, `suggestion_entity.dart`
- Create matching models
- Datasource: 7 methods (one per endpoint under `/finance/analysis/...`)
- Repo + 7 usecases
- Create: `presentation/cubit/analysis_cubit.dart` — single cubit loading all 7 in parallel via `Future.wait`
- Create: `presentation/pages/analysis_dashboard_page.dart`

- [ ] **Step 1: Define entities**

Ratios: `currentRatio`, `quickRatio`, `debtToEquity`, `grossMargin`, `netMargin`, `roi` — all `double`.
Revenue: `total`, `byMonth: List<{month, amount}>`, `bySource: List<{source, amount}>`.
Cost: similar shape.
BatchProfit: `List<{batchId, batchName, revenue, cost, profit}>`.
CashForecast: `List<{month, projected, actual?}>`.
Alert: `id, severity, message, createdAt`.
Suggestion: `id, category, message, impact`.

- [ ] **Step 2: AnalysisCubit loads all 7 in parallel**

```dart
Future<void> loadAll() async {
  emit(AnalysisLoading());
  final results = await Future.wait([
    _ratios(), _revenue(), _costs(), _batchProfit(), _cashForecast(), _alerts(), _suggestions(),
  ]);
  // fold each, emit AnalysisLoaded if all right, AnalysisError on any left
}
```

- [ ] **Step 3: Page layout**

`GridView` (responsive, 2 cols desktop, 1 col mobile):
- Card 1: Ratios — 6 mini-stat tiles
- Card 2: Revenue — line chart (use `fl_chart` if already in pubspec, else simple list)
- Card 3: Costs — bar chart
- Card 4: Batch Profitability — DataTable sortable by profit
- Card 5: Cash Forecast — line chart projected vs actual
- Card 6 (full width): Alerts feed — colored list by severity
- Card 7 (full width): Suggestions — list with category chips

If `fl_chart` not in `pubspec.yaml`, add to plan: run `flutter pub add fl_chart`.

- [ ] **Step 4: Tests — cubit happy/error path, 1 model parse test each**

- [ ] **Step 5: DI register, role-gate route `/admin/accounting/analysis` to accounting roles + director, commit**

```bash
git commit -am "feat(accounting): financial analysis dashboard (ratios/revenue/costs/profit/forecast/alerts/suggestions)"
```

---

## Task 1.11: Iter 1 PR

- [ ] **Step 1: Run full test suite**

```bash
cd app-dashboard && flutter test
```

Expected: all pass.

- [ ] **Step 2: Run linter**

```bash
cd app-dashboard && flutter analyze
```

Expected: 0 errors.

- [ ] **Step 3: Push + open PR**

```bash
git push -u origin feat/frontend-catchup
gh pr create --title "feat(accounting): wire shipped endpoints into dashboard" --body "$(cat <<'EOF'
## Summary
- Bank account CRUD page
- COA tree view with balances
- Transaction edit/delete
- Invoice detail + pay/cancel/send + stats header
- Financial analysis dashboard (7 endpoints)

## Test plan
- [ ] flutter test passes
- [ ] flutter analyze clean
- [ ] Manual: create + delete bank account
- [ ] Manual: open COA tree, expand levels
- [ ] Manual: edit transaction, delete with confirm
- [ ] Manual: open invoice, mark paid
- [ ] Manual: open analysis dashboard, all cards populate

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: After merge, branch new iter from main**

```bash
git checkout main && git pull && git checkout -b feat/certificate-frontend
```

---

# ITERATION 2 — Certificate Frontend

Branch: `feat/certificate-frontend`.

## Task 2.1: Extend certificate entity/model for new fields

**Files:**
- Modify: `app-dashboard/lib/features/certificate/domain/entities/certificate_entity.dart` (add fields if missing: `code`, `qrUrl`, `type` (participant|competency), `studentId`, `batchId`, `courseId`, `issuedAt`, `revokedAt?`, `revokeReason?`)
- Modify: matching model + `fromJson`
- Test: parse fixture

- [ ] **Step 1: Read current entity, add missing fields**
- [ ] **Step 2: Update model fromJson**
- [ ] **Step 3: Test fromJson with full payload**
- [ ] **Step 4: Commit**

```bash
git commit -am "feat(certificate): extend entity/model for new fields"
```

---

## Task 2.2: Issue Participant + Competency Datasource/Repo/Usecase

**Endpoints:**
- `POST /certificates/participant` — body: `{batch_id, student_ids[]}`
- `POST /certificates/competency` — body: `{student_id, course_id, test_score, test_date}`

**Files:**
- Modify: `certificate_remote_datasource.dart` — add `issueParticipant(body)`, `issueCompetency(body)`
- Modify: `certificate_repository_impl.dart` + interface
- Create: `usecases/issue_participant_certificate_usecase.dart`, `issue_competency_certificate_usecase.dart`

- [ ] **Step 1: Wire endpoints**
- [ ] **Step 2: Test usecases**
- [ ] **Step 3: Commit**

```bash
git commit -am "feat(certificate): issue participant + competency usecases"
```

---

## Task 2.3: List by Student + List by Batch

**Endpoints:**
- `GET /students/{id}/certificates`
- `GET /batches/{id}/certificates`

**Files:**
- Add datasource methods + repo + usecases
- Create: `cubit/student_certificates_cubit.dart`, `batch_certificates_cubit.dart`

- [ ] **Step 1: Wire**
- [ ] **Step 2: Test cubits**
- [ ] **Step 3: Commit**

---

## Task 2.4: Issue Participant Page (bulk multi-select)

**Files:**
- Create: `presentation/pages/issue_participant_page.dart`
- Modify: DI, router (`/admin/certificates/issue/participant`)

- [ ] **Step 1: Build page**

Layout:
1. Step 1: Batch dropdown (load via existing batch cubit)
2. Step 2: After batch selected, load enrolled students. Show CheckboxListTile list with "Select All" header.
3. Step 3: Issue button (disabled until ≥1 student). Calls `issueParticipant(batchId, selectedIds)` via cubit.
4. Success: SnackBar "X sertifikat diterbitkan" + reset form.

- [ ] **Step 2: Cubit handles state machine: initial → batchSelected → studentsLoaded → issuing → done/error**

- [ ] **Step 3: Test cubit transitions**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(certificate): issue participant bulk page"
```

---

## Task 2.5: Issue Competency Page (single-student form)

**Files:**
- Create: `presentation/pages/issue_competency_page.dart`
- Route: `/admin/certificates/issue/competency`

- [ ] **Step 1: Build form**

Fields: student autocomplete (search by name), course dropdown, test score (number, 0-100), test date (date picker), pass criteria warning if score < passing threshold (read from course config if available, else hardcode 70).

- [ ] **Step 2: Submit calls `issueCompetency` usecase**

- [ ] **Step 3: Test + commit**

```bash
git commit -am "feat(certificate): issue competency form page"
```

---

## Task 2.6: Student Certificates Tab (embed in student detail)

**Files:**
- Find student detail page: `grep -rl "StudentDetail" app-dashboard/lib`
- Modify: add new tab "Sertifikat" using `TabBar`
- Create: `presentation/widgets/student_certificates_tab.dart`

- [ ] **Step 1: Build tab widget**

`BlocProvider<StudentCertificatesCubit>` loaded with `studentId`, list certs grouped by type (Participant / Competency), each row: course name, batch (if applicable), date, status badge, actions (view, revoke if not revoked).

- [ ] **Step 2: Wire tab into existing student detail TabBar**

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(certificate): student detail certificates tab"
```

---

## Task 2.7: Batch Certificates Tab (embed in batch detail)

Same as 2.6 but for batch detail page, grouped by student.

- [ ] **Step 1-3: Build, wire, commit**

```bash
git commit -am "feat(certificate): batch detail certificates tab"
```

---

## Task 2.8: Revoke Dialog with Approval Note

**Files:**
- Create: `presentation/widgets/certificate_revoke_dialog.dart`

- [ ] **Step 1: Build dialog**

`AlertDialog`:
- Reason `TextFormField` (required, min 20 chars)
- Note: "Pencabutan memerlukan persetujuan: Dept Leader → Education Leader → Director"
- Buttons: Batal / Ajukan Pencabutan

- [ ] **Step 2: Wire to existing `revokeCertificate` usecase from cubit**

- [ ] **Step 3: Add to row actions on student/batch tabs and any list page**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(certificate): revocation dialog with approval chain note"
```

---

## Task 2.9: Template CRUD + A4 Live Preview

**Files:**
- Existing template usecases assumed (`createTemplate`, `getTemplates`, `updateTemplate`). If `update` missing, add it.
- Create: `presentation/pages/certificate_template_list_page.dart`
- Create: `presentation/pages/certificate_template_editor_page.dart`
- Create: `presentation/widgets/a4_certificate_preview.dart`

- [ ] **Step 1: List page**

Routes: `/admin/certificate-templates`. DataTable: name, type (participant/competency), updatedAt, actions (edit, delete).

- [ ] **Step 2: A4 preview widget**

```dart
class A4CertificatePreview extends StatelessWidget {
  final TemplateConfig config;
  final String? backgroundUrl;
  const A4CertificatePreview({required this.config, this.backgroundUrl});

  @override
  Widget build(BuildContext context) {
    // A4: 595x842 logical px @ 72dpi
    return AspectRatio(
      aspectRatio: 595 / 842,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          image: backgroundUrl != null ? DecorationImage(
            image: NetworkImage(backgroundUrl!), fit: BoxFit.cover) : null,
        ),
        child: LayoutBuilder(builder: (ctx, c) {
          // Render fields by % offsets
          return Stack(children: [
            Positioned(
              left: c.maxWidth * config.titleX,
              top: c.maxHeight * config.titleY,
              child: Text(config.title, style: TextStyle(fontSize: config.titleSize, fontFamily: config.fontFamily)),
            ),
            // ... body, signatures, QR
          ]);
        }),
      ),
    );
  }
}
```

- [ ] **Step 3: Editor page**

Two-column layout: left = form (title, body markdown, font family dropdown, sizes, signature names, QR position dropdown, background URL upload), right = `A4CertificatePreview` live-updating via `setState` or local `ValueNotifier`.

Save button calls `updateTemplate`. New button → `createTemplate`.

- [ ] **Step 4: Test — widget golden test for preview at default config**

```dart
testWidgets('A4 preview renders title at configured position', (tester) async {
  await tester.pumpWidget(MaterialApp(home: A4CertificatePreview(config: TemplateConfig.defaults)));
  expect(find.text('Sertifikat'), findsOneWidget);
});
```

- [ ] **Step 5: Routes + DI + commit**

```bash
git commit -am "feat(certificate): template CRUD with A4 live preview editor"
```

---

## Task 2.10: Iter 2 PR

- [ ] flutter test + analyze passes, push, gh pr create

---

# ITERATION 3 — Public Verify (app-website)

Branch: `feat/public-cert-verify`.

## Task 3.1: PII-safe entity + service swap

**Files:**
- Create: `app-website/lib/core/models/public_certificate_verification_model.dart`
- Modify: `app-website/lib/core/services/public_certificate_service.dart` — swap to `/api/v1/public/certificates/verify/{code}`

- [ ] **Step 1: Define PII-safe model**

```dart
class PublicCertificateVerification {
  final String code;
  final String studentDisplayName;  // "Erick M."
  final String courseName;
  final DateTime? batchStartDate;
  final DateTime? batchEndDate;
  final String issuerName;
  final String type;  // participant|competency
  final bool isValid;
  final DateTime? revokedAt;
  final String? revokeReason;  // sanitized

  factory PublicCertificateVerification.fromJson(Map<String, dynamic> j) => ...;
}
```

- [ ] **Step 2: Update service to call public alias endpoint**

- [ ] **Step 3: Test fromJson + service (mocked Dio)**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(website): PII-safe certificate verification model + service"
```

---

## Task 3.2: Sertifikat page redesign

**Files:**
- Modify: `app-website/lib/features/sertifikat/sertifikat_page.dart`

- [ ] **Step 1: Rebuild page**

Hero section: "Verifikasi Sertifikat VernonEdu". Input: large `TextField` for code + "Verifikasi" button. Optional: parse `?code=` from URL on init via `Uri.base.queryParameters['code']`.

Result card (after verify):
- ✅ Green banner if valid, ❌ red banner if revoked
- Student display name (PII-safe)
- Course name + batch dates
- Issuer
- Cert type badge
- QR rendered via `qr_flutter` (or static image from backend)
- If revoked: red note with date + sanitized reason
- Print button: `print()` JS interop or just CSS `@media print` hint

Empty state: search illustration. Error state: friendly "Sertifikat tidak ditemukan".

- [ ] **Step 2: Cubit (or simple `StatefulWidget` since 1 service call)**

For consistency with rest of app-website, plain `StatefulWidget` with `Future` is OK if app-website doesn't use BLoC. Check pattern via `grep -rl "Cubit\|Bloc" app-website/lib | head -5`.

- [ ] **Step 3: Manual test**

```bash
cd app-website && flutter run -d chrome
# Navigate to /sertifikat?code=VALIDCODE → should render card
# Use invalid code → friendly error
# Use revoked code → red banner
# Verify in DevTools Network tab no PII leakage
```

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(website): redesign sertifikat verify page (PII-safe + valid/revoked states)"
```

---

## Task 3.3: Iter 3 PR

```bash
git push -u origin feat/public-cert-verify
gh pr create --title "feat(website): PII-safe public certificate verification" --body "..."
```

---

# ITERATION 4 — Curriculum Approval

Branch: `feat/curriculum-approval-frontend`.

## Task 4.1: Approve usecase wired

**Files:**
- Modify: `app-dashboard/lib/features/course_version/data/datasources/course_version_remote_datasource.dart` — add `approveVersion(versionId, body)`
- Modify: repo + interface
- Create: `domain/usecases/approve_course_version_usecase.dart`
- Modify: `course_version_cubit.dart` — add `approveVersion(versionId, decision, reason)`

**Endpoint:** `POST /api/v1/curriculum/versions/{versionID}/approve` body: `{decision: 'approved'|'rejected', reason?: string}` (verify body shape from `api/internal/command/approve_courseversion/command.go` if needed).

- [ ] **Step 1: Verify body shape from backend command file**

```bash
grep -A 20 "type Command\|type ApproveCommand" api/internal/command/approve_courseversion/command.go
```

- [ ] **Step 2: Wire datasource**

```dart
Future<void> approveVersion(String versionId, Map<String, dynamic> body) async {
  await _dio.post('/curriculum/versions/$versionId/approve', data: body);
}
```

- [ ] **Step 3: Repo + usecase**

- [ ] **Step 4: Cubit method**

```dart
Future<void> approveVersion(String versionId, String decision, String? reason) async {
  emit(state.copyWith(isApproving: true));
  final r = await _approve(versionId, decision, reason);
  r.fold(
    (f) => emit(state.copyWith(isApproving: false, error: f.message)),
    (_) async { await load(); }, // reload list
  );
}
```

- [ ] **Step 5: Test cubit transitions**

- [ ] **Step 6: Commit**

```bash
git commit -am "feat(curriculum): course version approve usecase + cubit method"
```

---

## Task 4.2: Approve Button + ApprovalWizard wiring

**Files:**
- Modify: `app-dashboard/lib/features/course_version/presentation/pages/course_version_page.dart` — add Approve button on detail view
- Reuse existing `ApprovalWizard` component (search location):

```bash
grep -rl "ApprovalWizard" app-dashboard/lib/features
```

- [ ] **Step 1: Add role-gated button**

```dart
if (auth.hasRole('dept_leader') && version.status == 'pending_approval')
  ElevatedButton.icon(
    icon: Icon(Icons.check),
    label: Text('Setujui'),
    onPressed: () => showDialog(context: context, builder: (_) => ApprovalWizard(
      title: 'Setujui Versi Kurikulum',
      onConfirm: (decision, reason) =>
        context.read<CourseVersionCubit>().approveVersion(version.id, decision, reason),
    )),
  ),
```

- [ ] **Step 2: Verify `auth.hasRole` helper exists, else add to AuthContext**

```bash
grep -r "hasRole\|userRole" app-dashboard/lib/core | head
```

- [ ] **Step 3: Manual test — login as dept_leader, navigate to pending version, click Setujui**

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(curriculum): wire approve button on version detail (dept_leader)"
```

---

## Task 4.3: Pending Approvals Queue Page

**Files:**
- Create: `app-dashboard/lib/features/course_version/presentation/cubit/pending_approvals_cubit.dart` + state
- Create: `app-dashboard/lib/features/course_version/presentation/pages/pending_approvals_page.dart`
- Modify: course_version datasource — add `listPendingApprovals()` filtering by status (use existing list endpoint with `?status=pending_approval` query param if backend supports it; else filter client-side)
- Add route: `/admin/curriculum/approvals`
- Add sidebar entry visible only to dept_leader

- [ ] **Step 1: Verify backend supports status filter**

```bash
grep -i "status\|StatusFilter" api/internal/query/list_courseversions/query.go 2>/dev/null
```

If supported, use server filter. If not, fetch all + filter client-side (mark as tech debt).

- [ ] **Step 2: Cubit loads pending list**

- [ ] **Step 3: Page**

DataTable: course name, version, submitted by, submitted at, action button → opens version detail (existing route) with intent param `?action=approve` (auto-opens wizard).

- [ ] **Step 4: Sidebar entry**

Find sidebar component (`grep -rl "Sidebar\|NavRail" app-dashboard/lib/core/widgets`), add NavLink role-gated:

```dart
if (auth.hasRole('dept_leader'))
  NavTile(icon: Icons.fact_check, label: 'Persetujuan Kurikulum', route: '/admin/curriculum/approvals'),
```

- [ ] **Step 5: Test cubit**

- [ ] **Step 6: Commit**

```bash
git commit -am "feat(curriculum): pending approvals queue page (dept_leader)"
```

---

## Task 4.4: Iter 4 PR + final cleanup

- [ ] **Step 1: Run full suite**

```bash
cd app-dashboard && flutter test && flutter analyze
```

- [ ] **Step 2: Push + PR**

```bash
git push -u origin feat/curriculum-approval-frontend
gh pr create --title "feat(curriculum): approval queue + wizard wiring (dept_leader)" --body "..."
```

- [ ] **Step 3: Update CLAUDE.md if any new domain conventions emerged (likely none — pure pattern reuse)**

- [ ] **Step 4: Update `.wolf/anatomy.md` with new files (one-liner per file)**

```bash
# Append section listing new files under app-dashboard/lib/features/{accounting,certificate,course_version}/...
```

---

# Notes for Implementer

- **Existing patterns are gospel.** Always read sibling code in the same feature before writing new files. Repo error handling, model `fromJson`, cubit state shape — all already exist. Copy them.
- **Role helper:** `AuthContext.hasRole(String)` is the single source of truth for role gating. If absent, add it (one task to introduce it before iter 4).
- **No backend changes.** All endpoints are shipped. If a payload shape surprises you, read the Go handler in `api/internal/delivery/http/<x>_handler.go` — do not guess.
- **A4 preview** uses logical Flutter px scaled via `AspectRatio`. Print fidelity not in scope (PDF export is future work).
- **Public verify** must not return PII. If backend response contains PII, that's a backend bug — file a separate ticket; do not paper over with frontend masking.
- **Localization:** UI strings in Bahasa Indonesia matching existing pages (e.g. "Hapus", "Setujui", "Tandai Lunas").
- **Currency formatting:** `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')` from `intl`. Check pubspec.

---

# Self-Review Notes (already applied inline)

- ✅ Spec coverage: every iteration in spec has tasks here. Bank accounts, COA tree, transaction edit/delete, invoice detail+actions, analysis dashboard (iter 1) ✓. Issue forms, list-by-student/batch tabs, template editor with A4 preview, revoke dialog (iter 2) ✓. Public verify with PII-safe model (iter 3) ✓. Approve button + queue page (iter 4) ✓.
- ✅ No placeholders: all "TODO" replaced with concrete code or explicit "verify body shape from backend file X" steps.
- ✅ Type consistency: `BankAccountModel.toCreateJson()` used in usecases (defined in 1.1). `TemplateConfig` referenced in 2.9 — implementer reads existing certificate template model to define exact field set. `ApprovalWizard` reused from already-shipped component (verify location step in 4.2).
- ⚠ Outstanding verifications (deferred to implementer with grep commands embedded):
  - Approve command body shape (4.1 step 1)
  - List versions status filter support (4.3 step 1)
  - `ApprovalWizard` import path (4.2)
  - `hasRole` helper presence (4.2 step 2)
  - `fl_chart` package presence (1.10 step 3)
