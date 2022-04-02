import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:multiple_stream_builder/multiple_stream_builder.dart';
import 'package:provider/provider.dart';

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
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
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
                return BottomMemeTextItem(
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

class BottomMemeTextItem extends StatelessWidget {
  const BottomMemeTextItem({
    Key? key,
    required this.memeText,
    required this.selected,
  }) : super(key: key);

  final MemeText memeText;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: 16,
      ),
      color: selected ? AppColors.darkGrey16 : null,
      child: Text(
        memeText.text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
          fontFamily: 'Roboto',
          color: AppColors.darkGrey,
        ),
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
          child: Stack(
            children: [
              StreamBuilder<String?>(
                  stream: bloc.observeMemePath(),
                  builder: (context, snapshot) {
                    final path = snapshot.hasData ? snapshot.data! : null;
                    if (path == null) {
                      return Container(
                        color: Colors.white,
                      );
                    }
                    return Image.file(File(path));
                  }),
              StreamBuilder<List<MemeTextWithOffset>>(
                  stream: bloc.observeMemeTextWithOffsets(),
                  initialData: const <MemeTextWithOffset>[],
                  builder: (context, snapshot) {
                    final memeTextWithOffsets = snapshot.hasData
                        ? snapshot.data!
                        : const <MemeTextWithOffset>[];
                    return LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: memeTextWithOffsets.map((memeTextWithOffset) {
                          return DraggableMemeText(
                            memeTextWithOffset: memeTextWithOffset,
                            parentConstraints: constraints,
                          );
                        }).toList(growable: false),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => bloc.selectMemeText(widget.memeTextWithOffset.id),
        onPanUpdate: (details) {
          setState(() {
            top = calculateTop(details);
            left = calculateLeft(details);
            bloc.changeMemeTextOffset(
                widget.memeTextWithOffset.id, Offset(left, top));
          });
        },
        onTap: () => bloc.selectMemeText(widget.memeTextWithOffset.id),
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemeText(),
            builder: (context, snapshot) {
              final selected = snapshot.hasData &&
                  snapshot.data?.id == widget.memeTextWithOffset.id;
              return Container(
                padding: const EdgeInsets.all(padding),
                decoration: selected
                    ? BoxDecoration(
                        color: AppColors.darkGrey16,
                        border: Border.all(color: AppColors.fuchsia, width: 1),
                      )
                    : null,
                constraints: BoxConstraints(
                  maxWidth: widget.parentConstraints.maxWidth,
                  maxHeight: widget.parentConstraints.maxHeight,
                ),
                child: Text(
                  widget.memeTextWithOffset.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bloc.addNewText(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.fuchsia),
              const SizedBox(width: 8),
              Text(
                "Добавить текст".toUpperCase(),
                style: TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
