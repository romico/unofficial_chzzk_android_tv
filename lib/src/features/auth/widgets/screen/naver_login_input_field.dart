part of '../../auth_screen.dart';

class _NaverLoginInputField extends ConsumerWidget with AuthState {
  const _NaverLoginInputField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VirtualKeyboardInputField(isObscure: false, routeName: AppRoute.auth.routeName);
  }
}
