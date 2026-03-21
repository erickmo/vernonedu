import 'package:equatable/equatable.dart';

/// Hasil eksekusi program blok.
class ExecutionResult extends Equatable {
  final bool isSuccess;
  final List<String> outputLines;
  final String? errorMessage;
  final Map<String, dynamic> finalVariables;
  final Duration executionTime;

  const ExecutionResult({
    required this.isSuccess,
    required this.outputLines,
    this.errorMessage,
    this.finalVariables = const {},
    this.executionTime = Duration.zero,
  });

  factory ExecutionResult.success({
    required List<String> outputLines,
    Map<String, dynamic>? finalVariables,
    Duration? executionTime,
  }) {
    return ExecutionResult(
      isSuccess: true,
      outputLines: outputLines,
      finalVariables: finalVariables ?? {},
      executionTime: executionTime ?? Duration.zero,
    );
  }

  factory ExecutionResult.failure(String errorMessage) {
    return ExecutionResult(
      isSuccess: false,
      outputLines: [],
      errorMessage: errorMessage,
    );
  }

  String get outputText => outputLines.join('\n');

  @override
  List<Object?> get props => [
        isSuccess,
        outputLines,
        errorMessage,
        finalVariables,
        executionTime,
      ];
}
