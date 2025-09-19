/// 챌린지 재료를 주재료와 소스&양념으로 분류하는 마이그레이션 유틸리티
/// Ultra Think 방식: 기존 데이터 보존하면서 새 구조 추가
class IngredientMigrator {
  
  /// 한글 재료 분류 사전 (한국 + 해외 요리 커버)
  static const Map<String, String> _ingredientCategories = {
    // === 주재료 (메인 식재료) ===
    // 곡물류
    '쌀': 'main', '현미': 'main', '찹쌀': 'main', '보리': 'main', '밥': 'main',
    '파스타': 'main', '스파게티': 'main', '펜네': 'main', '라면': 'main',
    '우동': 'main', '소면': 'main', '냉면': 'main', '메밀면': 'main',
    '빵': 'main', '식빵': 'main', '바게트': 'main',
    
    // 육류
    '쇠고기': 'main', '돼지고기': 'main', '닭고기': 'main', '양고기': 'main', '닭': 'main',
    '삼겹살': 'main', '목살': 'main', '등심': 'main', '안심': 'main',
    '닭가슴살': 'main', '닭다리': 'main', '베이컨': 'main', '햄': 'main',
    '소시지': 'main', '치킨': 'main',
    
    // 해산물
    '연어': 'main', '참치': 'main', '고등어': 'main', '명태': 'main',
    '새우': 'main', '오징어': 'main', '문어': 'main', '조개': 'main',
    '굴': 'main', '멸치': 'main', '건멸치': 'main', '생선': 'main',
    
    // 채소류
    '양파': 'main', '당근': 'main', '감자': 'main', '고구마': 'main',
    '배추': 'main', '무': 'main', '브로콜리': 'main', '양배추': 'main',
    '시금치': 'main', '상추': 'main', '깻잎': 'main', '미역': 'main',
    '김': 'main', '버섯': 'main', '팽이버섯': 'main', '표고버섯': 'main',
    '토마토': 'main', '오이': 'main', '호박': 'main', '애호박': 'main',
    '파프리카': 'main', '피망': 'main', '가지': 'main', '콩나물': 'main',
    '숙주': 'main', '대파': 'main', '파': 'main', '청양고추': 'main',
    
    // 유제품 & 단백질
    '두부': 'main', '계란': 'main', '달걀': 'main', '치즈': 'main',
    '모짜렐라': 'main', '파마산': 'main', '우유': 'main', '요구르트': 'main',
    
    // === 소스 & 양념 (조미료) ===
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
    
    // 서양 양념 (한글명)
    '올리브오일': 'sauce', '올리브 오일': 'sauce', '식용유': 'sauce',
    '버터': 'sauce', '마가린': 'sauce', '생크림': 'sauce',
    '발사믹식초': 'sauce', '화이트와인': 'sauce', '레드와인': 'sauce',
    '레몬즙': 'sauce', '라임즙': 'sauce', '바질': 'sauce', '로즈마리': 'sauce',
    '타임': 'sauce', '오레가노': 'sauce', '파슬리': 'sauce',
    '토마토소스': 'sauce', '케첩': 'sauce', '마요네즈': 'sauce',
    '머스타드': 'sauce', '와사비': 'sauce', '타바스코': 'sauce',
    
    // 아시아 양념 (한글명)
    '굴소스': 'sauce', '생선소스': 'sauce', '치킨스톡': 'sauce',
    '다시마': 'sauce', '멸치육수': 'sauce', '사케': 'sauce',
    '미소': 'sauce',
    
    // 향신료
    '계피': 'sauce', '정향': 'sauce', '팔각': 'sauce', '큐민': 'sauce',
    '카레가루': 'sauce', '파프리카가루': 'sauce', '칠리파우더': 'sauce',
    '월계수잎': 'sauce', '백후추': 'sauce',
  };
  
  /// 재료 리스트를 주재료와 소스&양념으로 분류
  /// [ingredients] 분류할 재료 리스트
  /// 반환: {'main': [...], 'sauce': [...]}
  static Map<String, List<String>> classifyIngredients(List<String> ingredients) {
    List<String> mainIngredients = [];
    List<String> sauceIngredients = [];
    
    for (String ingredient in ingredients) {
      String cleaned = ingredient.trim();
      String category = _ingredientCategories[cleaned] ?? 'main'; // 모르는 재료는 주재료로
      
      if (category == 'main') {
        mainIngredients.add(cleaned);
      } else {
        sauceIngredients.add(cleaned);
      }
    }
    
    return {
      'main': mainIngredients,
      'sauce': sauceIngredients,
    };
  }
  
  /// 단일 재료의 카테고리 확인 (디버깅용)
  static String getIngredientCategory(String ingredient) {
    return _ingredientCategories[ingredient.trim()] ?? 'main';
  }
  
  /// 분류 결과를 콘솔에 출력 (디버깅용)
  static void printClassification(List<String> ingredients) {
    final result = classifyIngredients(ingredients);
    print('=== 재료 분류 결과 ===');
    print('주재료: ${result['main']}');
    print('소스&양념: ${result['sauce']}');
    print('====================');
  }
  
  /// 분류 정확도 검증 (테스트용)
  static bool validateClassification(List<String> ingredients, 
      {List<String>? expectedMain, List<String>? expectedSauce}) {
    final result = classifyIngredients(ingredients);
    
    bool mainValid = expectedMain == null || 
        result['main']!.toSet().containsAll(expectedMain.toSet());
    bool sauceValid = expectedSauce == null || 
        result['sauce']!.toSet().containsAll(expectedSauce.toSet());
    
    return mainValid && sauceValid;
  }
}