import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';

class MemesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static MemesRepository? _instance;

  factory MemesRepository.getInstance() => _instance ??=
      MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);

  Future<bool> addToMemes(final Meme newMeme) async {
    final memes = await getMemes();
    final index = memes.indexWhere((meme) => meme.id == newMeme.id);
    if (index < 0) {
      memes.add(newMeme);
    } else {
      memes[index] = newMeme;
    }
    return setMemes(memes);
  }

  Future<bool> removeFromMemes(final String id) async {
    final rawData = await spData.getMemes();
    rawData.removeWhere((e) => Meme.fromJson(json.decode(e)).id == id);
    updater.add(null);
    return spData.setMemes(rawData);
  }

  Future<List<Meme>> getMemes() async {
    return (await spData.getMemes())
        .map((e) => Meme.fromJson(json.decode(e)))
        .toList(growable: true);
  }

  Future<bool> setMemes(final List<Meme> memes) async {
    updater.add(null);
    return spData.setMemes(
      memes.map((e) => json.encode(e.toJson())).toList(growable: false),
    );
  }

  Future<Meme?> getMeme(final String id) async {
    final memes = await getMemes();
    return memes.firstWhereOrNull((meme) => meme.id == id);
  }

  Stream<List<Meme>> observeMemes() async* {
    yield await getMemes();
    await for (final _ in updater) {
      yield await getMemes();
    }
  }
}
