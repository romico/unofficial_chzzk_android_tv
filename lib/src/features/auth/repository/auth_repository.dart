import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/constants/api.dart' show BaseUrl;
import '../../../utils/shared_preferences/shared_prefs.dart';
import '../model/auth.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
      prefs: ref.watch(sharedPrefsProvider),
    );

/// Auth Repository with the [CookieManager].
class AuthRepository {
  AuthRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final CookieManager _cookieManager = CookieManager.instance();
  final SharedPreferences _prefs;

  static const _cookieUrls = <String>[
    'https://chzzk.naver.com/',
    'https://nid.naver.com/',
    BaseUrl.naverLogin,
    'https://naver.com/',
  ];

  /// WebView가 설정한 쿠키를 디스크에 반영하고, 만료일을 연장해 저장한다.
  Future<void> persistLoginCookies() async {
    await _syncCookieStore();

    final Auth? auth = await _readAuthFromCookieManager();
    if (auth == null) return;

    await _saveToPrefs(auth);
    await _writePersistentCookies(auth);
    await _syncCookieStore();
  }

  Future<Auth?> getAuthFromCookies() async {
    await _syncCookieStore();

    final Auth? authFromCookies = await _readAuthFromCookieManager();
    if (authFromCookies != null) {
      await _saveToPrefs(authFromCookies);
      await _writePersistentCookies(authFromCookies);
      return authFromCookies;
    }

    final Auth? authFromPrefs = _readAuthFromPrefs();
    if (authFromPrefs != null) {
      await _writePersistentCookies(authFromPrefs);
      return authFromPrefs;
    }

    return null;
  }

  /// Delete all cookies when you logged out.
  Future<void> deleteCookies() async {
    await _cookieManager.deleteAllCookies();
    await _prefs.remove(SharedPrefsDBKey.authNidAut);
    await _prefs.remove(SharedPrefsDBKey.authNidSes);
  }

  /// Android WebView 쿠키 store를 디스크와 동기화한다.
  Future<void> _syncCookieStore() async {
    await _cookieManager.setCookie(
      url: WebUri('https://naver.com'),
      name: '_chzzk_cookie_sync',
      value: '1',
      domain: '.naver.com',
      path: '/',
      maxAge: 1,
    );
  }

  Future<Auth?> _readAuthFromCookieManager() async {
    for (final url in _cookieUrls) {
      final uri = WebUri(url);

      final nidAuth =
          (await _cookieManager.getCookie(url: uri, name: 'NID_AUT'))?.value;
      final nidSession =
          (await _cookieManager.getCookie(url: uri, name: 'NID_SES'))?.value;

      if (nidAuth != null && nidSession != null) {
        return Auth(nidAuth: nidAuth, nidSession: nidSession);
      }

      final cookies = await _cookieManager.getCookies(url: uri);
      String? auth;
      String? session;

      for (final cookie in cookies) {
        if (cookie.name == 'NID_AUT') {
          auth = cookie.value;
        }
        if (cookie.name == 'NID_SES') {
          session = cookie.value;
        }
      }

      if (auth != null && session != null) {
        return Auth(nidAuth: auth, nidSession: session);
      }
    }

    return null;
  }

  Auth? _readAuthFromPrefs() {
    final nidAuth = _prefs.getString(SharedPrefsDBKey.authNidAut);
    final nidSession = _prefs.getString(SharedPrefsDBKey.authNidSes);

    if (nidAuth != null && nidSession != null) {
      return Auth(nidAuth: nidAuth, nidSession: nidSession);
    }

    return null;
  }

  Future<void> _saveToPrefs(Auth auth) async {
    await _prefs.setString(SharedPrefsDBKey.authNidAut, auth.nidAuth);
    await _prefs.setString(SharedPrefsDBKey.authNidSes, auth.nidSession);
  }

  Future<void> _writePersistentCookies(Auth auth, {int days = 14}) async {
    final expiresDate =
        DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;

    for (final url in ['https://naver.com', 'https://nid.naver.com']) {
      await _cookieManager.setCookie(
        url: WebUri(url),
        name: 'NID_AUT',
        value: auth.nidAuth,
        domain: '.naver.com',
        path: '/',
        expiresDate: expiresDate,
        isSecure: true,
      );
      await _cookieManager.setCookie(
        url: WebUri(url),
        name: 'NID_SES',
        value: auth.nidSession,
        domain: '.naver.com',
        path: '/',
        expiresDate: expiresDate,
        isSecure: true,
      );
    }
  }
}
