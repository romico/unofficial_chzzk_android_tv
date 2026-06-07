part of '../../auth_screen.dart';

class _NaverLoginHeaderText extends ConsumerWidget with AuthState {
  /// Hint text for login.
  const _NaverLoginHeaderText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginStep = getLoginStep(ref);

    final String hintText = switch (loginStep) {
      LoginStep.otp =>
        '네이버 앱에서 일회용 번호를 먼저 발급하세요 (유효 20초)\n'
        '설정 > 로그인 아이디 관리 > 더보기 > 일회용 로그인 번호\n'
        '8자리 입력이 끝나면 자동으로 로그인됩니다',
    };

    return CenteredText(
      text: hintText,
      fontSize: 20.0,
    );
  }
}
