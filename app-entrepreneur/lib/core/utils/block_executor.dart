
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block_type.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/execution_result.dart';

/// Jumlah iterasi maksimum sebelum dianggap infinite loop.
const int _kMaxIterations = 1000;

/// Menjalankan program yang tersusun dari daftar [Block].
///
/// Eksekutor bersifat sinkronus — tidak ada async I/O.
/// Input dari [askBlock] diambil dari [simulatedInputs] secara berurutan.
class BlockExecutor {
  final List<String> simulatedInputs;
  final Map<String, dynamic> _variables = {};
  final List<String> _output = [];
  int _inputIndex = 0;
  int _totalIterations = 0;

  BlockExecutor({List<String>? simulatedInputs})
      : simulatedInputs = simulatedInputs ?? [];

  /// Jalankan program dan kembalikan [ExecutionResult].
  ExecutionResult execute(List<Block> blocks) {
    _variables.clear();
    _output.clear();
    _inputIndex = 0;
    _totalIterations = 0;

    final stopwatch = Stopwatch()..start();

    try {
      _executeSequence(blocks);
      stopwatch.stop();
      return ExecutionResult.success(
        outputLines: List.unmodifiable(_output),
        finalVariables: Map.unmodifiable(_variables),
        executionTime: stopwatch.elapsed,
      );
    } on _ExecutionException catch (e) {
      stopwatch.stop();
      return ExecutionResult.failure(e.message);
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult.failure(
        '${'Program error saat dijalankan'}: $e',
      );
    }
  }

  void _executeSequence(List<Block> blocks) {
    for (final block in blocks) {
      _executeBlock(block);
    }
  }

  void _executeBlock(Block block) {
    _checkIterationLimit();

    switch (block.type) {
      case BlockType.start:
      case BlockType.end:
        break;

      case BlockType.printBlock:
        final text = _resolveValue(block.params['text'] ?? '');
        _output.add(_formatValue(text));

      case BlockType.askBlock:
        final question = block.params['question'] ?? 'Input:';
        final varName = block.params['variable'] ?? 'input';
        final input = _readInput(question);
        _variables[varName] = input;
        _output.add('$question $input');

      case BlockType.setVarBlock:
        final name = block.params['name'] ?? 'x';
        final value = block.params['value'] ?? '0';
        _variables[name] = _parseValue(value);

      case BlockType.changeVarBlock:
        final name = block.params['name'] ?? 'x';
        final delta = block.params['delta'] ?? '1';
        final current = _toNumber(_variables[name] ?? 0);
        final deltaVal = _toNumber(_parseValue(delta));
        _variables[name] = current + deltaVal;

      case BlockType.repeatBlock:
        final countStr = block.params['count'] ?? '1';
        final count = (_toNumber(_parseValue(countStr))).round().clamp(0, 999);
        for (int i = 0; i < count; i++) {
          _checkIterationLimit();
          _executeSequence(block.innerBlocks);
        }

      case BlockType.whileBlock:
        final condition = block.params['condition'] ?? 'false';
        int loopCount = 0;
        while (_evalCondition(condition)) {
          _checkIterationLimit();
          if (loopCount++ > _kMaxIterations) {
            throw _ExecutionException('Program berhenti: terlalu banyak pengulangan');
          }
          _executeSequence(block.innerBlocks);
        }

      case BlockType.ifBlock:
        final condition = block.params['condition'] ?? 'false';
        if (_evalCondition(condition)) {
          _executeSequence(block.innerBlocks);
        }

      case BlockType.ifElseBlock:
        final condition = block.params['condition'] ?? 'false';
        if (_evalCondition(condition)) {
          _executeSequence(block.innerBlocks);
        } else {
          _executeSequence(block.elseBlocks);
        }

      case BlockType.mathAddBlock:
        _executeMath(block, (a, b) => a + b);

      case BlockType.mathSubBlock:
        _executeMath(block, (a, b) => a - b);

      case BlockType.mathMulBlock:
        _executeMath(block, (a, b) => a * b);

      case BlockType.mathDivBlock:
        _executeMath(block, (a, b) {
          if (b == 0) throw _ExecutionException('Error: tidak bisa membagi dengan nol');
          return a / b;
        });

      case BlockType.compareBlock:
        final a = _toNumber(_resolveValue(block.params['a'] ?? '0'));
        final b = _toNumber(_resolveValue(block.params['b'] ?? '0'));
        final op = block.params['op'] ?? '>';
        final result = _compare(a, b, op);
        final resultVar = block.params['result'] ?? 'hasil';
        _variables[resultVar] = result;

      case BlockType.andBlock:
        final a = _toBool(_resolveValue(block.params['a'] ?? 'false'));
        final bVal = _toBool(_resolveValue(block.params['b'] ?? 'false'));
        _variables[block.params['result'] ?? 'hasil'] = a && bVal;

      case BlockType.orBlock:
        final a = _toBool(_resolveValue(block.params['a'] ?? 'false'));
        final bVal = _toBool(_resolveValue(block.params['b'] ?? 'false'));
        _variables[block.params['result'] ?? 'hasil'] = a || bVal;

      case BlockType.notBlock:
        final a = _toBool(_resolveValue(block.params['a'] ?? 'false'));
        _variables[block.params['result'] ?? 'hasil'] = !a;
    }
  }

  void _executeMath(Block block, num Function(num a, num b) op) {
    final a = _toNumber(_resolveValue(block.params['a'] ?? '0'));
    final b = _toNumber(_resolveValue(block.params['b'] ?? '0'));
    final result = op(a, b);
    final resultVar = block.params['result'] ?? 'hasil';
    _variables[resultVar] = result;
  }

  /// Resolve nilai: jika string adalah nama variabel yang ada, kembalikan nilainya.
  dynamic _resolveValue(String value) {
    if (_variables.containsKey(value)) return _variables[value];
    return _parseValue(value);
  }

  /// Parse string menjadi angka atau bool atau tetap string.
  dynamic _parseValue(String value) {
    final asNum = num.tryParse(value);
    if (asNum != null) return asNum;
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return value;
  }

  num _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty && value.toLowerCase() != 'false';
    return false;
  }

  bool _evalCondition(String condition) {
    // Resolve simple variable conditions like "x < 10", "x == 5"
    final trimmed = condition.trim();

    // Check if it's a variable name (boolean variable)
    if (_variables.containsKey(trimmed)) {
      return _toBool(_variables[trimmed]);
    }

    // Try to parse "a op b"
    final ops = ['>=', '<=', '==', '!=', '>', '<'];
    for (final op in ops) {
      if (trimmed.contains(op)) {
        final parts = trimmed.split(op);
        if (parts.length == 2) {
          final a = _toNumber(_resolveValue(parts[0].trim()));
          final b = _toNumber(_resolveValue(parts[1].trim()));
          return _compare(a, b, op);
        }
      }
    }

    return _toBool(_parseValue(trimmed));
  }

  bool _compare(num a, num b, String op) {
    switch (op) {
      case '>':
        return a > b;
      case '<':
        return a < b;
      case '>=':
        return a >= b;
      case '<=':
        return a <= b;
      case '==':
        return a == b;
      case '!=':
        return a != b;
      default:
        return false;
    }
  }

  String _readInput(String question) {
    if (_inputIndex < simulatedInputs.length) {
      return simulatedInputs[_inputIndex++];
    }
    // Default input jika tidak ada simulasi
    return '0';
  }

  void _checkIterationLimit() {
    _totalIterations++;
    if (_totalIterations > _kMaxIterations * 10) {
      throw _ExecutionException('Program berhenti: terlalu banyak pengulangan');
    }
  }

  /// Format nilai numerik agar tampil rapi (hilangkan desimal .0 jika bilangan bulat).
  String _formatValue(dynamic value) {
    if (value is double) {
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }
}

class _ExecutionException implements Exception {
  final String message;
  const _ExecutionException(this.message);
}
