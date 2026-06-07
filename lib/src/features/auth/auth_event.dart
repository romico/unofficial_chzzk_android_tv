import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './controller/auth_controller.dart';
import './widgets/naver_login_scripts.dart';
import '../user/controller/user_controller.dart';
import '../../common/constants/enums.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/virtual_keyboard/controller/virtual_keyboard_controller.dart';

mixin class AuthEvent {
  void authControllerInvalidate(WidgetRef ref) {
    ref.invalidate(authControllerProvider);
  }

  void userControllerInvalidate(WidgetRef ref) {
    ref.invalidate(userControllerProvider);
  }

  Future<void> checkLoginStateAndGoToHomeScreen(
    WidgetRef ref, {
    required BuildContext context,
    required InAppWebViewController controller,
  }) async {
    final currentPath = await controller.getUrl();
    final currentPathStr = currentPath.toString();

    if (currentPathStr == "https://chzzk.naver.com/" ||
        currentPathStr == "https://m.chzzk.naver.com") {
      authControllerInvalidate(ref);
      userControllerInvalidate(ref);

      if (context.mounted) {
        context.goTo(
          context: context,
          currentLocation: AppRoute.auth,
          appRoute: AppRoute.home,
        );
      }
    }
  }

  Future<void> onKeyboardEnterPressed(
    WidgetRef ref, {
    required InAppWebViewController? controller,
    required String inputText,
  }) async {
    if (inputText.isNotEmpty && controller != null) {
      await _runJS(controller, NaverLoginSource.inputOtp(inputText));
      await _runJS(controller, NaverLoginSource.clickOtpLoginButton);
      _resetInput(ref);
    }
  }

  Future<void> toggleKeepLogin(InAppWebViewController controller) async {
    await _runJS(controller, NaverLoginSource.toggleKeepLogin);
  }

  Future<void> toggleIpSecureSwitch(InAppWebViewController controller) async {
    await _runJS(controller, NaverLoginSource.toggleIpSecureSwitch);
  }

  Future<void> _runJS(InAppWebViewController controller, String source) async {
    await controller.evaluateJavascript(source: source);
  }

  void _resetInput(WidgetRef ref) {
    ref
        .read(
          virtualKeyboardControllerProvider(routeName: AppRoute.auth.routeName)
              .notifier,
        )
        .reset();
  }
}
