import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotInteractor {
  static const memesPathName = "memes";

  static ScreenshotInteractor? _instance;

  factory ScreenshotInteractor.getInstance() =>
      _instance ??= ScreenshotInteractor._internal();

  ScreenshotInteractor._internal();

  Future<void> shareScreenshot(
    final Future<Uint8List?> captureScreenshot,
  ) async {
    final image = await captureScreenshot;
    if (image == null) {
      print("ERROR: cannot get image from screenshot controller");
      return;
    }
    final tempDocs = await getTemporaryDirectory();
    final imagePath = [
      tempDocs.absolute.path,
      "${DateTime.now().millisecondsSinceEpoch}.png",
    ].join(Platform.pathSeparator);
    final imageFile = File(imagePath);
    await imageFile.create(recursive: true);
    await imageFile.writeAsBytes(image);
    await Share.shareFiles([imageFile.path]);
  }

  Future<void> saveThumbnail(
    final String memeId,
    final Future<Uint8List?> captureScreenshot,
  ) async {
    final image = await captureScreenshot;
    if (image == null) {
      print("ERROR: cannot get image from screenshot controller");
      return;
    }
    final tempDocs = await getApplicationDocumentsDirectory();
    final imagePath = [
      tempDocs.path,
      "thumbnails",
      memeId + ".png",
    ].join(Platform.pathSeparator);
    final imageFile = File(imagePath);
    await imageFile.create(recursive: true);
    await imageFile.writeAsBytes(image);
  }
}
