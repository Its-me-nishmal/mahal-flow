import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to a temp file and opens the system share sheet for it.
/// Returns false when the user dismissed the sheet; throws on I/O failure.
Future<bool> shareGeneratedFile(
  BuildContext context, {
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  // Read the anchor (iPad popover origin) before any await.
  Rect? origin;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType, name: fileName)],
      subject: subject,
      sharePositionOrigin: origin,
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}

/// "Mahal Name" → "Mahal_Name" for file names.
String safeFileStem(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^A-Za-z0-9\-]+'), '_');
  final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? 'MahalFlow' : trimmed;
}
