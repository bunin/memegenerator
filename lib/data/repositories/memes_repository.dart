import 'dart:convert';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/list_with_ids_reactive_repository.dart';
import 'package:memogenerator/data/shared_preference_data.dart';

class MemesRepository extends ListWithIdsReactiveRepository<Meme> {
  final SharedPreferenceData spData;

  static MemesRepository? _instance;

  factory MemesRepository.getInstance() => _instance ??=
      MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);

  @override
  convertFromString(String rawItem) => Meme.fromJson(json.decode(rawItem));

  @override
  String convertToString(item) => json.encode(item.toJson());

  @override
  getId(item) => item.id;

  @override
  Future<List<String>> getRawData() => spData.getMemes();

  @override
  Future<bool> saveRawData(List<String> items) => spData.setMemes(items);
}
