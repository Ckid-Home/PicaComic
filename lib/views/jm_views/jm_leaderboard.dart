import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/tools/translations.dart';

class JmLeaderboardPage extends StatelessWidget {
  const JmLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: !UiMode.m1(context),
      child: Scaffold(
        appBar: AppBar(
          primary: UiMode.m1(context),
          title: Text("排行榜".tl),
        ),
        body: DefaultTabController(length: 4, child: Column(
          children: [
            TabBar(
                splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
                tabs: [
                  Tab(text: "总排行".tl),
                  Tab(text: "月排行".tl),
                  Tab(text: "周排行".tl),
                  Tab(text: "日排行".tl),
                ]),
            const Expanded(child: TabBarView(
                children: [
                  OneJmLeaderboardPage(ComicsOrder.totalRanking),
                  OneJmLeaderboardPage(ComicsOrder.monthRanking),
                  OneJmLeaderboardPage(ComicsOrder.weekRanking),
                  OneJmLeaderboardPage(ComicsOrder.dayRanking),
                ]
            ),)
          ],
        )),
      ),
    );
  }
}

class OneJmLeaderboardPage extends ComicsPage{
  const OneJmLeaderboardPage(this.order,{super.key});
  final ComicsOrder order;

  @override
  Future<Res<List>> getComics(int i) {
    return JmNetwork().getCategoryComicsNew("0", order, i);
  }

  @override
  String? get tag => "Jm leaderboard $order";

  @override
  String get title => throw UnimplementedError();

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;

  @override
  bool get showBackWhenLoading => false;
}
