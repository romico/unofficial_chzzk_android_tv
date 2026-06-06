part of '../../auth_screen.dart';

class _NaverLoginHeaderText extends ConsumerWidget with AuthState {
  /// Hint text for login.
  const _NaverLoginHeaderText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginStep = getLoginStep(ref);

    final String hintText = switch (loginStep) {
      LoginStep.otp =>
        '네이버 앱 메뉴 > 설정 > 로그인 아이디 관리 > 더보기 > 일회용 로그인 번호\n를 입력해주세요',
    };

    return CenteredText(
      text: hintText,
      fontSize: 20.0,
    );
  }
}
