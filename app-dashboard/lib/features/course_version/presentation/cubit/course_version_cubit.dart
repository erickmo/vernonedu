import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_course_versions_usecase.dart';
import '../../domain/usecases/create_course_version_usecase.dart';
import '../../domain/usecases/promote_course_version_usecase.dart';
import '../../domain/usecases/get_internship_config_usecase.dart';
import '../../domain/usecases/upsert_internship_config_usecase.dart';
import '../../domain/usecases/get_character_test_config_usecase.dart';
import '../../domain/usecases/upsert_character_test_config_usecase.dart';
import 'course_version_state.dart';

// Cubit for managing CourseVersion list state per course type.
// Supports program_karir type with InternshipConfig and CharacterTestConfig.
class CourseVersionCubit extends Cubit<CourseVersionState> {
  final GetCourseVersionsUseCase getCourseVersionsUseCase;
  final CreateCourseVersionUseCase createCourseVersionUseCase;
  final PromoteCourseVersionUseCase promoteCourseVersionUseCase;
  final GetInternshipConfigUseCase getInternshipConfigUseCase;
  final UpsertInternshipConfigUseCase upsertInternshipConfigUseCase;
  final GetCharacterTestConfigUseCase getCharacterTestConfigUseCase;
  final UpsertCharacterTestConfigUseCase upsertCharacterTestConfigUseCase;

  CourseVersionCubit({
    required this.getCourseVersionsUseCase,
    required this.createCourseVersionUseCase,
    required this.promoteCourseVersionUseCase,
    required this.getInternshipConfigUseCase,
    required this.upsertInternshipConfigUseCase,
    required this.getCharacterTestConfigUseCase,
    required this.upsertCharacterTestConfigUseCase,
  }) : super(const CourseVersionInitial());

  // Load all versions by type ID.
  // If typeName == 'program_karir', also loads InternshipConfig and CharacterTestConfig
  // using the approved version ID (first approved found), or the latest version.
  Future<void> loadVersions(String typeId, {String? typeName}) async {
    emit(const CourseVersionLoading());
    final result = await getCourseVersionsUseCase(typeId);
    result.fold(
      (failure) => emit(CourseVersionError(failure.message)),
      (versions) async {
        // For non-program_karir types, emit loaded state immediately
        if (typeName != 'program_karir' || versions.isEmpty) {
          emit(CourseVersionLoaded(versions));
          return;
        }

        // Find the approved version, or fall back to the latest version
        final targetVersion = versions.firstWhere(
          (v) => v.isApproved,
          orElse: () => versions.first,
        );

        // Load both configs in parallel for program_karir
        final configs = await Future.wait([
          getInternshipConfigUseCase(targetVersion.id),
          getCharacterTestConfigUseCase(targetVersion.id),
        ]);

        final internshipConfig = configs[0].fold((_) => null, (c) => c);
        final characterTestConfig = configs[1].fold((_) => null, (c) => c);

        emit(CourseVersionLoaded(
          versions,
          internshipConfig: internshipConfig,
          characterTestConfig: characterTestConfig,
        ));
      },
    );
  }

  // Load configs for a specific version ID (called when page loads version detail for program_karir).
  Future<void> loadConfigs(String versionId) async {
    final current = state;
    if (current is! CourseVersionLoaded) return;

    final configs = await Future.wait([
      getInternshipConfigUseCase(versionId),
      getCharacterTestConfigUseCase(versionId),
    ]);

    final internshipConfig = configs[0].fold((_) => null, (c) => c);
    final characterTestConfig = configs[1].fold((_) => null, (c) => c);

    emit(current.copyWith(
      internshipConfig: internshipConfig,
      characterTestConfig: characterTestConfig,
    ));
  }

  // Create a new version then reload
  Future<bool> createVersion(String typeId, Map<String, dynamic> data, {String? typeName}) async {
    final result = await createCourseVersionUseCase(typeId, data);
    return result.fold(
      (failure) {
        emit(CourseVersionError(failure.message));
        return false;
      },
      (_) {
        loadVersions(typeId, typeName: typeName);
        return true;
      },
    );
  }

  // Promote a version (draft → review → approved) then reload
  Future<bool> promoteVersion(String versionId, String targetStatus, String typeId, {String? typeName}) async {
    final result = await promoteCourseVersionUseCase(versionId, targetStatus);
    return result.fold(
      (failure) {
        emit(CourseVersionError(failure.message));
        return false;
      },
      (_) {
        loadVersions(typeId, typeName: typeName);
        return true;
      },
    );
  }

  // Save InternshipConfig for the given version ID.
  // On success, refreshes the internshipConfig in the current loaded state.
  Future<bool> saveInternshipConfig(String versionId, Map<String, dynamic> data) async {
    final result = await upsertInternshipConfigUseCase(versionId, data);
    return result.fold(
      (failure) {
        emit(CourseVersionError(failure.message));
        return false;
      },
      (_) async {
        // Reload config after save
        final configResult = await getInternshipConfigUseCase(versionId);
        final current = state;
        if (current is CourseVersionLoaded) {
          emit(current.copyWith(
            internshipConfig: configResult.fold((_) => null, (c) => c),
          ));
        }
        return true;
      },
    );
  }

  // Save CharacterTestConfig for the given version ID.
  // On success, refreshes the characterTestConfig in the current loaded state.
  Future<bool> saveCharacterTestConfig(String versionId, Map<String, dynamic> data) async {
    final result = await upsertCharacterTestConfigUseCase(versionId, data);
    return result.fold(
      (failure) {
        emit(CourseVersionError(failure.message));
        return false;
      },
      (_) async {
        // Reload config after save
        final configResult = await getCharacterTestConfigUseCase(versionId);
        final current = state;
        if (current is CourseVersionLoaded) {
          emit(current.copyWith(
            characterTestConfig: configResult.fold((_) => null, (c) => c),
          ));
        }
        return true;
      },
    );
  }
}
