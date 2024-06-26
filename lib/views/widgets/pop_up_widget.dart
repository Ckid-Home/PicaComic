import 'package:flutter/material.dart';

import '../../foundation/app.dart';


class PopUpWidget<T> extends PopupRoute<T>{
  PopUpWidget(this.widget);

  final Widget widget;
  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "exit";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    var height = MediaQuery.of(context).size.height*0.9;
    bool showPopUp = MediaQuery.of(context).size.width > 420;
    if(!showPopUp){
      height = MediaQuery.of(context).size.height;
    }
    var body = MediaQuery.removePadding(removeTop: true, context: context, child: Center(
      child: PopupIndicatorWidget(
        child: Container(
          decoration: showPopUp ? const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ) : null,
          clipBehavior: showPopUp ? Clip.antiAlias : Clip.none,
          width: 550,
          height: height,
          child: ClipRect(
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => widget,
              ),
            ),
          ),
        ),
      ),
    ));

    if(!showPopUp){
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: body,
        ),
      );
    }
    return body;
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation.drive(Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.ease))),
      child: child,
    );
  }
}

class PopupIndicatorWidget extends InheritedWidget{
  const PopupIndicatorWidget({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static PopupIndicatorWidget? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PopupIndicatorWidget>();
  }
}

Future<T> showPopUpWidget<T>(BuildContext context, Widget widget) async{
  return await Navigator.of(context).push(PopUpWidget(widget));
}

void showAdaptiveWidget(BuildContext context, Widget widget){
  //根据当前宽度显示页面
  //当页面宽度大于600, 显示弹窗
  //小于600, 跳转页面
  MediaQuery.of(context).size.width>600?showPopUpWidget(context, widget):
    App.globalTo(()=>widget);
}