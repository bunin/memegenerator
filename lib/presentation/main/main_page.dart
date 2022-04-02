import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          centerTitle: true,
          foregroundColor: AppColors.darkGrey,
          title: Text(
            'Мемогенератор',
            style: GoogleFonts.seymourOne(
              fontSize: 24,
              color: AppColors.darkGrey,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(child: MainPageContent()),
        floatingActionButton: FloatingActionButton.extended(
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
          label: Text('Создать'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatefulWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  _MainPageContentState createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<Meme>>(
      stream: bloc.observeMemes(),
      initialData: const <Meme>[],
      builder: (context, snapshot) {
        final items = snapshot.hasData ? snapshot.data! : const <Meme>[];
        return ListView(
          children: items.map((meme) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return CreateMemePage(id: meme.id);
                  },
                ),
              ),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(meme.id),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}
