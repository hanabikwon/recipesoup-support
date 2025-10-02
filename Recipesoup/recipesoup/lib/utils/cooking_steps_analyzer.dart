import 'package:flutter/foundation.dart';

/// cooking_steps에서 소스&양념 정보를 추출하는 분석기
/// Ultra Think: 기존 IngredientMigrator와 호환되는 방식으로 설계
class CookingStepsAnalyzer {

  /// 소스 제작을 나타내는 키워드 패턴들 (Ultra Think: 10개 문제 레시피 분석 결과 확장)
  static const List<String> _sauceKeywords = [
    // 직접적인 소스 제작 패턴
    '소스를 만들어',
    '소스를 준비',
    '양념을 섞어',
    '양념장을 만들어',
    '드레싱을 만들어',
    '타레를 만들어',

    // 무침/볶음 패턴 (나물 요리 등)
    '무쳐주세요',
    '무쳐줍니다',
    '볶아 무쳐',
    '무치는',

    // 간 맞추기 패턴
    '간을 맞춰',
    '간을 해서',
    '간을 조절',

    // 특정 소스명 언급
    '간장소스',
    '참기름 소스',
    '마요네즈 소스',
    '겨자소스',
    '베샤멜소스',
    '베샤멜',

    // 서양식 조리 패턴
    '드레싱',
    '루를 만들고',
    '루를 만들어',
    '올리브오일을 두르고',
    '올리브오일과',
    '레몬즙을',

    // 한식 양념 패턴
    '참기름으로',
    '참기름과',
    '간장을 넣고',
    '고추장을',
    '된장을'
  ];

  /// 기존 IngredientMigrator의 소스 카테고리를 재사용
  static const Map<String, String> _sauceIngredients = {
    // 기본 조미료
    '소금': 'sauce', '설탕': 'sauce', '후추': 'sauce', '후춧가루': 'sauce',
    '마늘': 'sauce', '다진마늘': 'sauce', '생강': 'sauce', '다진생강': 'sauce',

    // 한국 양념
    '간장': 'sauce', '국간장': 'sauce', '진간장': 'sauce', '양조간장': 'sauce',
    '고추장': 'sauce', '된장': 'sauce', '쌈장': 'sauce', '춘장': 'sauce',
    '고춧가루': 'sauce', '건고추': 'sauce', '청고추': 'sauce',
    '참기름': 'sauce', '들기름': 'sauce', '깨소금': 'sauce', '깨': 'sauce',
    '맛술': 'sauce', '청주': 'sauce', '미림': 'sauce', '식초': 'sauce',
    '물엿': 'sauce', '올리고당': 'sauce', '꿀': 'sauce',

    // 서양 양념 (한글명) - Ultra Think: 누락 항목 추가
    '올리브오일': 'sauce', '올리브 오일': 'sauce', '식용유': 'sauce',
    '버터': 'sauce', '마가린': 'sauce', '생크림': 'sauce',
    '발사믹식초': 'sauce', '화이트와인': 'sauce', '레드와인': 'sauce',
    '레몬즙': 'sauce', '라임즙': 'sauce', '바질': 'sauce', '로즈마리': 'sauce',
    '타임': 'sauce', '오레가노': 'sauce', '파슬리': 'sauce',
    '토마토소스': 'sauce', '케첩': 'sauce', '마요네즈': 'sauce',
    '머스타드': 'sauce', '와사비': 'sauce', '타바스코': 'sauce',
    '밀가루': 'sauce', // 베샤멜소스용 루 제작
    '우유': 'sauce', // 베샤멜소스 베이스

    // 아시아 양념 (한글명)
    '굴소스': 'sauce', '생선소스': 'sauce', '치킨스톡': 'sauce',
    '다시마': 'sauce', '멸치육수': 'sauce', '사케': 'sauce',
    '미소': 'sauce',

    // 향신료
    '계피': 'sauce', '정향': 'sauce', '팔각': 'sauce', '큐민': 'sauce',
    '카레가루': 'sauce', '파프리카가루': 'sauce', '칠리파우더': 'sauce',
    '월계수잎': 'sauce', '백후추': 'sauce',
  };

  /// cooking_steps에서 소스&양념 재료를 추출
  /// [cookingSteps] 요리 단계 리스트
  /// 반환: 추출된 소스&양념 재료 리스트
  static List<String> extractSauceFromCookingSteps(List<String> cookingSteps) {
    Set<String> extractedSauces = {};

    for (String step in cookingSteps) {
      // 소스 관련 단계인지 확인
      if (_isSauceStep(step)) {
        List<String> sauceIngredientsInStep = _extractIngredientsFromStep(step);
        extractedSauces.addAll(sauceIngredientsInStep);
      }
    }

    return extractedSauces.toList();
  }

  /// 해당 단계가 소스 제작 단계인지 확인
  static bool _isSauceStep(String step) {
    String lowerStep = step.toLowerCase();
    return _sauceKeywords.any((keyword) => lowerStep.contains(keyword.toLowerCase()));
  }

  /// 요리 단계 텍스트에서 소스 재료들을 추출
  /// 예: "간장 2큰술, 참기름 1큰술, 와사비 적량을 섞어 소스를 만들어주세요"
  /// → ["간장", "참기름", "와사비"]
  static List<String> _extractIngredientsFromStep(String step) {
    List<String> foundIngredients = [];

    // 등록된 소스 재료들 중에서 해당 단계에 포함된 것들 찾기
    _sauceIngredients.keys.forEach((ingredient) {
      if (step.contains(ingredient)) {
        foundIngredients.add(ingredient);
      }
    });

    return foundIngredients;
  }

  /// 디버깅용: 추출 과정을 상세히 출력
  static void debugExtraction(List<String> cookingSteps) {
    if (kDebugMode) {
      print('=== Cooking Steps 소스 분석 ===');
    }

    for (int i = 0; i < cookingSteps.length; i++) {
      String step = cookingSteps[i];
      bool isSauceStep = _isSauceStep(step);

      if (kDebugMode) {
        print('${i + 1}. $step');
      }

      if (isSauceStep) {
        List<String> extractedIngredients = _extractIngredientsFromStep(step);
        if (kDebugMode) {
          print('   → 소스 단계 감지: $extractedIngredients');
        }
      }
    }

    List<String> finalResult = extractSauceFromCookingSteps(cookingSteps);
    if (kDebugMode) {
      print('최종 추출된 소스&양념: $finalResult');
      print('==============================');
    }
  }

  /// 기존 sauce_seasoning과 cooking_steps에서 추출한 소스를 통합
  /// [existingSauces] 기존 sauce_seasoning 필드
  /// [cookingSteps] 요리 단계 리스트
  /// 반환: 통합된 소스&양념 리스트 (중복 제거)
  static List<String> combineSauceData(List<String> existingSauces, List<String> cookingSteps) {
    Set<String> combinedSauces = {};

    // 기존 소스 추가
    combinedSauces.addAll(existingSauces);

    // cooking_steps에서 추출한 소스 추가
    List<String> extractedSauces = extractSauceFromCookingSteps(cookingSteps);
    combinedSauces.addAll(extractedSauces);

    return combinedSauces.toList();
  }
}