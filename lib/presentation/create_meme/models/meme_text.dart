import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:uuid/uuid.dart';

class MemeText extends Equatable {
  static const double defaultFontSize = 24;
  static const Color defaultColor = Colors.black;
  static const FontWeight defaultFontWeight = FontWeight.w400;

  final String id;
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  MemeText({
    required this.id,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.fontWeight,
  });

  factory MemeText.create() {
    return MemeText(
      id: Uuid().v4(),
      text: "",
      fontSize: defaultFontSize,
      color: defaultColor,
      fontWeight: defaultFontWeight,
    );
  }

  factory MemeText.createFromTextWithPosition(final TextWithPosition twp) {
    return MemeText(
      id: twp.id,
      text: twp.text,
      fontSize: twp.fontSize ?? defaultFontSize,
      color: twp.color ?? defaultColor,
      fontWeight: twp.fontWeight ?? defaultFontWeight,
    );
  }

  MemeText copyWithChangedText(final String newText) {
    return MemeText(
      id: id,
      text: newText,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  MemeText copyWithChangedFontSettings(
    final Color newColor,
    final double newFontSize,
    final FontWeight newFontWeight,
  ) {
    return MemeText(
      id: id,
      text: text,
      fontSize: newFontSize,
      color: newColor,
      fontWeight: newFontWeight,
    );
  }

  @override
  List<Object?> get props => [id, text, color, fontSize, fontWeight];
}
