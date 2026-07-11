import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String> writeGeneratedFileForOpen({
  required Uint8List bytes,
  required String fileName,
}) async {
  final directory = await getTemporaryDirectory();
  final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  final file = File('${directory.path}${Platform.pathSeparator}$safeFileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<bool> openGeneratedFile({
  required String path,
  required String mimeType,
}) async {
  final result = await OpenFilex.open(path, type: mimeType);
  return result.type == ResultType.done;
}
