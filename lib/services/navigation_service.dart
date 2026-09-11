import 'package:flutter/material.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static NavigationService get instance => const NavigationService();
  const NavigationService();
}

extension NavigationServiceCompat on NavigationService {
  GlobalKey<NavigatorState> get navigatorKey => NavigationService.navigatorKey;
}
