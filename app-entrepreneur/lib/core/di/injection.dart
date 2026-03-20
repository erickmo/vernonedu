import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// Business Ideation
import '../../features/business_ideation/data/datasources/business_remote_datasource.dart';
import '../../features/business_ideation/data/datasources/canvas_item_remote_datasource.dart';
import '../../features/business_ideation/data/repositories/business_repository_impl.dart';
import '../../features/business_ideation/data/repositories/canvas_item_repository_impl.dart';
import '../../features/business_ideation/domain/repositories/business_repository.dart';
import '../../features/business_ideation/domain/repositories/canvas_item_repository.dart';
import '../../features/business_ideation/domain/usecases/create_business_usecase.dart';
import '../../features/business_ideation/domain/usecases/create_canvas_item_usecase.dart';
import '../../features/business_ideation/domain/usecases/delete_business_usecase.dart';
import '../../features/business_ideation/domain/usecases/delete_canvas_item_usecase.dart';
import '../../features/business_ideation/domain/usecases/get_business_by_id_usecase.dart';
import '../../features/business_ideation/domain/usecases/get_businesses_usecase.dart';
import '../../features/business_ideation/domain/usecases/get_canvas_items_usecase.dart';
import '../../features/business_ideation/domain/usecases/update_business_usecase.dart';
import '../../features/business_ideation/domain/usecases/update_canvas_item_usecase.dart';
import '../../features/business_ideation/presentation/cubit/business_cubit.dart';
import '../../features/business_ideation/presentation/cubit/canvas_item_cubit.dart';

final getIt = GetIt.instance;

/// Inisialisasi dependency injection.
/// Dipanggil satu kali di main() sebelum runApp().
Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<Connectivity>(Connectivity());

  // Core
  getIt.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(getIt<Connectivity>()),
  );
  getIt.registerSingleton<ApiClient>(ApiClient(getIt<SharedPreferences>()));

  // Auth
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(loginUseCase: getIt<LoginUseCase>()),
  );

  // Business Ideation
  getIt.registerLazySingleton<BusinessRemoteDataSource>(
    () => BusinessRemoteDataSourceImpl(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(
      remoteDataSource: getIt<BusinessRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerLazySingleton<GetBusinessesUseCase>(
    () => GetBusinessesUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerLazySingleton<GetBusinessByIdUseCase>(
    () => GetBusinessByIdUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerLazySingleton<CreateBusinessUseCase>(
    () => CreateBusinessUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerLazySingleton<UpdateBusinessUseCase>(
    () => UpdateBusinessUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerLazySingleton<DeleteBusinessUseCase>(
    () => DeleteBusinessUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerFactory<BusinessCubit>(
    () => BusinessCubit(
      getBusinessesUseCase: getIt<GetBusinessesUseCase>(),
      getBusinessByIdUseCase: getIt<GetBusinessByIdUseCase>(),
      createBusinessUseCase: getIt<CreateBusinessUseCase>(),
      updateBusinessUseCase: getIt<UpdateBusinessUseCase>(),
      deleteBusinessUseCase: getIt<DeleteBusinessUseCase>(),
    ),
  );

  // Canvas Items
  getIt.registerLazySingleton<CanvasItemRemoteDataSource>(
    () => CanvasItemRemoteDataSourceImpl(dio: getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<CanvasItemRepository>(
    () => CanvasItemRepositoryImpl(
      remoteDataSource: getIt<CanvasItemRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerLazySingleton<GetCanvasItemsUseCase>(
    () => GetCanvasItemsUseCase(getIt<CanvasItemRepository>()),
  );
  getIt.registerLazySingleton<CreateCanvasItemUseCase>(
    () => CreateCanvasItemUseCase(getIt<CanvasItemRepository>()),
  );
  getIt.registerLazySingleton<UpdateCanvasItemUseCase>(
    () => UpdateCanvasItemUseCase(getIt<CanvasItemRepository>()),
  );
  getIt.registerLazySingleton<DeleteCanvasItemUseCase>(
    () => DeleteCanvasItemUseCase(getIt<CanvasItemRepository>()),
  );
  getIt.registerFactory<CanvasItemCubit>(
    () => CanvasItemCubit(
      getCanvasItemsUseCase: getIt<GetCanvasItemsUseCase>(),
      createCanvasItemUseCase: getIt<CreateCanvasItemUseCase>(),
      updateCanvasItemUseCase: getIt<UpdateCanvasItemUseCase>(),
      deleteCanvasItemUseCase: getIt<DeleteCanvasItemUseCase>(),
    ),
  );
}
