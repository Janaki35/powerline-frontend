import 'dart:io';

Future<String?> readLocalFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        return content;
      }
    }
  } catch (_) {}
  return null;
}
