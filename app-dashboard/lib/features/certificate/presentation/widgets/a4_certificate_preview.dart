import 'package:flutter/material.dart';

import '../../domain/entities/certificate_template_entity.dart';

/// A4 portrait aspect ratio at 72 DPI: 595 / 842.
const double _a4AspectRatio = 595.0 / 842.0;
const double _qrSize = 80.0;
const double _qrMargin = 32.0;
const double _signatureLineWidth = 120.0;
const double _bodyRightMarginRatio = 0.1;
const String _qrPosNone = 'none';
const String _qrPosTopLeft = 'top-left';
const String _qrPosTopRight = 'top-right';
const String _qrPosBottomLeft = 'bottom-left';
const String _qrPosBottomRight = 'bottom-right';

/// Live A4 preview of a certificate template. Coordinates are normalized
/// (0.0–1.0) so the preview scales with the available width.
class A4CertificatePreview extends StatelessWidget {
  final CertificateTemplateEntity config;

  const A4CertificatePreview({required this.config, super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _a4AspectRatio,
      child: Container(
        decoration: _decoration(),
        child: LayoutBuilder(
          builder: (ctx, c) => Stack(
            children: [
              _title(c),
              _body(c),
              ...config.signatureBlocks.map((s) => _signature(c, s)),
              if (config.qrPosition != _qrPosNone) _qr(c),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    final hasBg =
        config.backgroundUrl != null && config.backgroundUrl!.isNotEmpty;
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade400),
      image: hasBg
          ? DecorationImage(
              image: NetworkImage(config.backgroundUrl!),
              fit: BoxFit.cover,
              onError: (_, __) {},
            )
          : null,
    );
  }

  Widget _title(BoxConstraints c) => Positioned(
        left: c.maxWidth * config.titleX,
        top: c.maxHeight * config.titleY,
        child: Text(
          config.title,
          style: TextStyle(
            fontSize: config.titleSize,
            fontFamily: config.fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );

  Widget _body(BoxConstraints c) => Positioned(
        left: c.maxWidth * config.bodyX,
        top: c.maxHeight * config.bodyY,
        right: c.maxWidth * _bodyRightMarginRatio,
        child: Text(
          config.bodyText,
          style: TextStyle(
            fontSize: config.titleSize * 0.5,
            fontFamily: config.fontFamily,
            color: Colors.black87,
          ),
        ),
      );

  Widget _signature(BoxConstraints c, SignatureBlockEntity s) => Positioned(
        left: c.maxWidth * s.x,
        top: c.maxHeight * s.y,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _signatureLineWidth,
              height: 1,
              color: Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              s.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            Text(
              s.role,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );

  Widget _qr(BoxConstraints c) => Positioned(
        left: _qrLeft(c.maxWidth, config.qrPosition),
        top: _qrTop(c.maxHeight, config.qrPosition),
        right: _qrRight(c.maxWidth, config.qrPosition),
        bottom: _qrBottom(c.maxHeight, config.qrPosition),
        child: Container(
          width: _qrSize,
          height: _qrSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.qr_code_2, size: 60),
        ),
      );

  double? _qrLeft(double w, String pos) {
    if (pos == _qrPosTopLeft || pos == _qrPosBottomLeft) return _qrMargin;
    return null;
  }

  double? _qrTop(double h, String pos) {
    if (pos == _qrPosTopLeft || pos == _qrPosTopRight) return _qrMargin;
    return null;
  }

  double? _qrRight(double w, String pos) {
    if (pos == _qrPosTopRight || pos == _qrPosBottomRight) return _qrMargin;
    return null;
  }

  double? _qrBottom(double h, String pos) {
    if (pos == _qrPosBottomLeft || pos == _qrPosBottomRight) return _qrMargin;
    return null;
  }
}
