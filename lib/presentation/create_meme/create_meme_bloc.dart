import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/domain/interactors/screenshot_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final String id;

  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);
  final memePathSubject = BehaviorSubject<String?>.seeded(null);
  final screenshotControllerSubject =
      BehaviorSubject<ScreenshotController>.seeded(
    ScreenshotController(),
  );

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubscription;
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;
  StreamSubscription<void>? shareMemeSubscription;

  CreateMemeBloc({
    final String? id,
    final String? selectedMemePath,
  }) : this.id = id ?? Uuid().v4() {
    print("Got id: $id");
    memePathSubject.add(selectedMemePath);
    _subscribeToNewMemeTextOffset();
    _subscribeToExistentMeme();
  }

  Future<bool> isAllSaved() async {
    final savedMeme = await MemesRepository.getInstance().getMeme(id);
    if (savedMeme == null) {
      return false;
    }

    final savedMemeTexts = savedMeme.texts.map((textWithPosition) {
      return MemeText.createFromTextWithPosition(textWithPosition);
    }).toList(growable: false);
    final savedMemeTextOffsets = savedMeme.texts.map((textWithPosition) {
      return MemeTextOffset(
        id: textWithPosition.id,
        offset: Offset(
          textWithPosition.position.left,
          textWithPosition.position.top,
        ),
      );
    }).toList(growable: false);

    return DeepCollectionEquality.unordered().equals(
          savedMemeTexts,
          memeTextsSubject.value,
        ) &&
        DeepCollectionEquality.unordered().equals(
          savedMemeTextOffsets,
          memeTextOffsetsSubject.value,
        );
  }

  void _subscribeToExistentMeme() {
    existentMemeSubscription =
        MemesRepository.getInstance().getMeme(this.id).asStream().listen(
      (meme) {
        if (meme == null) {
          return;
        }
        final memeTexts = meme.texts.map((textWithPosition) {
          return MemeText.createFromTextWithPosition(textWithPosition);
        }).toList(growable: false);
        final memeTextOffsets = meme.texts.map((textWithPosition) {
          return MemeTextOffset(
            id: textWithPosition.id,
            offset: Offset(
              textWithPosition.position.left,
              textWithPosition.position.top,
            ),
          );
        }).toList(growable: false);
        memeTextsSubject.add(memeTexts);
        memeTextOffsetsSubject.add(memeTextOffsets);
        if (meme.memePath != null) {
          getApplicationDocumentsDirectory().then((docsDirectory) {
            memePathSubject.add(
              [
                docsDirectory.absolute.path,
                SaveMemeInteractor.memesPathName,
                meme.memePath,
              ].join(Platform.pathSeparator),
            );
          });
        }
      },
      onError: (error, stackTrace) => print(
        "Error in existentMemeSubscription: $error, $stackTrace",
      ),
    );
  }

  void shareScreenshot() {
    shareMemeSubscription?.cancel();
    shareMemeSubscription = ScreenshotInteractor.getInstance()
        .shareScreenshot(screenshotControllerSubject.value.capture())
        .asStream()
        .listen(
          (event) {},
          onError: (error, stackTrace) => print(
            "Error in shareMemeSubscription: $error, $stackTrace",
          ),
        );
  }

  void changeFontSettings(
    final String textId,
    final Color color,
    final double fontSize,
    final FontWeight fontWeight,
  ) {
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == textId);
    if (index < 0) {
      return;
    }
    copiedList[index] = copiedList[index].copyWithChangedFontSettings(
      color,
      fontSize,
      fontWeight,
    );
    memeTextsSubject.add(copiedList);
  }

  void saveMeme() {
    final memeTexts = memeTextsSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;
    final textsWithPositions = memeTexts.map((memeText) {
      final memeTextPosition = memeTextOffsets.firstWhereOrNull(
          (memeTextOffset) => memeTextOffset.id == memeText.id);
      return TextWithPosition(
        id: memeText.id,
        text: memeText.text,
        position: Position(
          left: memeTextPosition?.offset.dx ?? 0,
          top: memeTextPosition?.offset.dy ?? 0,
        ),
        color: memeText.color,
        fontSize: memeText.fontSize,
        fontWeight: memeText.fontWeight,
      );
    }).toList(growable: false);

    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: id,
          textWithPositions: textsWithPositions,
          imagePath: memePathSubject.value,
          screenshotController: screenshotControllerSubject.value,
        )
        .asStream()
        .listen(
      (saved) {
        print("Meme saved: $saved");
      },
      onError: (error, stackTrace) => print(
        "Error in saveMemeSubscription: $error, $stackTrace",
      ),
    );
  }

  void _subscribeToNewMemeTextOffset() {
    newMemeTextOffsetSubscription = newMemeTextOffsetSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen(
      (newMemeTextOffset) {
        if (newMemeTextOffset == null) {
          return;
        }
        _changeMemeTextOffsetInternal(newMemeTextOffset);
      },
      onError: (error, stackTrace) => print(
        "Error in newMemeTextOffsetSubscription: $error, $stackTrace",
      ),
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffsets = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset = copiedMemeTextOffsets.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffsets.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffsets.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffsets);
  }

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void deleteMemeText(final String textId) {
    final copiedList = [...memeTextsSubject.value];
    copiedList.removeWhere((memeText) => memeText.id == textId);
    memeTextsSubject.add(copiedList);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index < 0) {
      return;
    }
    copiedList[index] = copiedList[index].copyWithChangedText(text);
    memeTextsSubject.add(copiedList);
  }

  void selectMemeText(final String id) {
    selectedMemeTextSubject.add(memeTextsSubject.value
        .firstWhereOrNull((memeText) => memeText.id == id));
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<String?> observeMemePath() => memePathSubject.distinct();

  Stream<List<MemeText>> observeMemeTexts() => memeTextsSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  Stream<ScreenshotController> observeScreenshotController() =>
      screenshotControllerSubject.distinct();

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffsets() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
            List<MemeTextWithOffset>>(
        observeMemeTexts(), memeTextOffsetsSubject.distinct(),
        (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final memeTextOffset = memeTextOffsets
            .firstWhereOrNull((element) => element.id == memeText.id);
        return MemeTextWithOffset(
          memeText: memeText,
          offset: memeTextOffset?.offset,
        );
      }).toList(growable: false);
    });
  }

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    memePathSubject.close();
    screenshotControllerSubject.close();

    newMemeTextOffsetSubscription?.cancel();
    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
    shareMemeSubscription?.cancel();
  }
}
