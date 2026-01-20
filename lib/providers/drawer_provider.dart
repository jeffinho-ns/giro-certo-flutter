import 'package:flutter/material.dart';

class DrawerProvider extends ChangeNotifier {
  GlobalKey<ScaffoldState>? scaffoldKey;

  void setScaffoldKey(GlobalKey<ScaffoldState> key) {
    scaffoldKey = key;
    notifyListeners();
  }

  void openProfileDrawer() {
    scaffoldKey?.currentState?.openEndDrawer();
  }
}




