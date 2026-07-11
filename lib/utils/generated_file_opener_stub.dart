import 'dart:typed_data';

Future<String> writeGeneratedFileForOpen({
  required Uint8List bytes,
  required String fileName,
}) {
  throw UnsupportedError('Opening generated files is not supported here.');
}

Future<bool> openGeneratedFile({
  required String path,
  required String mimeType,
}) async {
  return false;
}
