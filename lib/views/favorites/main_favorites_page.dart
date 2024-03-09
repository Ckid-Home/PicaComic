import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:pica_comic/base.dart";
import "package:pica_comic/comic_source/comic_source.dart";
import "package:pica_comic/foundation/app.dart";
import "package:pica_comic/foundation/local_favorites.dart";
import "package:pica_comic/foundation/log.dart";
import "package:pica_comic/tools/translations.dart";
import "package:pica_comic/views/favorites/network_favorite_page.dart";
import "package:pica_comic/views/widgets/desktop_menu.dart";
import "package:pica_comic/views/widgets/grid_view_delegate.dart";
import "package:pica_comic/views/widgets/show_message.dart";

import "../../network/net_fav_to_local.dart";
import "../../tools/io_tools.dart";
import "../main_page.dart";
import "../widgets/loading.dart";
import "local_favorites.dart";
import "local_search_page.dart";

class FavoritesPageController extends StateController{
  String? current;

  bool? isNetwork;

  bool selecting = true;

  FavoriteData? networkData;
}

const _kSecondaryTopBarHeight = 48.0;

class FavoritesPage extends StatelessWidget with _LocalFavoritesManager{
  FavoritesPage({super.key});

  final controller = StateController
      .putIfNotExists<FavoritesPageController>(FavoritesPageController());

  @override
  Widget build(BuildContext context) {
    return StateBuilder<FavoritesPageController>(builder: (controller){
      return buildPage(context);
    });
  }

  Widget buildPage(BuildContext context){
    return LayoutBuilder(builder: (context, constrains) => Stack(
      children: [
        Positioned(
          top: _kSecondaryTopBarHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: buildContent(context),
        ),
        AnimatedPositioned(
          key: const Key("folders"),
          duration: const Duration(milliseconds: 200),
          left: 0,
          right: 0,
          bottom: controller.selecting ? 0 : constrains.maxHeight - _kSecondaryTopBarHeight,
          child: buildFoldersList(context, constrains.maxHeight - _kSecondaryTopBarHeight),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: buildTopBar(context),
        ),
      ],
    ));
  }

  Widget buildTopBar(BuildContext context){
    final iconColor = Theme.of(context).colorScheme.primary;
    return Material(
      elevation: 1,
      child: SizedBox(
        height: _kSecondaryTopBarHeight,
        child: Row(
            children: [
              if(controller.isNetwork == null)
                Icon(Icons.folder, color: iconColor,)
              else if(controller.isNetwork!)
                Icon(Icons.folder_special, color: iconColor,)
              else
                Icon(Icons.local_activity, color: iconColor,),
              const SizedBox(width: 8,),
              Text(controller.current ?? "未选择".tl, style: const TextStyle(fontSize: 16),).paddingBottom(3),
              const Spacer(),
              if(controller.selecting)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: (){
                    if(controller.current == null){
                      showToast(message: "选择收藏夹".tl);
                      return;
                    }
                    controller.selecting = false;
                    controller.update();
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: (){
                    controller.selecting = true;
                    controller.update();
                  },
                )
            ]
        ).paddingHorizontal(16),
      ),
    );
  }
  
  Widget buildFoldersList(BuildContext context, double height){
    return Material(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomScrollView(
          primary: false,
          slivers: [
            buildTitle("网络".tl).sliverPadding(const EdgeInsets.fromLTRB(12, 8, 12, 0)),
            buildNetwork().sliverPaddingHorizontal(12),
            const SliverToBoxAdapter(child: Divider()).sliverPaddingHorizontal(12),
            buildTitle("本地".tl).sliverPaddingHorizontal(12),
            buildUtils(context),
            buildLocal().sliverPaddingHorizontal(12),
          ],
        ),
      ),
    );
  }

  Widget buildTitle(String title){
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget buildNetwork(){
    final folders = appdata.settings[68].split(',').map((e) => getFavoriteDataOrNull(e));
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedHeight(
        maxCrossAxisExtent: 240,
        itemHeight: 56,
      ),
      delegate: SliverChildBuilderDelegate((context, index){
        final data = folders.elementAt(index);
        return InkWell(
          onTap: (){
            controller.current = data?.title;
            controller.isNetwork = true;
            controller.selecting = false;
            controller.networkData = data;
            controller.update();
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.folder_special, color: Theme.of(context).colorScheme.secondary,),
              const SizedBox(width: 8),
              Text(data?.title ?? "Unknown"),
            ],
          ),
        );
      }, childCount: folders.length),
    );
  }

  Widget buildLocal(){
    final folders = LocalFavoritesManager().folderNames;
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedHeight(
        maxCrossAxisExtent: 240,
        itemHeight: 56,
      ),
      delegate: SliverChildBuilderDelegate((context, index){
        final data = folders.elementAt(index);
        return GestureDetector(
          onLongPressStart: (details) =>
              _showMenu(data, details.globalPosition),
          child: InkWell(
            onTap: (){
              controller.current = data;
              controller.isNetwork = false;
              controller.selecting = false;
              controller.update();
            },
            onSecondaryTapUp: (details) =>
                _showDesktopMenu(data, details.globalPosition),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.local_activity, color: Theme.of(context).colorScheme.secondary,),
                const SizedBox(width: 8),
                Text(data),
              ],
            ),
          ),
        );
      }, childCount: folders.length),
    );
  }

  Widget buildUtils(BuildContext context){
    Widget buildItem(String title, IconData icon, VoidCallback onTap){
      return InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: SizedBox(
          height: 72,
          width: 64,
          child: Column(
            children: [
              const SizedBox(height: 12,),
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary,),
              const SizedBox(height: 8,),
              Text(title, style: const TextStyle(fontSize: 12),)
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Wrap(
        children: [
          buildItem("新建".tl, Icons.add, (){
            showDialog(context: context, builder: (context) =>
            const CreateFolderDialog()).then((value) => controller.update());
          }),
          buildItem("搜索".tl, Icons.search, () => App.to(context, () => const LocalSearchPage())),
        ],
      ).paddingHorizontal(12),
    );
  }

  Widget buildContent(BuildContext context){
    if(controller.current == null){
      return const SizedBox();
    } else if(controller.isNetwork!) {
      return NetworkFavoritePage(controller.networkData!);
    } else {
      return ComicsPageView(folder: controller.current!);
    }
  }

  void _showMenu(String folder, Offset location){
    showMenu(
      context: App.globalContext!,
      position: RelativeRect.fromLTRB(location.dx, location.dy, location.dx, location.dy),
      items: [
        PopupMenuItem(
          child: Text("删除".tl),
          onTap: (){
            App.globalBack();
            deleteFolder(folder);
          },
        ),
        PopupMenuItem(
          child: Text("排序".tl),
          onTap: (){
            App.globalBack();
            App.globalTo(() => LocalFavoritesFolder(folder))
                .then((value) => controller.update());
          },
        ),
        PopupMenuItem(
          child: Text("重命名".tl),
          onTap: (){
            App.globalBack();
            rename(folder);
          },
        ),
        PopupMenuItem(
          child: Text("检查漫画存活".tl),
          onTap: (){
            App.globalBack();
            checkFolder(folder).then((value) {
              controller.update();
            });
          },
        ),
        PopupMenuItem(
          child: Text("导出".tl),
          onTap: (){
            App.globalBack();
            export(folder);
          },
        ),
        PopupMenuItem(
          child: Text("下载全部".tl),
          onTap: (){
            App.globalBack();
            addDownload(folder);
          },
        ),
      ]
    );
  }

  void _showDesktopMenu(String folder, Offset location){
    showDesktopMenu(App.globalContext!, location, [
      DesktopMenuEntry(
        text: "删除".tl,
        onClick: (){
          deleteFolder(folder);
        }
      ),
      DesktopMenuEntry(
        text: "排序".tl,
        onClick: (){
          App.globalTo(() => LocalFavoritesFolder(folder))
              .then((value) => controller.update());
        }
      ),
      DesktopMenuEntry(
        text: "重命名".tl,
        onClick: (){
          rename(folder);
        }
      ),
      DesktopMenuEntry(
        text: "检查漫画存活".tl,
        onClick: (){
          checkFolder(folder).then((value) {
            controller.update();
          });
        }
      ),
      DesktopMenuEntry(
        text: "导出".tl,
        onClick: (){
          export(folder);
        }
      ),
      DesktopMenuEntry(
        text: "下载全部".tl,
        onClick: (){
          addDownload(folder);
        }
      ),
    ]);
  }
}

mixin class _LocalFavoritesManager{
  void deleteFolder(String folder){
    showConfirmDialog(App.globalContext!, "确认删除".tl, "此操作无法撤销, 是否继续?", () {
      App.globalBack();
      LocalFavoritesManager().deleteFolder(folder);
      final controller = StateController.find<FavoritesPageController>();
      if(controller.current == folder && !controller.isNetwork!){
        controller.current = null;
        controller.isNetwork = null;
      }
      controller.update();
    });
  }

  void rename(String folder) async{
    await showDialog(
      context: App.globalContext!,
      builder: (context) => RenameFolderDialog(folder)
    );
    StateController.find<FavoritesPageController>().update();
  }

  void export(String folder) async{
    var controller = showLoadingDialog(App.globalContext!, () {}, true, true, "正在导出".tl);
    try {
      await exportStringDataAsFile(
          LocalFavoritesManager().folderToJsonString(folder),
          "$folder.json");
      controller.close();
    }
    catch(e, s){
      controller.close();
      showMessage(App.globalContext, e.toString());
      log("$e\n$s", "IO", LogLevel.error);
    }
  }

  void addDownload(String folder){
    for(var comic in LocalFavoritesManager().getAllComics(folder)){
      comic.addDownload();
    }
    showToast(message: "已添加下载任务".tl);
  }
}

class ComicsPageView extends StatefulWidget {
  const ComicsPageView({required this.folder, super.key});

  final String folder;

  @override
  State<ComicsPageView> createState() => _ComicsPageViewState();
}

class _ComicsPageViewState extends State<ComicsPageView> {
  late ScrollController scrollController;
  bool showFB = true;
  double location = 0;

  String get folder => widget.folder;

  FolderSync? folderSync(){
    final folderSyncArr = LocalFavoritesManager().folderSync
        .where((element) => element.folderName == folder).toList();
    if(folderSyncArr.isEmpty) return null;
    return folderSyncArr[0];
  }

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      var current = scrollController.offset;

      if ((current > location && current != 0) && showFB) {
        setState(() {
          showFB = false;
        });
      } else if ((current < location || current == 0) && !showFB) {
        setState(() {
          showFB = true;
        });
      }

      location = current;
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildFolderComics(folder);
  }
  Future<void> onRefresh(context) async {
    return startFolderSync(context, folderSync()!);
  }

  Widget buildFolderComics(String folder) {
    var comics = LocalFavoritesManager().getAllComics(folder);
    if (comics.isEmpty) {
      return buildEmptyView();
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: MediaQuery.removePadding(
          key: Key(folder),
          removeTop: true,
          context: context,
          child: RefreshIndicator(
            notificationPredicate: (notify) {
              return folderSync() != null;
            },
            onRefresh: () => onRefresh(context),
            child: Scrollbar(
                controller: scrollController,
                interactive: true,
                thickness: App.isMobile ? 12 : null,
                radius: const Radius.circular(8),
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: GridView.builder(
                    key: Key(folder),
                    primary: false,
                    controller: scrollController,
                    gridDelegate: SliverGridDelegateWithComics(),
                    itemCount: comics.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (BuildContext context, int index) {
                      return LocalFavoriteTile(
                        comics[index],
                        folder,
                            () => setState(() {}),
                        true,
                        showFolderInfo: true,
                      );
                    },
                  ),
                )),
          ),
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 150),
          child: showFB && folderSync() != null ? buildFAB() : const SizedBox(),
          transitionBuilder: (widget, animation) {
            var tween = Tween<Offset>(
                begin: const Offset(0, 1), end: const Offset(0, 0));
            return SlideTransition(
              position: tween.animate(animation),
              child: widget,
            );
          },
        ));
  }

  Widget buildFAB() => Material(
    color: Colors.transparent,
    child: FloatingActionButton(
      key: const Key("FAB"),
      onPressed: () => onRefresh(context),
      child: const Icon(Icons.refresh),
    ),
  );
  Widget buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("这里什么都没有".tl),
          const SizedBox(height: 8,),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '前往'.tl,
                ),
                TextSpan(
                    text: '探索页面'.tl,
                    style: TextStyle(color: App.colors(context).primary),
                    recognizer:  TapGestureRecognizer()..onTap = () {
                      MainPage.toExplorePage?.call();
                    }
                ),
                TextSpan(
                  text: '寻找漫画'.tl,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
