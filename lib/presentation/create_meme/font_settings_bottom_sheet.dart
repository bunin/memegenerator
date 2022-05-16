import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class FontSettingBottomSheet extends StatefulWidget {
  final MemeText memeText;

  const FontSettingBottomSheet({
    Key? key,
    required this.memeText,
  }) : super(key: key);

  @override
  State<FontSettingBottomSheet> createState() => _FontSettingBottomSheetState();
}

class _FontSettingBottomSheetState extends State<FontSettingBottomSheet> {
  late double fontSize;
  late Color color;
  late FontWeight fontWeight;

  @override
  void initState() {
    super.initState();
    fontSize = widget.memeText.fontSize;
    color = widget.memeText.color;
    fontWeight = widget.memeText.fontWeight;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            height: 4,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.darkGrey38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MemeTextOnCanvas(
          padding: 8,
          selected: true,
          parentConstraints: BoxConstraints.expand(),
          text: widget.memeText.text,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
        const SizedBox(height: 16),
        FontSizeSlider(
          changeFontSize: (value) => setState(() => fontSize = value),
          fontSize: fontSize,
        ),
        const SizedBox(height: 16),
        ColorSelection(
          changeColor: (Color color) => setState(() {
            this.color = color;
          }),
        ),
        const SizedBox(height: 16),
        FontWeightSlider(
          changeFontWeight: (value) => setState(() {
            fontWeight = value;
          }),
          fontWeight: fontWeight,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Buttons(
            textId: widget.memeText.id,
            onPositiveButtonAction: () {
              bloc.changeFontSettings(
                widget.memeText.id,
                color,
                fontSize,
                fontWeight,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class Buttons extends StatelessWidget {
  final String textId;
  final VoidCallback onPositiveButtonAction;

  const Buttons({
    Key? key,
    required this.textId,
    required this.onPositiveButtonAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          onTap: () => Navigator.of(context).pop(),
          text: "Отмена",
          color: AppColors.darkGrey,
        ),
        const SizedBox(width: 24),
        AppButton(
          onTap: () {
            onPositiveButtonAction();
            Navigator.of(context).pop();
          },
          text: "Сохранить",
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class ColorSelection extends StatelessWidget {
  final ValueChanged<Color> changeColor;

  const ColorSelection({Key? key, required this.changeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 16),
        Text(
          "Color:",
          style: TextStyle(
            fontSize: 20,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(width: 16),
        ColorSelectionBox(changeColor: changeColor, color: Colors.white),
        const SizedBox(width: 16),
        ColorSelectionBox(changeColor: changeColor, color: Colors.black),
        const SizedBox(width: 16),
      ],
    );
  }
}

class ColorSelectionBox extends StatelessWidget {
  final ValueChanged<Color> changeColor;
  final Color color;

  const ColorSelectionBox({
    Key? key,
    required this.changeColor,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => changeColor(color),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: Colors.black,
              width: 1,
            )),
      ),
    );
  }
}

class FontSizeSlider extends StatefulWidget {
  final ValueChanged<double> changeFontSize;
  final double fontSize;

  const FontSizeSlider({
    Key? key,
    required this.changeFontSize,
    required this.fontSize,
  }) : super(key: key);

  @override
  State<FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends State<FontSizeSlider> {
  late double fontSize;

  @override
  void initState() {
    super.initState();
    fontSize = widget.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Text(
          "Size:",
          style: TextStyle(
            fontSize: 20,
            color: AppColors.darkGrey,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.fuchsia,
              inactiveTrackColor: AppColors.fuchsia38,
              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
              thumbColor: AppColors.fuchsia,
              inactiveTickMarkColor: AppColors.fuchsia,
              valueIndicatorColor: AppColors.fuchsia,
            ),
            child: Slider(
              min: 16,
              max: 32,
              divisions: 10,
              label: fontSize.round().toString(),
              value: fontSize,
              onChanged: (double value) {
                setState(() {
                  this.fontSize = value;
                  widget.changeFontSize(value);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FontWeightSlider extends StatefulWidget {
  final ValueChanged<FontWeight> changeFontWeight;
  final FontWeight fontWeight;

  const FontWeightSlider({
    Key? key,
    required this.changeFontWeight,
    required this.fontWeight,
  }) : super(key: key);

  @override
  State<FontWeightSlider> createState() => _FontWeightSliderState();
}

class _FontWeightSliderState extends State<FontWeightSlider> {
  late FontWeight fontWeight;

  @override
  void initState() {
    super.initState();
    fontWeight = widget.fontWeight;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Font Weight:",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.darkGrey,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.fuchsia,
              inactiveTrackColor: AppColors.fuchsia38,
              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
              thumbColor: AppColors.fuchsia,
              inactiveTickMarkColor: AppColors.fuchsia,
              valueIndicatorColor: AppColors.fuchsia,
            ),
            child: Slider(
              min: FontWeight.w100.index.toDouble(),
              max: FontWeight.w900.index.toDouble(),
              divisions: FontWeight.w900.index - FontWeight.w100.index,
              value: fontWeight.index.toDouble(),
              onChanged: (double value) {
                setState(() {
                  this.fontWeight = FontWeight.values.firstWhere(
                    (element) => element.index == value.toInt(),
                  );
                  widget.changeFontWeight(this.fontWeight);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
