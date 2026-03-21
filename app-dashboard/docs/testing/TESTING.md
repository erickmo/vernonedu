# Testing Conventions — app-dashboard

> Standards and practices for testing the VernonEdu dashboard.

---

## Commands

```bash
make test       # Run all unit tests
make analyze    # Static analysis (flutter analyze)
make gen        # Run code generation (build_runner) — always run before testing if models changed
```

---

## What to Test

### Layer: Cubit (Required)

Every cubit must have tests covering:
- **Initial state** — correct default state on creation
- **Loading state** — emitted when action starts
- **Success state** — emitted with correct data on success
- **Error state** — emitted with message on failure
- **Parallel loading** — for cubits using `Future.wait`, test partial failure scenarios

```dart
// Example: cubit test structure
blocTest<CourseCubit, CourseState>(
  'emits [Loading, Loaded] when GetCoursesUseCase succeeds',
  build: () {
    when(() => mockGetCourses()).thenAnswer((_) async => Right(courses));
    return CourseCubit(getCoursesUseCase: mockGetCourses);
  },
  act: (cubit) => cubit.loadCourses(),
  expect: () => [CourseLoading(), CourseLoaded(courses)],
);
```

### Layer: UseCase (Required)

- Test that usecase correctly delegates to repository
- Test parameter passing

### Layer: Repository (Required)

- Test success path (datasource returns data → maps to entity correctly)
- Test error path (datasource throws → returns `Left(Failure)`)
- For SDM domain: test that `ServerFailure` is caught (not `DioException`)

### Layer: Model (Required if has logic)

- Test `fromJson()` with realistic API response
- Test `toEntity()` mapping
- Test edge cases: null fields, missing keys

### Layer: Widget (Recommended)

- Test that correct widgets render for each state (loading spinner, error message, data list, empty state)
- Test user interactions (tap, form input) trigger correct cubit methods

---

## Mocking

- Use `mocktail` for mocking
- Mock at the **usecase level** for cubit tests
- Mock at the **datasource level** for repository tests
- Never mock multiple layers at once

---

## Test File Location

```
test/features/[domain]/
  presentation/cubit/[feature]_cubit_test.dart
  domain/usecases/[usecase]_test.dart
  data/repositories/[feature]_repository_impl_test.dart
  data/models/[feature]_model_test.dart
```

Mirror the `lib/` structure exactly.

---

## Coverage Targets

| Layer | Target |
|-------|--------|
| Cubit | 100% of public methods |
| UseCase | 100% |
| Repository | 100% of success + error paths |
| Model | 100% of fromJson + toEntity |
| Widget | Best effort — focus on state rendering |

---

## Rules

1. **Run `make test` before every PR** — no exceptions
2. **Run `make analyze` before every PR** — zero warnings allowed
3. **Run `make gen` if models changed** — stale generated code causes phantom failures
4. **No integration tests in this project** — integration testing is done at the API level (see `api/` test docs)
5. **Test names in English** — descriptive, e.g. `'should emit error when usecase returns failure'`
