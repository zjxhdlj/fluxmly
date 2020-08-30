import 'package:flutter/material.dart';
import 'package:fluxmly_example/detail.dart';
import 'package:fluxmly_example/list.dart';

final routes = {
  "/detail": (context, {arguments}) => TrackDetail(
        track: arguments,
      ),
  "/albumList": (context, {arguments}) => AlbumList(
        params: arguments,
      ),
};

var onGenerateRoute = (RouteSettings settings) {
  final String name = settings.name;
  final Function pageContentBuilder = routes[name];
  if (pageContentBuilder != null) {
    if (settings.arguments != null) {
      final Route route = MaterialPageRoute(
          builder: (context) =>
              pageContentBuilder(context, arguments: settings.arguments));
      return route;
    } else {
      final Route route =
          MaterialPageRoute(builder: (context) => pageContentBuilder(context));
      return route;
    }
  }
};
