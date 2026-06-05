import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigator.dart' show NavigationService;
import '../../../chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

// Đăng xuất toàn diện: reset filter, xóa session roommate, xóa cache chat rồi mới logout Firebase
Future<void> performLogout(BuildContext context) async {
  final authVm = context.read<AuthViewModel>();
  final navigationService = context.read<NavigationService>();
  HomeSearchFilterViewModel? filterVm;
  RoommateRequestViewModel? roommateVm;
  try {
    filterVm = context.read<HomeSearchFilterViewModel>();
  } on ProviderNotFoundException {
    filterVm = null;
  }
  try {
    roommateVm = context.read<RoommateRequestViewModel>();
  } on ProviderNotFoundException {
    roommateVm = null;
  }
  ChatViewModel? chatVm;
  try {
    chatVm = context.read<ChatViewModel>();
  } on ProviderNotFoundException {
    chatVm = null;
  }

  if (filterVm != null) {
    await filterVm.resetFilter(clearSaved: true);
  }
  if (roommateVm != null) {
    await roommateVm.resetSession();
  }
  chatVm?.clearSession();

  await authVm.logout();

  // Pop hết routes về AuthGate — AuthGate sẽ tự hiển thị LoginScreen khi session = null
  navigationService.navigatorKey.currentState
      ?.popUntil((route) => route.isFirst);
}
