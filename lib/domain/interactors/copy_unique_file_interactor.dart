import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CopyUniqueFileInteractor {
  static CopyUniqueFileInteractor? _instance;

  factory CopyUniqueFileInteractor.getInstance() =>
      _instance ??= CopyUniqueFileInteractor._internal();

  CopyUniqueFileInteractor._internal();

  Future<String> copyUniqueFile({
    required final String directoryWithFiles,
    required final String filePath,
  }) async {
    final docsPath = await getApplicationDocumentsDirectory();
    final dirName =
        "${docsPath.absolute.path}${Platform.pathSeparator}$directoryWithFiles";
    await Directory(dirName).create(recursive: true);
    final imageName = filePath.split(Platform.pathSeparator).last;
    String newImagePath = "$dirName${Platform.pathSeparator}$imageName";
    var existingFile = File(newImagePath);
    final tempFile = File(filePath);
    if (existingFile.existsSync()) {
      if (existingFile.statSync().size == tempFile.statSync().size) {
        return newImagePath.replaceFirst(dirName + Platform.pathSeparator, "");
      }
      int counter = 0;
      final isNumeric = RegExp(r"^(\d+)$");
      while (existingFile.existsSync()) {
        final nameParts = imageName.split(".");
        String baseName, ext = "";
        if (nameParts.length < 2) {
          baseName = nameParts.join(".");
        } else {
          baseName = nameParts.getRange(0, nameParts.length - 1).join(".");
          ext = nameParts.last;
        }
        final baseParts = baseName.split("_");
        if (baseParts.length < 2 || !isNumeric.hasMatch(baseParts.last)) {
          counter = 0;
        } else {
          counter = int.parse(baseParts.last);
          baseName = baseParts.getRange(0, baseParts.length - 1).join("_");
        }
        counter++;
        newImagePath =
            "$dirName${Platform.pathSeparator}${baseName}_$counter.$ext";
        existingFile = File(newImagePath);
      }
    }
    await tempFile.copy(newImagePath);
    return newImagePath.replaceFirst(dirName + Platform.pathSeparator, "");
  }
}
