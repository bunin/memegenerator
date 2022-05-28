import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/easter_egg/easter_egg_page.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/main/models/meme_thumbnail.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late MainBloc bloc;
  late TabController tabController;

  // int openedTabIndex = 0;
  double tabIndex = 0;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
    tabController = TabController(length: 2, vsync: this);
    // tabController.addListener(() {
    //   if (tabController.index == openedTabIndex) {
    //     return;
    //   }
    //   setState(() {
    //     openedTabIndex = tabController.index;
    //   });
    // });
    tabController.animation!.addListener(() {
      setState(() {
        tabIndex = tabController.animation!.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          final goBack = await showConfirmation(context);
          return goBack ?? false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            centerTitle: true,
            foregroundColor: AppColors.darkGrey,
            title: GestureDetector(
              onLongPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EasterEggPage(),
                  ),
                );
              },
              child: Text(
                'Мемогенератор',
                style: GoogleFonts.seymourOne(
                  fontSize: 24,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            bottom: TabBar(
              controller: tabController,
              labelColor: AppColors.darkGrey,
              indicatorColor: AppColors.fuchsia,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  text: "Созданные".toUpperCase(),
                ),
                Tab(
                  text: "Шаблоны".toUpperCase(),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          body: TabBarView(
            controller: tabController,
            children: [
              SafeArea(child: CreatedMemesGrid()),
              SafeArea(child: TemplatesGrid()),
            ],
          ),
          floatingActionButton: tabIndex <= 0.5
              ? Transform.scale(
                  scale: 1 - tabIndex / 0.5,
                  child: CreateMemeFab(),
                )
              : Transform.scale(
                  scale: (tabIndex - 0.5) / 0.5,
                  child: CreateTemplateFab(),
                ),
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
            title: Text("Точно хотите выйти?"),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
            content: Text("Мемы сами себя не сделают"),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Остаться",
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

class CreateMemeFab extends StatelessWidget {
  const CreateMemeFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        final selectedMemePath = await bloc.selectMeme();
        if (selectedMemePath == null) {
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreateMemePage(
                  selectedMemePath: selectedMemePath,
                )));
      },
      backgroundColor: AppColors.fuchsia,
      icon: Icon(Icons.add, color: AppColors.white),
      label: Text('Мем'),
    );
  }
}

class CreateTemplateFab extends StatelessWidget {
  const CreateTemplateFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        await bloc.addToTemplates();
      },
      backgroundColor: AppColors.fuchsia,
      icon: Icon(Icons.add, color: AppColors.white),
      label: Text('Шаблон'),
    );
  }
}

class CreatedMemesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<MemeThumbnail>>(
      stream: bloc.observeMemes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final items = snapshot.requireData;
        return GridView.extent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: items.map((memeThumbnail) {
            return MemeGridItem(memeThumbnail: memeThumbnail);
          }).toList(growable: false),
        );
      },
    );
  }
}

class MemeGridItem extends StatelessWidget {
  const MemeGridItem({
    Key? key,
    required this.memeThumbnail,
  }) : super(key: key);

  final MemeThumbnail memeThumbnail;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(memeThumbnail.fullImageUrl);
    final bloc = Provider.of<MainBloc>(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return CreateMemePage(id: memeThumbnail.memeId);
          },
        ),
      ),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.darkGrey,
                width: 1,
              ),
            ),
            child: imageFile.existsSync()
                ? Image.file(imageFile)
                : Text(memeThumbnail.memeId),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: DeleteButton(
              onDeleteAction: () => bloc.deleteMeme(memeThumbnail.memeId),
              itemName: "мем",
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  final VoidCallback onDeleteAction;
  final String itemName;

  const DeleteButton({
    Key? key,
    required this.onDeleteAction,
    required this.itemName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showConfirmation(context) ?? false;
        if (ok) {
          onDeleteAction();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGrey38,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        child: const Icon(
          Icons.delete_outline,
          size: 24,
          color: AppColors.white,
        ),
      ),
    );
  }

  Future<bool?> showConfirmation(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Удалить $itemName?"),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
            content: Text("Выбранный $itemName будет удален навсегда"),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Отмена",
                color: AppColors.darkGrey,
              ),
              AppButton(
                onTap: () => Navigator.of(context).pop(true),
                text: "Удалить",
              ),
            ],
          );
        });
  }
}

class TemplatesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<TemplateFull>>(
      stream: bloc.observeTemplates(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final templates = snapshot.requireData;
        return GridView.extent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: templates.map((template) {
            return TemplateGridItem(template: template);
          }).toList(growable: false),
        );
      },
    );
  }
}

class TemplateGridItem extends StatelessWidget {
  const TemplateGridItem({
    Key? key,
    required this.template,
  }) : super(key: key);

  final TemplateFull template;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(template.fullImagePath);
    final bloc = Provider.of<MainBloc>(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return CreateMemePage(selectedMemePath: template.fullImagePath);
          },
        ),
      ),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.darkGrey,
                width: 1,
              ),
            ),
            child: imageFile.existsSync()
                ? Image.file(imageFile)
                : Text(template.id),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: DeleteButton(
              onDeleteAction: () => bloc.deleteTemplate(template.id),
              itemName: "шаблон",
            ),
          ),
        ],
      ),
    );
  }
}
