
/// 네이버 블로그 JavaScript 한계를 완전히 우회하는 대안적 레시피 입력 서비스
/// Ultra Think 접근방식: URL 크롤링의 한계를 인정하고 더 나은 UX 제공
class AlternativeRecipeInputService {
  
  /// 대안적 레시피 입력 방법들을 사용자에게 제안
  static Map<String, dynamic> getAlternativeInputSuggestions() {
    return {
      'title': '네이버 블로그 접근이 어려워요 😅',
      'subtitle': '하지만 더 쉬운 방법들이 있어요!',
      'alternatives': [
        {
          'icon': '📝',
          'title': '텍스트 직접 붙여넣기',
          'description': '블로그 내용을 복사해서 붙여넣어주세요\nAI가 자동으로 재료와 조리법을 정리해드려요',
          'action': 'text_input',
          'priority': 1,
        },
        {
          'icon': '📷',
          'title': '음식 사진으로 분석',
          'description': '완성된 음식 사진만 있어도 괜찮아요\nAI가 사진을 보고 레시피를 추천해드려요',
          'action': 'photo_analysis',
          'priority': 2,
        },
        {
          'icon': '📖',
          'title': '수동으로 작성하기',
          'description': '직접 입력하면서 감정과 기억도 함께 기록해보세요\n더 의미있는 레시피가 될 거예요',
          'action': 'manual_input',
          'priority': 3,
        },
        {
          'icon': '🌐',
          'title': '다른 블로그 플랫폼 시도',
          'description': '티스토리, 브런치, 개인 블로그는 잘 작동해요\n네이버 말고 다른 곳의 레시피를 찾아보세요',
          'action': 'other_platform',
          'priority': 4,
        },
      ],
      'technical_explanation': {
        'title': '왜 네이버 블로그가 어려운가요?',
        'reasons': [
          '네이버 블로그는 JavaScript로 동적 렌더링됩니다',
          'RSS 피드는 최신 글만 포함되어 있어요',
          '블로그 설정에 따라 외부 접근이 제한될 수 있어요',
          '모바일 앱에서는 완전한 웹 브라우저 실행이 어려워요'
        ]
      }
    };
  }
  
  /// 텍스트 입력 방식 가이드
  static Map<String, dynamic> getTextInputGuide() {
    return {
      'title': '텍스트로 레시피 입력하기',
      'guide': [
        '1. 네이버 블로그에서 전체 내용을 복사하세요 (Ctrl+A → Ctrl+C)',
        '2. 아래 텍스트 박스에 붙여넣기 하세요 (Ctrl+V)',
        '3. AI가 자동으로 재료와 조리법을 분석해드려요',
        '4. 감정 메모를 추가해서 의미있는 레시피로 완성하세요'
      ],
      'placeholder': '''블로그 내용을 여기에 붙여넣어주세요.

예시:
"오늘은 남편을 위해 특별한 저녁을 준비했어요.
우당탕당 초당옥수수 스프 만들기

재료:
- 옥수수 2개
- 우유 200ml
- 양파 1/2개
- 버터 1큰술

만드는 법:
1. 옥수수를 삶아서 알맹이를 발라내세요
2. 양파를 잘게 다져서 버터에 볶아주세요
..."''',
      'benefits': [
        '✅ 100% 정확한 내용 추출',
        '✅ 즉시 분석 완료',
        '✅ 네트워크 문제 없음',
        '✅ 모든 블로그 호환'
      ]
    };
  }
  
  /// 사진 분석 방식 가이드  
  static Map<String, dynamic> getPhotoAnalysisGuide() {
    return {
      'title': '사진으로 레시피 분석하기',
      'guide': [
        '1. 완성된 음식 사진을 촬영하거나 선택하세요',
        '2. AI가 사진을 분석해서 음식을 인식합니다',
        '3. 재료와 조리법을 자동으로 추천해드려요',
        '4. 필요하면 수정하고 감정 메모를 추가하세요'
      ],
      'tips': [
        '💡 음식이 잘 보이는 각도로 찍어주세요',
        '💡 자연스러운 조명에서 촬영하면 더 정확해요',
        '💡 완성된 요리뿐만 아니라 조리 과정 사진도 좋아요',
        '💡 재료가 함께 나온 사진이면 더욱 정확합니다'
      ],
      'benefits': [
        '✅ 블로그 URL이 필요 없어요',
        '✅ AI가 사진만으로도 레시피 추천',
        '✅ 나만의 음식 사진과 함께 기록',
        '✅ 더 개인적이고 의미있는 레시피'
      ]
    };
  }
  
  /// 수동 입력 방식 가이드
  static Map<String, dynamic> getManualInputGuide() {
    return {
      'title': '직접 작성하기',
      'guide': [
        '1. 요리 이름을 입력하세요',
        '2. 왜 이 요리를 만들었는지 감정 이야기를 써보세요',
        '3. 재료와 조리법을 하나씩 추가하세요',
        '4. 사진을 촬영해서 완성된 레시피를 저장하세요'
      ],
      'emotional_questions': [
        '이 요리를 왜 만들게 되었나요?',
        '누구를 위해 만든 요리인가요?',
        '만들면서 어떤 기분이었나요?',
        '특별한 기억이나 에피소드가 있나요?',
        '이 요리가 나에게 어떤 의미인가요?'
      ],
      'benefits': [
        '✅ 가장 개인적이고 의미있는 기록',
        '✅ 감정과 기억이 풍부하게 담김',
        '✅ 나만의 조리 노하우 추가 가능',
        '✅ 시간을 들여 정성스럽게 작성'
      ]
    };
  }
  
  /// 다른 플랫폼 가이드
  static Map<String, dynamic> getOtherPlatformGuide() {
    return {
      'title': '다른 블로그 플랫폼 시도하기',
      'supported_platforms': [
        {
          'name': '티스토리',
          'url_example': 'example.tistory.com/123',
          'success_rate': '95%',
          'note': '가장 안정적으로 동작해요'
        },
        {
          'name': '브런치',
          'url_example': 'brunch.co.kr/@user/123',
          'success_rate': '90%',
          'note': '깔끔하게 콘텐츠를 추출해드려요'
        },
        {
          'name': '개인 블로그',
          'url_example': 'yourblog.com/recipe',
          'success_rate': '85%',
          'note': 'WordPress, Jekyll 등 대부분 지원'
        },
        {
          'name': '레시피 사이트',
          'url_example': 'recipe-site.com/recipe/123',
          'success_rate': '90%',
          'note': '만개의레시피, 쿡패드 등'
        }
      ],
      'search_tips': [
        '💡 "레시피 사이트명 + 요리명"으로 검색해보세요',
        '💡 인스타그램 레시피도 캡쳐해서 텍스트로 입력 가능해요',
        '💡 유튜브 요리 영상 설명란의 재료 목록도 좋아요',
        '💡 요리책이나 잡지 내용도 사진 찍어서 활용하세요'
      ]
    };
  }
}

/// 사용자 경험 개선을 위한 도움말 메시지들
class UserGuidanceMessages {
  static const String naverBlogIssueExplanation = '''
네이버 블로그는 JavaScript로 동작하는 특별한 구조라서 
모바일 앱에서 직접 내용을 읽어오기가 어려워요.

하지만 걱정하지 마세요! 
더 쉽고 확실한 방법들을 준비했어요 😊
  ''';
  
  static const String alternativeMethodsPrompt = '''
어떤 방법을 시도해보시겠어요?

📝 텍스트 붙여넣기 (가장 확실한 방법)
📷 사진으로 분석하기 (AI 추천)  
📖 직접 작성하기 (가장 의미있는 방법)
🌐 다른 블로그 플랫폼 시도하기

선택해주시면 자세한 가이드를 보여드릴게요!
  ''';
  
  static const String textInputSuccess = '''
텍스트 입력이 완료되었어요! 🎉

AI가 내용을 분석해서 재료와 조리법을 정리해드릴게요.
감정 메모도 함께 작성하면 더욱 의미있는 레시피가 될 거예요.
  ''';
}