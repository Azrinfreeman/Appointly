import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

Future<void> exportCalendarFile(
  String content,
  String fileName,
  String subject,
) async {
  final parts = <BlobPart>[content.toJS].toJS;
  final blob =
      Blob(parts, BlobPropertyBag(type: 'text/calendar;charset=utf-8'));
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = fileName;

  try {
    document.body?.append(anchor);
    anchor.click();
  } finally {
    anchor.remove();
    // The browser needs the URL to remain valid while it starts the download.
    Timer(const Duration(seconds: 1), () => URL.revokeObjectURL(url));
  }
}
