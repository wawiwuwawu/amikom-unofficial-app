import 'package:flutter/material.dart';

class NavigationService {
  static NavigationService? _instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigationService._();

  static NavigationService get instance {
    _instance ??= NavigationService._();
    return _instance!;
  }
}
