/// Recipesoup 앱 전역 상수들
/// 감정 기반 레시피 데이터 기본값과 앱 전역 설정들
library;

class AppConstants {
  // 앱 기본 정보
  static const String appName = 'Recipesoup';
  static const String appSubtitle = '감정 기반 레시피 다이어리';
  static const String appDescription = '음식 사진 분석으로 재료를 알 도록이, 그 요리를 왜 만들었는지, 어떤 마음으로 만들었는지를 함께 기록하여 단순한 정보 저장이 아닌 감성 레시피 저장소';
  static const String appVersion = '1.0.0';

  // API 설정
  static const String openAiModel = 'gpt-4o-mini';
  static const int apiTimeoutSeconds = 30;
  static const int apiRetryAttempts = 3;

  // 로컬 저장소 설정
  static const String recipeBoxName = 'recipes';
  static const String settingsBoxName = 'settings';
  static const String statsBoxName = 'user_stats';
  static const String burrowMilestonesBoxName = 'burrow_milestones';
  static const String burrowProgressBoxName = 'unlock_progress';
  
  // 이미지 설정
  static const int maxImageSizeMB = 10;
  static const int imageQuality = 85;
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 800;
  
  // 감정 기반 설정 (핵심!)
  static const int minEmotionalStoryLength = 1; // 감정 텍스트 최소 길이
  static const int maxEmotionalStoryLength = 1000; // 감정 텍스트 최대 길이
  static const int maxRecipeTitleLength = 100;
  static const int maxIngredientsCount = 50;
  static const int maxInstructionsCount = 30;
  static const int maxTagsCount = 20;
  static const int maxTagLength = 20;
  
  // 평점 설정
  static const int minRating = 1;
  static const int maxRating = 5;
  
  // UI 설정
  static const int bottomNavItemsCount = 6;
  static const double cardElevation = 2.0;
  static const double fabElevation = 6.0;
  static const double appBarElevation = 0.0;
  
  // 검색 설정
  static const int searchResultsLimit = 50;
  static const int recentSearchesLimit = 10;
  static const String searchHintText = '요리명, 감정, 재료로 검색하세요';
  
  // "과거 오늘" 기능 설정
  static const int pastTodayMaxYears = 10; // 최대 10년 이전까지
  static const String pastTodayEmptyMessage = '오늘 같은날에 만든 요리가 없네요?';
  
  // 통계 설정
  static const int statsMaxDays = 365; // 최대 1년간 통계
  static const int continuousStreakMaxDays = 365; // 연속 기록 최대 일수
  
  // 감정별 기본 태그 (기본값)
  static const Map<String, List<String>> defaultTagsByMood = {
    'happy': ['#기쁨', '#축하', '#기념일', '#성공', '#새로움'],
    'peaceful': ['#평온', '#여유', '#차분', '#휴식', '#명상시간'],
    'sad': ['#슬픔', '#위로', '#그리움', '#혼자', '#기억'],
    'tired': ['#피곤', '#간편식', '#빠르게', '#야식', '#지쳐서'],
    'excited': ['#설렘', '#새로운도전', '#신나는일', '#기대', '#특별함'],
    'nostalgic': ['#그리움', '#추억', '#어린시절', '#고향', '#옛날'],
    'comfortable': ['#편안함', '#안정', '#평상시', '#가족', '#익숙함'],
    'grateful': ['#감사', '#고마움', '#사랑', '#배려', '#정성'],
  };
  
  // 상황별 태그 묶음
  static const List<String> occasionTags = [
    '#생일', '#기념일', '#성공', '#데이트', '#집들이',
    '#명절', '#졸업', '#승진', '#시험', '#특별한기념일'
  ];
  
  static const List<String> relationshipTags = [
    '#여유', '#안정', '#친구', '#연인', '#가족들',
    '#그리움', '#빠르게', '#휴식', '#정성', '#혼자만의시간'
  ];
  
  static const List<String> cookingStyleTags = [
    '#간편식', '#정성요리', '#건강식', '#다이어트', '#야식',
    '#성공', '#위로', '#새로움', '#특별함', '#편안함'
  ];
  
  static const List<String> timeTags = [
    '#아침', '#점심', '#저녁', '#새벽', '#야근후',
    '#주말', '#휴일', '#비오는날', '#더운날', '#추운날'
  ];
  
  // 감정적 텍스트 가이드
  static const String emotionalStoryGuide = '그 요리를 왜 만들었나요? 어떤 마음이었나요? 누구를 위해서였나요?';
  static const List<String> emotionalStoryExamples = [
    '더위에 지쳐 집에 온 나를 위한 시원한 위로...',
    '바쁜 하루 끝, 마음을 달래는 한 그릇...',
    '오늘은 나를 위한 시간, 간단하지만 특별하게...',
    '스트레스받은 하루, 건강하면서도 맛있게...',
    '5분만에 완성하는 나만의 힐링 레시피...'
  ];
  
  // 오류 텍스트
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요';
  static const String apiErrorMessage = 'AI 분석 중 오류가 발생했습니다';
  static const String storageErrorMessage = '데이터 저장 중 오류가 발생했습니다';
  static const String imageErrorMessage = '이미지 처리 중 오류가 발생했습니다';
  
  // 토끼굴 시스템 오류 텍스트
  static const String burrowLoadErrorMessage = '토끼굴 데이터를 불러올 수 없습니다';
  static const String burrowSaveErrorMessage = '토끼굴 진행 상황 저장에 실패했습니다';
  static const String burrowUnlockErrorMessage = '마일스톤 잠금 해제 중 오류가 발생했습니다';
  static const String burrowImageErrorMessage = '토끼굴 이미지를 불러올 수 없습니다';
  
  // 성공 텍스트
  static const String recipeSavedMessage = '레시피가 저장되었습니다';
  static const String recipeUpdatedMessage = '레시피가 수정되었습니다';
  static const String recipeDeletedMessage = '레시피가 삭제되었습니다';
  
  // 토끼굴 시스템 성공 텍스트
  static const String burrowMilestoneUnlockedMessage = '새로운 마일스톤을 달성했습니다!';
  static const String burrowSpecialRoomUnlockedMessage = '특별한 공간이 열렸습니다!';
  static const String burrowProgressSavedMessage = '토끼굴 진행 상황이 저장되었습니다';
  
  // Bottom Navigation 라벨
  static const List<String> bottomNavLabels = [
    '홈',
    '검색', 
    '토끼굴',
    '통계',
    '보관함',
    '설정',
  ];
  
  // 빈 상태 텍스트들
  static const String emptyRecipesMessage = '아직 작성한 레시피가 없네요\\n첫 번째 감정과 함께 레시피를 작성해보세요!';
  static const String emptySearchMessage = '검색 결과가 없네요\\n다른 키워드로 찾아보세요';
  static const String emptyFavoritesMessage = '즐겨찾기한 레시피가 없네요';
  static const String emptyStatsMessage = '통계를 보려면 레시피를 더 작성해보세요';
  
  // 토끼굴 빈 상태 텍스트들  
  static const String emptyBurrowMessage = '아직 달성한 마일스톤이 없네요\\n레시피를 작성해서 토끼굴을 성장시켜보세요!';
  static const String emptySpecialRoomsMessage = '특별한 공간은 숨겨진 조건을 만족해야 열립니다';
  static const String burrowInitializingMessage = '토끼굴을 준비하고 있어요...';
  
  // 난이도 레벨 한국어 매핑
  static const Map<String, String> difficultyLevels = {
    'easy': '쉬움',
    'medium': '보통', 
    'hard': '어려움',
  };
  
  // 요리 단위들 (한국 요리에서 자주 사용)
  static const List<String> commonUnits = [
    'g', 'kg', 'ml', 'L', '개', '마리', '큰술', '작은술',
    '컵', '공기', '모', '줄기', '다발', '손바닥', '조각', '쪽',
    '팩', '캔', '봉지', 'L', '리터'
  ];
  
  // 애니메이션 타이밍
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // 토끼굴 시스템 설정
  static const int burrowGrowthTrackLevels = 5;  // 성장 트랙 레벨 (1-5)
  static const int burrowSpecialRoomCount = 5;   // 특별 공간 개수
  static const int burrowSpecialRoomStartLevel = 100;  // 특별 공간 시작 레벨
  static const int burrowMaxNotificationQueue = 3;     // 최대 알림 큐 개수
  static const int burrowDebounceMs = 1000;            // 디바운스 시간 (ms)
  static const int burrowAnimationDurationMs = 800;    // 토끼굴 애니메이션 시간
  
  // 토끼굴 성장 트랙 설정 (레시피 개수별 잠금 해제)
  static const Map<int, int> burrowGrowthMilestones = {
    1: 1,      // 레벨 1: 레시피 1개
    2: 3,      // 레벨 2: 레시피 3개  
    3: 5,      // 레벨 3: 레시피 5개
    4: 7,      // 레벨 4: 레시피 7개
    5: 10,     // 레벨 5: 레시피 10개
  };
  
  // 스플래시 관련 설정
  static const int splashDurationMs = 2500;
  static const String splashMessage = '감정과 함께 레시피를 기록하세요';
  
  // 개인정보 보호 및 보안 관련
  static const String privacyMessage = 'Recipesoup은 모든 데이터를 기기 내에서만 저장합니다. 개인정보는 외부로 전송되지 않습니다.';
  static const String apiKeyWarningMessage = 'API 키가 유효하지 않으면 레시피 분석이 불가능합니다.';
  
  // 개발자 정보
  static const String developerInfo = '🤖 Generated with Claude Code\\nCo-Authored-By: Claude <noreply@anthropic.com>';
  
  // 지원 및 피드백
  static const String feedbackEmail = 'feedback@recipesoup.com';
  static const String supportUrl = 'https://github.com/recipesoup/support';
}