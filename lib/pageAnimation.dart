import 'package:flutter/cupertino.dart';

Future<T?> pushPage<T>(BuildContext context, WidgetBuilder builder, {String? name}) {
  return Navigator.push<T>(
    context,
    CupertinoPageRoute<T>(
      builder: builder,
      settings: RouteSettings(name: name),
    ),
  );
}

Future<T?> pushDialog<T>(BuildContext context, WidgetBuilder builder, {String? name}) {
  final nav = Navigator.of(context, rootNavigator: true);
  return nav.push<T>(
    CupertinoPageRoute<T>(
      builder: builder,
      settings: RouteSettings(name: name),
      fullscreenDialog: true,
    ),
  );
}