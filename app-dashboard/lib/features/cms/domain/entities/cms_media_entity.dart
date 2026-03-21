import 'package:equatable/equatable.dart';

class CmsMediaEntity extends Equatable {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;
  final DateTime uploadedAt;

  const CmsMediaEntity({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  bool get isImage => type.startsWith('image/');

  String get sizeLabel {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  List<Object?> get props => [id];
}
