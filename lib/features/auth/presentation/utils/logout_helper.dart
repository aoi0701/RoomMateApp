import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/login_screen.dart';

Future<void> performLogout(BuildContext context) async {
  final authVm = context.read<AuthViewModel>();
  RoommateRequestViewModel? roommateVm;
  try {
    roommateVm = context.read<RoommateRequestViewModel>();
  } on ProviderNotFoundException {
    roommateVm = null;
  }
  if (roommateVm != null) {
    await roommateVm.resetSession();
  }

  await authVm.logout();

  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(),
    ),
    (route) => false,
  );
}
