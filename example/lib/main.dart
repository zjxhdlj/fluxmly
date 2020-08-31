import 'package:flutter/material.dart';
import 'package:fluxmly/fluxmly.dart';
import 'home_page.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String title = "demo";
  List tracksList;
  int page = 1;

  @override
  void initState() {
    super.initState();
    //初始化喜马拉雅SDK
    initPlatformState();
  }

  initPlatformState() async {
    final res = await Fluxmly.init("APPKEY", "APPSECRET", "PACKID");
    print(res);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: onGenerateRoute,
      home: HomePage(),
    );
  }
}
