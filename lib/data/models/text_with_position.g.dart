// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_with_position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextWithPosition _$TextWithPositionFromJson(Map<String, dynamic> json) =>
    TextWithPosition(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      fontSize: (json['font-size'] as num?)?.toDouble(),
      color: TextWithPosition.colorFromJson(json['color'] as String?),
      fontWeight:
          TextWithPosition.fontWeightFromJson(json['font-weight'] as int?),
    );

Map<String, dynamic> _$TextWithPositionToJson(TextWithPosition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'position': instance.position.toJson(),
      'font-size': instance.fontSize,
      'color': TextWithPosition.colorToJson(instance.color),
      'font-weight': TextWithPosition.fontWeightToJson(instance.fontWeight),
    };
