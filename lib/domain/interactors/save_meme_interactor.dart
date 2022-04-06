import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(
        id: id,
        texts: textWithPositions,
      );
      return MemesRepository.getInstance().addToMemes(meme);
    }

    final docsPath = await getApplicationDocumentsDirectory();
    final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
    await Directory(memePath).create(recursive: true);
    final imageName = imagePath.split(Platform.pathSeparator).last;
    String newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    var existingFile = File(newImagePath);
    final tempFile = File(imagePath);
    if (existingFile.existsSync()) {
      if (existingFile.statSync().size == tempFile.statSync().size) {
        final meme = Meme(
          id: id,
          texts: textWithPositions,
          memePath: newImagePath,
        );
        return MemesRepository.getInstance().addToMemes(meme);
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
        }
        counter++;
        newImagePath =
            "$memePath${Platform.pathSeparator}${baseName}_$counter.$ext";
        existingFile = File(newImagePath);
      }
    }
    await tempFile.copy(newImagePath);
    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );
    return MemesRepository.getInstance().addToMemes(meme);
  }
}
