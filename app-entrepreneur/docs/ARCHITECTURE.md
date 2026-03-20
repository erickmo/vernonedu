# Architecture Documentation

## Overview

VernonEdu Entrepreneurship App mengikuti **Clean Architecture** dengan separation of concerns antara Data, Domain, dan Presentation layers.

---

## Project Structure

```
lib/
├── config/
│   └── routes/
│       └── app_router.dart          # go_router configuration
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_dimensions.dart      # Spacing, border radius, breakpoints
│   │   ├── app_strings.dart         # Localized strings
│   │   └── app_constants.dart       # Other constants
│   │
│   ├── failures/
│   │   └── failures.dart            # Error handling
│   │
│   └── utils/
│       └── extensions.dart          # Utility extensions
│
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── remote/          # API calls
│       │   │   └── local/           # Local storage
│       │   ├── models/              # Data models (freezed)
│       │   └── repositories/        # Repository implementations
│       │
│       ├── domain/
│       │   ├── entities/            # Business entities
│       │   ├── repositories/        # Repository interfaces
│       │   └── usecases/            # Business logic
│       │
│       └── presentation/
│           ├── pages/               # Full-screen widgets
│           ├── widgets/             # Reusable widgets
│           ├── bloc/ atau cubit/    # State management
│           └── [feature]_state.dart # State models
│
└── main.dart                         # App entry point
```

---

## Layers

### 1. Presentation Layer

**Responsibility:** UI rendering dan user interaction handling.

**Contains:**
- **Pages**: Full-screen widgets (StatefulWidget/StatelessWidget)
- **Widgets**: Reusable UI components
- **State Management**: BLoC/Cubit untuk complex state
- **Models**: UI-specific data models (freezed)

**Example:**
```dart
// WorksheetPage — Full screen untuk worksheet editing
class WorksheetPage extends StatefulWidget {
  // Navigation params: businessId, worksheetKey
}

// CanvasSectionWidget — Reusable section component
class CanvasSectionWidget extends StatefulWidget {
  // Reusable di berbagai worksheet types
}
```

**Guidelines:**
- ❌ Jangan put business logic di build()
- ✅ Delegate state management ke BLoC/Cubit
- ✅ Keep widgets fokus pada presentation
- ✅ Pass data through constructor parameters

---

### 2. Domain Layer

**Responsibility:** Business logic dan rules.

**Contains:**
- **Entities**: Pure Dart objects yang represent business concepts
- **Repositories**: Interfaces yang define contracts
- **UseCases**: Orchestrate business operations

**Example:**
```dart
// Entity — Business concept
class Business {
  final String id;
  final String name;
  final String description;
}

// Repository Interface — Contract
abstract class BusinessRepository {
  Future<Either<Failure, Business>> getById(String id);
  Future<Either<Failure, List<Business>>> getAll();
}

// UseCase — Business orchestration
class GetBusinessByIdUseCase {
  final BusinessRepository repository;

  Future<Either<Failure, Business>> call(String id) async {
    return await repository.getById(id);
  }
}
```

**Guidelines:**
- ✅ Entities are pure Dart — tidak depend pada framework
- ✅ Repositories adalah interfaces (abstract classes)
- ✅ UseCases encapsulate single business operation
- ✅ Return `Either<Failure, T>` untuk error handling

---

### 3. Data Layer

**Responsibility:** Data source abstraction dan persistence.

**Contains:**
- **DataSources**: Remote (API) dan Local (Database) data sources
- **Models**: DTO (Data Transfer Objects) dengan serialization
- **Repositories**: Implementations dari domain repositories

**Example:**
```dart
// Model — DTO dengan serialization
@freezed
class BusinessModel with _$BusinessModel {
  const factory BusinessModel({
    required String id,
    required String name,
    required String description,
  }) = _BusinessModel;

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);
}

// DataSource — API calls
class BusinessRemoteDataSource {
  final Dio _dio;

  Future<BusinessModel> getById(String id) async {
    final response = await _dio.get('/api/businesses/$id');
    return BusinessModel.fromJson(response.data);
  }
}

// Repository Implementation
class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, Business>> getById(String id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

**Guidelines:**
- ✅ Models are data-specific (JSON serialization)
- ✅ Models provide `.toEntity()` untuk convert ke domain entity
- ✅ Entities provide `.toModel()` untuk convert ke data model (optional)
- ✅ DataSources handle technical implementation details
- ✅ Repository coordinate antara multiple datasources

---

## State Management

### Current Implementation (Business Ideation)

**Type:** Local StatefulWidget state (temporary)

```dart
class WorksheetPageState extends State<WorksheetPage> {
  late final Map<String, List<CanvasItem>> _sectionItems;
  late final Map<String, GlobalKey> _sectionKeys;

  void _addItem(String sectionId) { /* ... */ }
  void _updateItem(CanvasItem item) { /* ... */ }
  void _deleteItem(String itemId) { /* ... */ }
}
```

**Limitations:**
- ❌ No persistence (data hilang saat reload)
- ❌ No async operations
- ❌ No error handling
- ❌ No loading states

### Future Implementation (Planned)

**Type:** BLoC/Cubit untuk complex state

```dart
// Event-based (BLoC)
abstract class WorksheetEvent extends Equatable {}

class AddItemEvent extends WorksheetEvent {
  final String sectionId;
  final String text;
}

// State classes
abstract class WorksheetState extends Equatable {}

class WorksheetLoaded extends WorksheetState {
  final Map<String, List<CanvasItem>> sectionItems;
}

class WorksheetError extends WorksheetState {
  final String message;
}

// BLoC
class WorksheetBloc extends Bloc<WorksheetEvent, WorksheetState> {
  final AddItemUseCase addItemUseCase;

  WorksheetBloc({required this.addItemUseCase}) : super(WorksheetInitial()) {
    on<AddItemEvent>(_onAddItem);
  }

  Future<void> _onAddItem(AddItemEvent event, Emitter<WorksheetState> emit) async {
    final result = await addItemUseCase(event.sectionId, event.text);
    result.fold(
      (failure) => emit(WorksheetError(failure.message)),
      (sectionItems) => emit(WorksheetLoaded(sectionItems)),
    );
  }
}
```

---

## Error Handling

### Failure Hierarchy

```dart
abstract class Failure extends Equatable {}

class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class ValidationFailure extends Failure {
  final String message;
  ValidationFailure(this.message);
}

class NotFoundFailure extends Failure {}

class UnauthorizedFailure extends Failure {}
```

### Either Pattern (from dartz)

```dart
// Success case
Future<Either<Failure, Business>> getBusiness(String id) async {
  try {
    final business = await api.get(id);
    return Right(business); // Success
  } catch (e) {
    return Left(ServerFailure()); // Failure
  }
}

// Usage in BLoC
result.fold(
  (failure) => emit(ErrorState(failure)), // Handle failure
  (business) => emit(SuccessState(business)), // Handle success
);
```

---

## Dependency Injection

**Tool:** get_it

### Service Locator Setup

```dart
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Data Sources
  getIt.registerSingleton<BusinessRemoteDataSource>(
    BusinessRemoteDataSource(dio: getIt()),
  );

  // Repositories
  getIt.registerSingleton<BusinessRepository>(
    BusinessRepositoryImpl(
      remoteDataSource: getIt(),
    ),
  );

  // UseCases
  getIt.registerSingleton<GetBusinessByIdUseCase>(
    GetBusinessByIdUseCase(getIt()),
  );

  // BLoCs
  getIt.registerSingleton<BusinessBloc>(
    BusinessBloc(getIt()),
  );
}
```

### Usage

```dart
// In BLoC
class WorksheetBloc extends Bloc<WorksheetEvent, WorksheetState> {
  final SaveWorksheetUseCase saveWorksheet = getIt();
}

// In presentation
context.read<WorksheetBloc>().add(SaveWorksheetEvent(...));
```

---

## Responsive Design

### Breakpoints

```dart
// From app_dimensions.dart
static const double breakpointMobile = 600.0;
static const double breakpointTablet = 900.0;
static const double breakpointDesktop = 1200.0;
```

### Usage Pattern

```dart
@override
Widget build(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isDesktop = size.width >= AppDimensions.breakpointDesktop;
  final isTablet = size.width >= AppDimensions.breakpointTablet;

  if (isDesktop) {
    return _buildDesktopLayout();
  } else if (isTablet) {
    return _buildTabletLayout();
  } else {
    return _buildMobileLayout();
  }
}
```

### Canvas Widgets Example

```dart
// BMCCanvasWidget
@override
Widget build(BuildContext context) {
  final isDesktop = MediaQuery.sizeOf(context).width >=
    AppDimensions.breakpointDesktop;

  return isDesktop
    ? _buildDesktopLayout() // Complex 9-blok grid
    : _buildMobileLayout(); // Simple vertical list
}
```

---

## Navigation

**Tool:** go_router

### Route Configuration

```dart
// config/routes/app_router.dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/business-ideation',
      builder: (context, state) => const BusinessIdeationPage(),
      routes: [
        GoRoute(
          path: ':businessId',
          builder: (context, state) {
            final businessId = state.pathParameters['businessId']!;
            return BusinessDetailPage(businessId: businessId);
          },
          routes: [
            GoRoute(
              path: 'worksheet/:worksheetKey',
              builder: (context, state) {
                final businessId = state.pathParameters['businessId']!;
                final worksheetKey = state.pathParameters['worksheetKey']!;
                return WorksheetPage(
                  businessId: businessId,
                  worksheetKey: worksheetKey,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
```

### Navigation Usage

```dart
// Navigate to worksheet
context.go('/business-ideation/123/worksheet/business-model-canvas');

// Go back
context.pop();
```

---

## Testing Strategy

### Unit Tests
- Test domain entities, value objects
- Test repository implementations
- Test use cases dengan mocked dependencies

### Widget Tests
- Test UI components in isolation
- Mock BLoCs/Cubits dengan test doubles
- Verify UI updates dengan state changes

### Integration Tests
- Test full user flows
- Real BLoC instances
- Firebase emulator untuk backend testing

---

## Code Generation (freezed)

### Model Definition

```dart
@freezed
class Business with _$Business {
  const factory Business({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> tags,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) =>
      _$BusinessFromJson(json);
}
```

### Generated Code (Auto)
- `copyWith()` method
- `==` dan `hashCode`
- `toString()`
- JSON serialization

### Generate Command
```bash
flutter pub run build_runner build
# atau
make gen
```

---

## Performance Optimization

### Best Practices

1. **Widget Rebuilds**
   - Use `const` constructors
   - Separate stateful & stateless widgets
   - Use `ListView.builder` untuk long lists

2. **Build Runner**
   - Run `make gen` setelah model changes
   - Remove unused imports
   - Cache invalidation saat perlu

3. **Image Optimization**
   - Use `CachedNetworkImage` untuk remote images
   - Optimize local images
   - Lazy load images

4. **Web Optimization**
   - Optimize bundle size
   - Enable compression
   - Use CDN untuk static assets

---

## Security Considerations

1. **API Security**
   - ❌ Jangan hardcode API keys
   - ✅ Use environment variables
   - ✅ Validate server certificates

2. **Data Security**
   - ❌ Jangan hardcode sensitive data
   - ✅ Use secure storage untuk sensitive tokens
   - ✅ Clear sensitive data on logout

3. **Input Validation**
   - ✅ Validate semua user input
   - ✅ Sanitize data sebelum API calls
   - ✅ Handle validation errors gracefully

---

## Development Workflow

### 1. Feature Development
1. Analyze requirements (PRD)
2. Design data flow & architecture
3. Implement domain layer (entities, repositories)
4. Implement data layer (datasources, models)
5. Implement presentation layer (BLoC/state, pages, widgets)
6. Write tests
7. Code review & merge

### 2. Code Quality Checklist
- [ ] No analyzer warnings (except minor ones)
- [ ] All imports used
- [ ] Consistent naming conventions
- [ ] Comments untuk non-obvious code
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Tests written & passing

### 3. Commit Conventions
```
feat(feature-name): Short description
fix(feature-name): Short description
refactor(feature-name): Short description
test(feature-name): Short description
docs: Update documentation
chore: Dependency updates, etc
```

---

## Future Improvements

- [ ] Migrate local state ke BLoC/Cubit
- [ ] Add comprehensive error handling
- [ ] Implement local caching
- [ ] Add analytics & logging
- [ ] Performance profiling & optimization
- [ ] Security audit & improvements
- [ ] Accessibility (a11y) improvements
- [ ] Internationalization (i18n) support

---

**Last Updated:** 2026-03-17
**Maintainer:** AI-Generated
