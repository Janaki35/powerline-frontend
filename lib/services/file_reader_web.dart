Future<String?> readLocalFile(String path) async {
  // Direct disk paths are not accessible in web sandbox; falls back to rootBundle
  return null;
}
