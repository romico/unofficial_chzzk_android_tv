abstract class NaverLoginSource {
  const NaverLoginSource._();

  /// Maintain the login state.
  static String toggleKeepLogin = """
var checkbox = document.querySelector('.input_keep');
              if (checkbox !== null) {
                checkbox.checked = true;
                checkbox.value = 'on';
              }
""";

  /// If Keep login is enabled, the ip secure switch must be off.
  static String toggleIpSecureSwitch = """
var switchElement  = document.getElementById("switch");
if (switchElement) switchElement.checked = false;

var smartLevel = document.getElementById('smart_LEVEL');
if (smartLevel) smartLevel.value = "-1";
""";

  static String inputOtp(String otp) => """
var otpField = document.getElementById('disposable');
otpField.value = '$otp';
""";

  static String clickOtpLoginButton = """
document.querySelector('[id="otnlog.login"]').click();
""";
}
