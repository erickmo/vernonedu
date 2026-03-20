# Flutter ↔ API Integration & Sync Plan

**Version:** 1.0.0
**Status:** Ready to Implement
**Date:** 2026-03-17

---

## 📋 Overview

Sync Flutter Frontend dengan Go API Backend yang sudah production-ready.

### Current State

**API (Go)** ✅ READY
- Clean Architecture + CQRS + Event-Driven
- 5 entities: User, Business, ValuePropositionCanvas, DesignThinking, Item
- All endpoints implemented: `/api/v1/{entities}` CRUD
- Authentication ready (JWT)
- Database migrations ready (PostgreSQL)
- Stack: Chi, Uber FX, PostgreSQL, Redis, NATS

**Flutter** ⚠️ PARTIAL
- UI canvas widgets 100% done
- API client (Dio) setup done
- Network interceptors setup done
- **MISSING:** Data layer, repositories, BLoCs, models

### Gap to Close

```
Flutter UI      ←→  API Client  ←→  Go API
  ✅              ✅               ✅
              (Data Layer)
              (Repositories)
              (Models)
              (BLoCs)
              ❌ MISSING
```

---

## 🎯 Deliverables

### Phase 1: Data Layer (Models)
- [ ] Create API response models matching Go responses
- [ ] Create domain models (clean architecture entities)
- [ ] Create request DTOs
- [ ] Implement model mapping (API response → domain model)

### Phase 2: Data Repositories
- [ ] UserRepository (login, getUser)
- [ ] BusinessRepository (CRUD + list)
- [ ] CanvasRepository (VPC CRUD + list)
- [ ] DesignThinkingRepository (DT CRUD + list)
- [ ] ItemRepository (item CRUD + list)

### Phase 3: Domain Usecases
- [ ] Auth usecase (login, getToken)
- [ ] Business usecase (create, update, delete, list, get)
- [ ] Canvas usecase (create, update, delete, list, get)
- [ ] DesignThinking usecase (create, update, delete, list, get)
- [ ] Item usecase (create, update, delete, list, get)

### Phase 4: State Management (BLoCs)
- [ ] AuthBloc (login, logout, token management)
- [ ] BusinessBloc (CRUD operations)
- [ ] CanvasBloc (CRUD operations)
- [ ] DesignThinkingBloc (CRUD operations)
- [ ] ItemBloc (CRUD operations)

### Phase 5: UI Integration
- [ ] Update worksheet_page.dart to use BLoCs
- [ ] Update business list page to fetch from API
- [ ] Update canvas pages to load/save data from API
- [ ] Add loading/error/success states to UI
- [ ] Handle JWT token refresh

### Phase 6: Testing
- [ ] Unit tests untuk models
- [ ] Repository tests (mocked API)
- [ ] BLoC tests
- [ ] Integration tests dengan real API

---

## 🏗️ Architecture Map

```
lib/features/business_ideation/
│
├── data/
│   ├── datasources/
│   │   ├── business_remote_datasource.dart
│   │   ├── canvas_remote_datasource.dart
│   │   ├── design_thinking_remote_datasource.dart
│   │   ├── item_remote_datasource.dart
│   │   └── auth_remote_datasource.dart
│   │
│   ├── models/
│   │   ├── business_model.dart        ← API response
│   │   ├── canvas_model.dart
│   │   ├── design_thinking_model.dart
│   │   ├── item_model.dart
│   │   └── auth_response_model.dart
│   │
│   └── repositories/
│       ├── business_repository_impl.dart
│       ├── canvas_repository_impl.dart
│       ├── design_thinking_repository_impl.dart
│       ├── item_repository_impl.dart
│       └── auth_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── business.dart              ← Domain model (clean)
│   │   ├── canvas.dart
│   │   ├── design_thinking.dart
│   │   ├── item.dart
│   │   └── user.dart
│   │
│   ├── repositories/
│   │   ├── business_repository.dart   ← Interfaces
│   │   ├── canvas_repository.dart
│   │   ├── design_thinking_repository.dart
│   │   ├── item_repository.dart
│   │   └── auth_repository.dart
│   │
│   └── usecases/
│       ├── business_usecases.dart
│       ├── canvas_usecases.dart
│       ├── design_thinking_usecases.dart
│       ├── item_usecases.dart
│       └── auth_usecases.dart
│
└── presentation/
    ├── bloc/
    │   ├── business_bloc.dart
    │   ├── canvas_bloc.dart
    │   ├── design_thinking_bloc.dart
    │   ├── item_bloc.dart
    │   └── auth_bloc.dart
    │
    ├── pages/
    │   └── worksheet_page.dart        ← Connect to BLoCs
    │
    └── widgets/
        └── (existing canvas widgets)

lib/core/
├── network/
│   ├── api_client.dart                ← Done
│   ├── network_info.dart              ← Done
│   └── api_constants.dart             ← New
```

---

## 📡 API Integration Details

### Base Configuration

**File:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // API
  static const String baseUrl = 'http://localhost:8080';  // Dev
  // static const String baseUrl = 'https://api.vernonedu.local';  // Prod

  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String usersEndpoint = '$apiVersion/users';
  static const String businessesEndpoint = '$apiVersion/businesses';
  static const String canvasesEndpoint = '$apiVersion/canvases';
  static const String designThinkingsEndpoint = '$apiVersion/design-thinkings';
  static const String itemsEndpoint = '$apiVersion/items';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Local storage keys
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
}
```

---

### 1. Models (Data Layer)

**Example: BusinessModel**

```dart
// business_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/business.dart';

part 'business_model.g.dart';

@JsonSerializable()
class BusinessModel {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);

  // Convert to domain entity
  Business toDomain() {
    return Business(
      id: id,
      name: name,
      description: description,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

**Domain Entity (Clean):**

```dart
// domain/entities/business.dart
class Business {
  final String id;
  final String name;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

### 2. Remote Data Sources

**Example: BusinessRemoteDataSource**

```dart
// data/datasources/business_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/business_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessModel>> listBusinesses({int offset = 0, int limit = 10});
  Future<BusinessModel> getBusiness(String id);
  Future<BusinessModel> createBusiness(String name, String? description);
  Future<BusinessModel> updateBusiness(String id, String name, String? description);
  Future<void> deleteBusiness(String id);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final ApiClient _apiClient;

  BusinessRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<BusinessModel>> listBusinesses({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.businessesEndpoint,
        queryParameters: {'offset': offset, 'limit': limit},
      );

      final list = (response.data['data'] as List)
          .map((e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return list;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BusinessModel> getBusiness(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.businessesEndpoint}/$id',
      );
      return BusinessModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BusinessModel> createBusiness(
    String name,
    String? description,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.businessesEndpoint,
        data: {
          'name': name,
          'description': description,
        },
      );
      return BusinessModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BusinessModel> updateBusiness(
    String id,
    String name,
    String? description,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${AppConstants.businessesEndpoint}/$id',
        data: {
          'name': name,
          'description': description,
        },
      );
      return BusinessModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteBusiness(String id) async {
    try {
      await _apiClient.dio.delete(
        '${AppConstants.businessesEndpoint}/$id',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _handleDioError(DioException error) {
    if (error.response?.statusCode == 404) {
      throw Exception('Business not found');
    } else if (error.response?.statusCode == 400) {
      throw Exception('Invalid request');
    }
    return Exception('Network error: ${error.message}');
  }
}
```

---

### 3. Repositories (Domain Layer)

**Interface:**

```dart
// domain/repositories/business_repository.dart
import 'package:dartz/dartz.dart';
import '../entities/business.dart';
import '../../core/errors/failure.dart';

abstract class BusinessRepository {
  Future<Either<Failure, List<Business>>> listBusinesses({
    int offset = 0,
    int limit = 10,
  });
  Future<Either<Failure, Business>> getBusiness(String id);
  Future<Either<Failure, Business>> createBusiness(String name, String? description);
  Future<Either<Failure, Business>> updateBusiness(String id, String name, String? description);
  Future<Either<Failure, void>> deleteBusiness(String id);
}
```

**Implementation:**

```dart
// data/repositories/business_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/business_repository.dart';
import '../../core/errors/failure.dart';
import '../datasources/business_remote_datasource.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource _remoteDataSource;

  BusinessRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Business>>> listBusinesses({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final models = await _remoteDataSource.listBusinesses(
        offset: offset,
        limit: limit,
      );
      return Right(models.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> getBusiness(String id) async {
    try {
      final model = await _remoteDataSource.getBusiness(id);
      return Right(model.toDomain());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> createBusiness(
    String name,
    String? description,
  ) async {
    try {
      final model = await _remoteDataSource.createBusiness(name, description);
      return Right(model.toDomain());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> updateBusiness(
    String id,
    String name,
    String? description,
  ) async {
    try {
      final model = await _remoteDataSource.updateBusiness(id, name, description);
      return Right(model.toDomain());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBusiness(String id) async {
    try {
      await _remoteDataSource.deleteBusiness(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

---

### 4. BLoCs (State Management)

**States:**

```dart
// presentation/bloc/business_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/business.dart';

sealed class BusinessState extends Equatable {
  const BusinessState();

  @override
  List<Object?> get props => [];
}

class BusinessInitial extends BusinessState {
  const BusinessInitial();
}

class BusinessLoading extends BusinessState {
  const BusinessLoading();
}

class BusinessSuccess extends BusinessState {
  final List<Business> businesses;
  const BusinessSuccess(this.businesses);

  @override
  List<Object?> get props => [businesses];
}

class BusinessError extends BusinessState {
  final String message;
  const BusinessError(this.message);

  @override
  List<Object?> get props => [message];
}

class BusinessCreated extends BusinessState {
  final Business business;
  const BusinessCreated(this.business);

  @override
  List<Object?> get props => [business];
}
```

**Events:**

```dart
// presentation/bloc/business_event.dart
import 'package:equatable/equatable.dart';

sealed class BusinessEvent extends Equatable {
  const BusinessEvent();

  @override
  List<Object?> get props => [];
}

class FetchBusinesses extends BusinessEvent {
  final int offset;
  final int limit;

  const FetchBusinesses({this.offset = 0, this.limit = 10});

  @override
  List<Object?> get props => [offset, limit];
}

class CreateBusiness extends BusinessEvent {
  final String name;
  final String? description;

  const CreateBusiness(this.name, this.description);

  @override
  List<Object?> get props => [name, description];
}

class UpdateBusiness extends BusinessEvent {
  final String id;
  final String name;
  final String? description;

  const UpdateBusiness(this.id, this.name, this.description);

  @override
  List<Object?> get props => [id, name, description];
}

class DeleteBusiness extends BusinessEvent {
  final String id;

  const DeleteBusiness(this.id);

  @override
  List<Object?> get props => [id];
}
```

**BLoC:**

```dart
// presentation/bloc/business_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/business_repository.dart';
import 'business_event.dart';
import 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository _repository;

  BusinessBloc(this._repository) : super(const BusinessInitial()) {
    on<FetchBusinesses>(_onFetchBusinesses);
    on<CreateBusiness>(_onCreateBusiness);
    on<UpdateBusiness>(_onUpdateBusiness);
    on<DeleteBusiness>(_onDeleteBusiness);
  }

  Future<void> _onFetchBusinesses(
    FetchBusinesses event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.listBusinesses(
      offset: event.offset,
      limit: event.limit,
    );
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (businesses) => emit(BusinessSuccess(businesses)),
    );
  }

  Future<void> _onCreateBusiness(
    CreateBusiness event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.createBusiness(
      event.name,
      event.description,
    );
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (business) => emit(BusinessCreated(business)),
    );
  }

  Future<void> _onUpdateBusiness(
    UpdateBusiness event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.updateBusiness(
      event.id,
      event.name,
      event.description,
    );
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (business) => emit(BusinessCreated(business)),
    );
  }

  Future<void> _onDeleteBusiness(
    DeleteBusiness event,
    Emitter<BusinessState> emit,
  ) async {
    emit(const BusinessLoading());
    final result = await _repository.deleteBusiness(event.id);
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (_) => emit(const BusinessInitial()), // Reload list
    );
  }
}
```

---

## 📱 UI Integration

### Update Worksheet Page

```dart
// presentation/pages/worksheet_page.dart
class WorksheetPage extends StatefulWidget {
  // ... existing code ...

  @override
  State<WorksheetPage> createState() => _WorksheetPageState();
}

class _WorksheetPageState extends State<WorksheetPage> {
  late final ScrollController _scrollController;

  // Local state untuk canvas items (masih digunakan)
  late final Map<String, List<CanvasItem>> _sectionItems;
  late final Map<String, GlobalKey> _sectionKeys;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeCanvasSections();

    // Load dari API saat page init
    _loadWorksheet();
  }

  void _loadWorksheet() {
    // Get dari context BLoC
    context.read<WorksheetBloc>().add(
      FetchWorksheet(
        businessId: widget.businessId,
        worksheetId: widget.worksheetId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorksheetBloc, WorksheetState>(
      listener: (context, state) {
        if (state is WorksheetLoaded) {
          // Update local state dengan data dari API
          _syncCanvasItemsFromAPI(state.worksheet);
        } else if (state is WorksheetError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<WorksheetBloc, WorksheetState>(
        builder: (context, state) {
          if (state is WorksheetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            // ... existing UI code ...
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _saveDraft,
                  tooltip: 'Simpan Draft',
                  child: const Icon(Icons.save),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _submitWorksheet,
                  tooltip: 'Submit',
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveDraft() {
    context.read<CanvasItemBloc>().add(
      SaveCanvasItems(
        worksheetId: widget.worksheetId,
        items: _getAllCanvasItems(),
      ),
    );
  }

  void _submitWorksheet() {
    context.read<WorksheetBloc>().add(
      SubmitWorksheet(
        businessId: widget.businessId,
        worksheetId: widget.worksheetId,
      ),
    );
  }
}
```

---

## ✅ Implementation Checklist

### Phase 1: Models
- [ ] Create `business_model.dart` with JSON serialization
- [ ] Create `canvas_model.dart`
- [ ] Create `design_thinking_model.dart`
- [ ] Create `item_model.dart`
- [ ] Create `auth_response_model.dart`
- [ ] Create domain entities for each model
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`

### Phase 2: Repositories
- [ ] Create `business_remote_datasource.dart`
- [ ] Create `canvas_remote_datasource.dart`
- [ ] Create `design_thinking_remote_datasource.dart`
- [ ] Create `item_remote_datasource.dart`
- [ ] Create `auth_remote_datasource.dart`
- [ ] Create repository interfaces in domain
- [ ] Implement repositories with error handling

### Phase 3: BLoCs
- [ ] Create BusinessBloc + events + states
- [ ] Create CanvasBloc + events + states
- [ ] Create DesignThinkingBloc + events + states
- [ ] Create ItemBloc + events + states
- [ ] Create AuthBloc + JWT token management
- [ ] Register BLoCs in get_it DI container

### Phase 4: UI Integration
- [ ] Update worksheet_page.dart to use BLoCs
- [ ] Update business list page
- [ ] Add loading/error states to UI
- [ ] Implement JWT token refresh logic
- [ ] Test all CRUD operations

### Phase 5: Testing
- [ ] Unit tests untuk models
- [ ] Repository tests (mocked API)
- [ ] BLoC tests
- [ ] Integration tests dengan real API

---

## 🚀 Next Steps

1. **Start Phase 1:** Create models with JSON serialization
   - Use `flutter-coding-standard` skill for code generation
   - Use `json_annotation` + `build_runner`

2. **Execute Phase 2:** Build repositories
   - Implement data sources
   - Map API responses to domain entities
   - Handle errors properly

3. **Build Phase 3:** Create BLoCs
   - Use provided event/state examples
   - Implement proper state management
   - Handle loading/error states

4. **Connect Phase 4:** Update UI pages
   - Replace local state with BLoC state
   - Add BLoC listeners for API updates
   - Test with running API

5. **Validate Phase 5:** Write tests
   - Unit test models and mapping
   - Test repository CRUD
   - Integration tests with API

---

## 📡 API Endpoints Reference

All endpoints di: `/api/v1/`

```
Users:
POST   /users                    → Create
GET    /users?offset=0&limit=10  → List
GET    /users/search?name=xxx    → Search
GET    /users/{id}               → Get
PUT    /users/{id}               → Update
DELETE /users/{id}               → Delete

Businesses:
POST   /businesses               → Create
GET    /businesses               → List
GET    /businesses/search        → Search
GET    /businesses/{id}          → Get
PUT    /businesses/{id}          → Update
DELETE /businesses/{id}          → Delete

Canvases (Value Proposition):
POST   /canvases                 → Create
GET    /canvases                 → List
GET    /canvases/search          → Search
GET    /canvases/{id}            → Get
PUT    /canvases/{id}            → Update
DELETE /canvases/{id}            → Delete

Design Thinkings:
POST   /design-thinkings         → Create
GET    /design-thinkings         → List
GET    /design-thinkings/search  → Search
GET    /design-thinkings/{id}    → Get
PUT    /design-thinkings/{id}    → Update
DELETE /design-thinkings/{id}    → Delete

Items:
POST   /items                    → Create
GET    /items                    → List
GET    /items/search             → Search
GET    /items/{id}               → Get
PUT    /items/{id}               → Update
DELETE /items/{id}               → Delete
```

**Authentication:**
- Header: `Authorization: Bearer {token}`
- Token from login endpoint

---

**Ready to implement! Use `flutter-coding-standard` skill untuk semua code generation.** 🚀
