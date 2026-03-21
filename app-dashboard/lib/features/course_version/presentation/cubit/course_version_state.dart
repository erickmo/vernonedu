import 'package:equatable/equatable.dart';
import '../../domain/entities/course_version_entity.dart';
import '../../domain/entities/internship_config_entity.dart';
import '../../domain/entities/character_test_config_entity.dart';

abstract class CourseVersionState extends Equatable {
  const CourseVersionState();
  @override
  List<Object?> get props => [];
}

class CourseVersionInitial extends CourseVersionState {
  const CourseVersionInitial();
}

class CourseVersionLoading extends CourseVersionState {
  const CourseVersionLoading();
}

// State when version list is successfully loaded.
// For program_karir types, internshipConfig and characterTestConfig are populated.
class CourseVersionLoaded extends CourseVersionState {
  final List<CourseVersionEntity> versions;
  final InternshipConfigEntity? internshipConfig;
  final CharacterTestConfigEntity? characterTestConfig;

  const CourseVersionLoaded(
    this.versions, {
    this.internshipConfig,
    this.characterTestConfig,
  });

  // Returns a copy with updated fields
  CourseVersionLoaded copyWith({
    List<CourseVersionEntity>? versions,
    // Use a sentinel to distinguish "not provided" from "set to null"
    Object? internshipConfig = _sentinel,
    Object? characterTestConfig = _sentinel,
  }) {
    return CourseVersionLoaded(
      versions ?? this.versions,
      internshipConfig: internshipConfig == _sentinel
          ? this.internshipConfig
          : internshipConfig as InternshipConfigEntity?,
      characterTestConfig: characterTestConfig == _sentinel
          ? this.characterTestConfig
          : characterTestConfig as CharacterTestConfigEntity?,
    );
  }

  @override
  List<Object?> get props => [versions, internshipConfig, characterTestConfig];
}

class CourseVersionError extends CourseVersionState {
  final String message;
  const CourseVersionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Sentinel object used by copyWith to distinguish null from "not provided"
const Object _sentinel = Object();
