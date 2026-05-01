import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel({required NotificationRepository repository})
      : _repository = repository;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<List<NotificationModel>>? _notifSub;
  StreamSubscription<int>? _unreadSub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void listenToNotifications(String userId) {
    _notifSub?.cancel();
    _unreadSub?.cancel();

    _notifSub = _repository.getNotificationsStream(userId).listen((data) {
      _notifications = data;
      notifyListeners();
    });

    _unreadSub = _repository.getUnreadCountStream(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _repository.markAllAsRead(userId);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}
