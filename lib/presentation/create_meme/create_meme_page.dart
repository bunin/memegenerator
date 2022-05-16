import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/font_settings_bottom_sheet.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:multiple_stream_builder/multiple_stream_builder.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;
  final String? selectedMemePath;

  const CreateMemePage({Key? key, this.id, this.selectedMemePath})
      : super(key: key);

  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(
      id: widget.id,
      selectedMemePath: widget.selectedMemePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          final allSaved = await bloc.isAllSaved();
          if (allSaved) {
            return true;
          }
          final goBack = await showConfirmation(context);
          return goBack ?? false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            foregroundColor: AppColors.darkGrey,
            title: Text(
              'Создаем мем',
            ),
            bottom: EditTextBar(),
            actions: [
              GestureDetector(
                onTap: bloc.shareScreenshot,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.share,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              GestureDetector(
                onTap: bloc.saveMeme,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.save,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: SafeArea(child: CreateMemePageContent()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  Future<bool?> showConfirmation(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Хотите выйти?"),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
            content: Text("Вы потеряете несохраненные изменения"),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Отмена",
                color: AppColors.darkGrey,
              ),
              AppButton(
                onTap: () => Navigator.of(context).pop(true),
                text: "Выйти",
              ),
            ],
          );
        });
  }
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({Key? key}) : super(key: key);

  @override
  _EditTextBarState createState() => _EditTextBarState();

  @override
  Size get preferredSize => Size.fromHeight(68);
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: StreamBuilder<MemeText?>(
          stream: bloc.observeSelectedMemeText(),
          builder: (context, snapshot) {
            final MemeText? selectedMemeText =
                snapshot.hasData ? snapshot.data : null;
            if (selectedMemeText?.text != controller.text) {
              final newText = selectedMemeText?.text ?? "";
              controller.text = newText;
              controller.selection =
                  TextSelection.collapsed(offset: newText.length);
            }
            return TextField(
              enabled: selectedMemeText != null,
              controller: controller,
              onChanged: (text) {
                if (selectedMemeText == null) {
                  return;
                }
                bloc.changeMemeText(selectedMemeText.id, text);
              },
              onEditingComplete: () => bloc.deselectMemeText(),
              cursorColor: AppColors.fuchsia,
              decoration: InputDecoration(
                hintText: (selectedMemeText == null) ? null : "Ввести текст",
                hintStyle: TextStyle(fontSize: 16, color: AppColors.darkGrey38),
                hintMaxLines: 1,
                filled: true,
                fillColor: (selectedMemeText == null)
                    ? AppColors.darkGrey6
                    : AppColors.fuchsia16,
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.darkGrey38),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia38),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia, width: 2),
                ),
              ),
            );
          }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  const CreateMemePageContent({Key? key}) : super(key: key);

  @override
  _CreateMemePageContentState createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: const MemeCanvasWidget(),
          flex: 2,
        ),
        Container(
          color: AppColors.darkGrey,
          height: 1,
          width: double.infinity,
        ),
        Expanded(
          child: Container(
            color: AppColors.white,
            child: BottomList(),
          ),
          flex: 1,
        ),
      ],
    );
  }
}

class BottomList extends StatelessWidget {
  const BottomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder2<List<MemeText>, MemeText?>(
      streams: Tuple2(
        bloc.observeMemeTexts(),
        bloc.observeSelectedMemeText(),
      ),
      initialData: Tuple2(const <MemeText>[], null),
      builder: (context, snapshots) {
        final memeTexts = snapshots.item1.hasData
            ? snapshots.item1.data!
            : const <MemeText>[];
        final selectedMemeText =
            snapshots.item2.hasData ? snapshots.item2.data : null;
        return ListView.separated(
          itemCount: memeTexts.length + 1,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return const AddNewMemeTextButton();
              default:
                return BottomMemeText(
                  memeText: memeTexts[index - 1],
                  selected: memeTexts[index - 1].id == selectedMemeText?.id,
                );
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            if (index < 1) {
              return SizedBox.shrink();
            }
            return Container(
              margin: EdgeInsets.only(left: 16),
              height: 1,
              color: AppColors.darkGrey,
            );
          },
        );
      },
    );
  }
}

class BottomMemeText extends StatelessWidget {
  const BottomMemeText({
    Key? key,
    required this.memeText,
    required this.selected,
  }) : super(key: key);

  final MemeText memeText;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      onTap: () => bloc.selectMemeText(memeText.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        color: selected ? AppColors.darkGrey16 : null,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                memeText.text,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            const SizedBox(width: 4),
            BottomTextMemeAction(
              icon: Icons.font_download_outlined,
              onTap: () {
                showModalBottomSheet(
                  shape: const RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  context: context,
                  builder: (context) {
                    return Provider.value(
                      value: bloc,
                      child: FontSettingBottomSheet(memeText: memeText),
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 4),
            BottomTextMemeAction(
              onTap: () => bloc.deleteMemeText(memeText.id),
              icon: Icons.delete_forever_outlined,
            ),
            SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class BottomTextMemeAction extends StatelessWidget {
  const BottomTextMemeAction({
    Key? key,
    required this.onTap,
    required this.icon,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      onTap: () => bloc.deselectMemeText(),
      child: Container(
        color: AppColors.darkGrey38,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 1,
          child: StreamBuilder<ScreenshotController>(
              stream: bloc.observeScreenshotController(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox.shrink();
                }
                return Screenshot(
                  controller: snapshot.requireData,
                  child: Stack(
                    children: [
                      BackgroundImage(),
                      MemeTexts(),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class MemeTexts extends StatelessWidget {
  const MemeTexts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<List<MemeTextWithOffset>>(
        stream: bloc.observeMemeTextWithOffsets(),
        initialData: const <MemeTextWithOffset>[],
        builder: (context, snapshot) {
          final memeTextWithOffsets =
              snapshot.hasData ? snapshot.data! : const <MemeTextWithOffset>[];
          return LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: memeTextWithOffsets.map((memeTextWithOffset) {
                return DraggableMemeText(
                  key: ValueKey(
                    memeTextWithOffset.memeText.id,
                  ),
                  memeTextWithOffset: memeTextWithOffset,
                  parentConstraints: constraints,
                );
              }).toList(growable: false),
            ),
          );
        });
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<String?>(
        stream: bloc.observeMemePath(),
        builder: (context, snapshot) {
          final path = snapshot.hasData ? snapshot.data! : null;
          if (path == null) {
            return Container(
              color: Colors.white,
            );
          }
          return Image.file(File(path));
        });
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    Key? key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  _DraggableMemeTextState createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;
  static const double padding = 8;

  @override
  void initState() {
    super.initState();
    top = widget.memeTextWithOffset.offset?.dy ??
        widget.parentConstraints.maxHeight / 2;
    left = widget.memeTextWithOffset.offset?.dx ??
        widget.parentConstraints.maxWidth / 3;
    if (widget.memeTextWithOffset.offset != null) {
      return;
    }
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
      bloc.changeMemeTextOffset(
          widget.memeTextWithOffset.memeText.id, Offset(left, top));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => bloc.selectMemeText(
          widget.memeTextWithOffset.memeText.id,
        ),
        onPanUpdate: (details) {
          setState(() {
            top = calculateTop(details);
            left = calculateLeft(details);
            bloc.changeMemeTextOffset(
              widget.memeTextWithOffset.memeText.id,
              Offset(left, top),
            );
          });
        },
        onTap: () => bloc.selectMemeText(widget.memeTextWithOffset.memeText.id),
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemeText(),
            builder: (context, snapshot) {
              final selected = snapshot.hasData &&
                  snapshot.data?.id == widget.memeTextWithOffset.memeText.id;
              return MemeTextOnCanvas(
                padding: padding,
                selected: selected,
                parentConstraints: widget.parentConstraints,
                text: widget.memeTextWithOffset.memeText.text,
                fontSize: widget.memeTextWithOffset.memeText.fontSize,
                color: widget.memeTextWithOffset.memeText.color,
                fontWeight: widget.memeTextWithOffset.memeText.fontWeight,
              );
            }),
      ),
    );
  }

  double calculateLeft(DragUpdateDetails details) {
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) {
      return 0;
    }
    if (rawLeft > widget.parentConstraints.maxWidth - padding * 2 - 10) {
      return widget.parentConstraints.maxWidth - padding * 2 - 10;
    }
    return rawLeft;
  }

  double calculateTop(DragUpdateDetails details) {
    final rawTop = top + details.delta.dy;
    if (rawTop < 0) {
      return 0;
    }
    if (rawTop > widget.parentConstraints.maxHeight - padding * 2 - 30) {
      return widget.parentConstraints.maxHeight - padding * 2 - 30;
    }
    return rawTop;
  }
}

class AddNewMemeTextButton extends StatelessWidget {
  const AddNewMemeTextButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: AppButton(
          onTap: bloc.addNewText,
          text: "Добавить текст",
          icon: Icons.add,
        ),
      ),
    );
  }
}
