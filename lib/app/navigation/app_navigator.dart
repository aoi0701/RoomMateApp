import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _state => navigatorKey.currentState;

  void pushAndRemoveUntil(Route<dynamic> route, RoutePredicate predicate) {
    _state?.pushAndRemoveUntil(route, predicate);
  }
}
