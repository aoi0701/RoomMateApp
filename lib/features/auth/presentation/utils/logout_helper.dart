import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/login_screen.dart';

Future<void> performLogout(BuildContext context) async {
  final authVm = context.read<AuthViewModel>();
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
  if (filterVm != null) {
    await filterVm.resetFilter(clearSaved: true);
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
