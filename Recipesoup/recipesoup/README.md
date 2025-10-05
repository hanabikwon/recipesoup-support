# Recipesoup 🍲

**감정 기반 레시피 아카이빙 툴**

단순히 요리 방법을 저장하는 것이 아니라, **이 요리를 왜 만들었는지, 누구를 위해 만들었는지** 그 순간의 감정과 기억까지 함께 기록하는 감성 레시피 다이어리입니다.

## ✨ 주요 기능

- 📝 **감정 메모와 함께하는 레시피 작성**: 요리에 담긴 이야기와 감정을 함께 기록
- 📷 **AI 기반 음식 사진 분석**: OpenAI API를 활용한 재료와 조리법 자동 추천
- 🏠 **완전한 오프라인 지원**: 모든 데이터를 로컬에 저장하는 개인 아카이빙
- 🎭 **8가지 감정 상태 분류**: 기쁨, 평온, 슬픔, 피로, 설렘, 그리움, 편안함, 감사
- 📊 **개인 요리 패턴 분석**: 감정별, 시간대별 요리 성향 분석

## 🛠 기술 스택

- **Framework**: Flutter 3.x (Cross-platform)
- **AI/ML**: OpenAI GPT-4o-mini (음식 사진 분석)
- **Local Storage**: Hive NoSQL (완전 오프라인)
- **State Management**: Provider + ChangeNotifier
- **Design**: 빈티지 아이보리 테마

## 🚀 시작하기

### 환경 설정
1. `.env` 파일 생성:
```
OPENAI_API_KEY=your_openai_api_key_here
API_MODEL=gpt-4o-mini
```

### 실행
```bash
flutter pub get
flutter run
```

### 웹 빌드
```bash
flutter build web
```

## 📱 지원 플랫폼

- ✅ iOS
- ✅ Android  
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🎨 디자인 컨셉

따뜻한 빈티지 아이보리 톤으로 감정 회고에 집중할 수 있는 시각적 안정성을 제공합니다.

---

*요리하는 사람의 마음까지 남기는 공간* 💝
