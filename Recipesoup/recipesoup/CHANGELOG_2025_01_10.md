# 변경 사항 - 2025년 1월 10일

## 📋 개요
레시피 링크 기능 추가 및 챌린지 진행중 개수 표시 버그 수정

---

## 🔧 수정 사항

### 1. 레시피 링크 기능 구현

#### 1.1 상세 화면에 링크 표시 및 바텀시트 추가
**파일**: `lib/screens/detail_screen.dart`

**추가된 기능**:
- 레시피에 sourceUrl이 있을 때 링크 UI 표시
- 링크 클릭 시 바텀시트 표시
  - **링크 복사하기**: 클립보드에 URL 복사
  - **바로가기**: 외부 브라우저에서 URL 열기
- 빈티지 아이보리 테마 적용
- 성공/실패 스낵바 피드백

**추가된 import**:
```dart
import 'package:flutter/services.dart';        // Clipboard API
import 'package:url_launcher/url_launcher.dart'; // URL 열기
```

**추가된 메서드**:
```dart
void _showLinkBottomSheet(String url) {
  // 모달 바텀시트 구현
  // - 링크 복사 기능 (Clipboard.setData)
  // - 바로가기 기능 (launchUrl)
}
```

**UI 변경**:
- `_buildRecipeInfo()` 메서드에 링크 표시 UI 추가 (227-272번 라인)
- 링크 아이콘 변경: `Icons.open_in_browser` → `Icons.open_in_new` (더 명확한 아이콘)

#### 1.2 레시피 카드에 URL 존재 여부 표시
**파일**: `lib/widgets/recipe/recipe_card.dart`

**추가된 기능**:
- 레시피 리스트/그리드에서 URL이 있는 레시피 표시
- 작은 링크 아이콘으로 시각적 피드백

**변경된 메서드**:

1. `_buildFooter()` (155-172번 라인)
```dart
// 일반 레이아웃용 - 아이콘 크기 14
if (recipe.sourceUrl != null && recipe.sourceUrl!.isNotEmpty)
  Icon(
    Icons.link,
    size: 14,
    color: AppTheme.primaryColor,
  ),
```

2. `_buildCompactFooter()` (174-208번 라인)
```dart
// 컴팩트 레이아웃용 - 아이콘 크기 12
if (recipe.sourceUrl != null && recipe.sourceUrl!.isNotEmpty)
  Icon(
    Icons.link,
    size: 12,
    color: AppTheme.primaryColor,
  ),
```

---

### 2. 챌린지 진행중 개수 표시 버그 수정

#### 2.1 문제 상황
- 챌린지를 시작해도 "진행중인 레시피" 개수가 업데이트되지 않음
- 챌린지를 완료할 때만 개수가 업데이트됨
- 사용자가 "완료된 레시피랑 로직이 연결되어 있는 것 같다"고 보고

#### 2.2 원인 분석
**파일**: `lib/providers/challenge_provider.dart`

**분석 결과**:
- `completeChallenge()` 메서드: `await _refreshUserData()` 호출 ✅
- `startChallenge()` 메서드: `await _refreshUserData()` 호출 ❌

**문제점**:
```dart
// 기존 코드 (171-188번 라인)
Future<bool> startChallenge(String challengeId) async {
  try {
    _clearError();

    final progress = await _challengeService.startChallenge(challengeId);
    _userProgress[challengeId] = progress;

    // ❌ 통계 업데이트 누락!

    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    return false;
  }
}
```

#### 2.3 적용된 수정
**파일**: `lib/providers/challenge_provider.dart` (180번 라인)

```dart
Future<bool> startChallenge(String challengeId) async {
  try {
    _clearError();

    final progress = await _challengeService.startChallenge(challengeId);
    _userProgress[challengeId] = progress;

    // ✅ 통계 업데이트 추가 (진행중 개수 변경)
    await _refreshUserData();

    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    return false;
  }
}
```

**효과**:
- 챌린지 시작 시 즉시 통계 업데이트
- `inProgressChallenges` 카운트가 실시간으로 증가
- 챌린지 완료 시 통계 업데이트 (기존 유지)
- `inProgressChallenges` 카운트가 실시간으로 감소

---

## 📦 의존성

### 기존 패키지 사용
**파일**: `pubspec.yaml`

```yaml
dependencies:
  url_launcher: ^6.2.1  # 이미 존재 - 추가 설치 불필요
```

---

## 🧪 테스트 가이드

### 1. 레시피 링크 기능 테스트

#### 1.1 상세 화면 링크 표시
1. sourceUrl이 있는 레시피 생성/편집
2. 상세 화면에서 링크 UI 확인
3. 링크 영역 탭하여 바텀시트 표시 확인

#### 1.2 링크 복사 기능
1. 바텀시트에서 "링크 복사하기" 탭
2. 성공 스낵바 확인
3. 다른 앱에 붙여넣기로 URL 확인

#### 1.3 바로가기 기능
1. 바텀시트에서 "바로가기" 탭
2. 외부 브라우저에서 URL 열림 확인
3. 잘못된 URL인 경우 에러 스낵바 확인

#### 1.4 레시피 카드 링크 아이콘
1. 보관함(아카이브) 화면 이동
2. sourceUrl이 있는 레시피에 링크 아이콘 표시 확인
3. sourceUrl이 없는 레시피에 아이콘 미표시 확인

### 2. 챌린지 진행중 개수 테스트

#### 2.1 챌린지 시작 시
1. 챌린지 허브 화면에서 "진행중인 레시피" 개수 확인
2. 새 챌린지 시작
3. "진행중인 레시피" 개수 즉시 증가 확인 ✅

#### 2.2 챌린지 완료 시
1. 진행중인 챌린지 완료
2. "진행중인 레시피" 개수 즉시 감소 확인 ✅
3. "완료한 레시피" 개수 즉시 증가 확인 ✅

---

## 🐛 알려진 이슈

없음

---

## 📝 참고 사항

### 코드 변경 위치 요약

| 파일 | 변경 내용 | 라인 |
|------|----------|------|
| `lib/screens/detail_screen.dart` | import 추가 (Clipboard, url_launcher) | 1-12 |
| `lib/screens/detail_screen.dart` | 링크 표시 UI 추가 | 227-272 |
| `lib/screens/detail_screen.dart` | `_showLinkBottomSheet()` 메서드 추가 | 900-1053 |
| `lib/widgets/recipe/recipe_card.dart` | `_buildFooter()` 링크 아이콘 추가 | 155-172 |
| `lib/widgets/recipe/recipe_card.dart` | `_buildCompactFooter()` 링크 아이콘 추가 | 174-208 |
| `lib/providers/challenge_provider.dart` | `startChallenge()` 통계 업데이트 추가 | 180 |

### 테마 일관성
- 모든 UI 요소에 빈티지 아이보리 테마 적용
- `AppTheme.primaryColor` 사용 (링크 아이콘)
- `AppTheme.accentOrange` 사용 (바로가기 버튼 배경)

### 사용자 경험 개선
- 명확한 시각적 피드백 (스낵바)
- 외부 브라우저 열기로 앱 내 안정성 유지
- 진행중 개수 실시간 업데이트로 즉각적인 피드백

---

## ✅ 체크리스트

- [x] 레시피 링크 UI 구현
- [x] 링크 복사 기능 구현
- [x] 바로가기 기능 구현
- [x] 레시피 카드 링크 아이콘 추가
- [x] 챌린지 진행중 개수 버그 수정
- [x] 테마 일관성 유지
- [x] 에러 처리 및 사용자 피드백
- [ ] 릴리즈 빌드 테스트 (사용자 진행 예정)

---

**작성일**: 2025년 1월 10일
**작성자**: Claude (AI Assistant)
**버전**: 1.0
