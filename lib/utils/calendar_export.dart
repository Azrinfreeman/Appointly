import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportCalendarFile(
  String content,
  String fileName,
  String subject,
) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
  final calendar = XFile(file.path, mimeType: 'text/calendar');
  await Share.shareXFiles([calendar], subject: subject);
}
