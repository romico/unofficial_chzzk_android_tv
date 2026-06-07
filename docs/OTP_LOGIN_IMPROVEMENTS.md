# OTP 로그인 개선 내역

OTP(일회용 로그인 번호) 로그인 UX 및 안정성 개선 작업을 정리한 문서입니다.

## 배경

- 네이버 OTP 유효 시간은 **약 20초**로 짧음
- Android TV는 리모컨 입력만 가능해 QWERTY 전체 키보드로는 시간 내 입력이 어려움
- WebView 쿠키만으로 로그인 상태를 유지할 경우, 앱 종료 직후 세션이 풀리는 문제가 있었음

## 개선 요약

| 구분 | 내용 |
|------|------|
| 로그인 안정성 | OTP 직후 조기 API 호출 제거, User 파싱 방어, 쿠키 SharedPreferences 백업 |
| 입력 UX | 숫자 전용 3×4 키패드, 8자리 4-4 표시, 8자리 완료 시 자동 제출 |
| 플랫폼 호환 | `getAllCookies()` 미지원 환경 대응 |

---

## 1. OTP 로그인 크래시 수정

### 문제
- OTP Enter 직후 `getUserStatus` API를 너무 일찍 호출
- 응답 `nickname`이 null일 때 `User.fromJson`에서 type cast 크래시

### 해결
- OTP 버튼 클릭 직후 `_trySignIn` 제거 → WebView가 `chzzk.naver.com`으로 리다이렉트된 뒤 로그인 처리
- `User.nickname` nullable 처리
- `fetchUser()` try-catch 및 null 응답 시 쿠키 삭제 조건 완화

### 관련 파일
- `lib/src/features/auth/auth_event.dart`
- `lib/src/features/user/model/user.dart`
- `lib/src/features/user/controller/user_controller.dart`

---

## 2. 로그인 상태 유지

### 문제
- 로그인 정보가 WebView `CookieManager`에만 의존
- Android WebView 쿠키가 디스크에 flush되기 전 앱 종료 시 세션 소실
- `fetchUser` 실패 시 `deleteAllCookies()`로 유효 쿠키까지 삭제

### 해결
- `NID_AUT`, `NID_SES`를 SharedPreferences에 백업
- 로그인 성공 시 `persistLoginCookies()`로 만료일 연장 및 prefs 저장
- 앱 시작 시 WebView 쿠키 → prefs 순으로 복원
- API 일시 실패 시 쿠키를 즉시 삭제하지 않음
- `userController`가 `authController` 완료 후 API 호출 (초기화 레이스 방지)

### `getAllCookies()` 미지원 대응
- Android TV 등에서 `getAllCookies()`가 `UnimplementedError`를 발생
- URL별 `getCookie` / `getCookies`만 사용 (`chzzk.naver.com` 우선 조회)

### 관련 파일
- `lib/src/features/auth/repository/auth_repository.dart`
- `lib/src/utils/shared_preferences/shared_prefs.dart`

---

## 3. 숫자 전용 OTP 키패드

### 변경
- `VirtualKeyboardLayoutType.numeric` 추가
- 3×4 레이아웃: `1-9`, `지움`, `0`, `입력`
- 최대 8자리 (`maxInputLength: 8`)
- 입력 필드 4-4 표시 (`1234 5678`, `groupSize: 4`)

### 관련 파일
- `lib/src/common/constants/enums.dart`
- `lib/src/utils/virtual_keyboard/data/virtual_keyboard_data.dart`
- `lib/src/utils/virtual_keyboard/widgets/virtual_keyboard_layout.dart`
- `lib/src/utils/virtual_keyboard/widgets/virtual_keyboard_input_field.dart`
- `lib/src/features/auth/widgets/screen/auth_body.dart`

---

## 4. 20초 OTP 입력 최적화

### 자동 제출
- 8자리 입력 완료 시 `입력` 버튼 없이 자동으로 OTP 전송 (`autoSubmitOnMaxLength: true`)
- 8자리 미만일 때는 제출하지 않음

### 권장 입력 순서
1. **휴대폰** 네이버 앱에서 일회용 번호 발급
2. **TV**에서 숫자 8자리 연속 입력 (자동 제출)
3. 만료 시 휴대폰에서 번호 재발급 후 재입력

### 관련 파일
- `lib/src/utils/virtual_keyboard/widgets/virtual_keyboard_layout.dart`
- `lib/src/features/auth/auth_event.dart`
- `lib/src/features/auth/widgets/screen/naver_login_header_text.dart`

---

## 5. Git / 릴리즈

- 커밋 메시지는 **한글** 사용
- `Co-authored-by` 트레일러 없이 커밋하려면 Cursor Agent Attribution 비활성화 또는 `git commit-tree` 사용
- 자동 빌드: `v*` 태그 push 시 GitHub Actions Release 워크플로 실행 (`.github/workflows/release.yml`)

---

## 향후 검토 사항

- OTP 만료/오류 시 사용자에게 재발급 안내 UI
- WebView `CookieManager.flush()` API 지원 버전 업 시 명시적 flush 호출
- 세션 만료 시 prefs + 쿠키 정리 로직 세분화 (401 등 명확한 인증 실패만 삭제)
