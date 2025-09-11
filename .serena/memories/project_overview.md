# Recipesoup 프로젝트 개요

## 프로젝트 목적
**Recipesoup**는 감정 기반 레시피 아카이빙 Flutter 앱으로, 단순한 요리 방법 저장을 넘어 그 순간의 감정과 기억을 함께 기록하는 감성 레시피 다이어리입니다.

## 주요 기능
- 📝 감정 메모와 함께하는 레시피 작성
- 📷 AI 기반 음식 사진 분석 (OpenAI GPT-4o-mini)
- 🏠 완전한 오프라인 지원 (로컬 저장)
- 🎭 8가지 감정 상태 분류 (기쁨, 평온, 슬픔, 피로, 설렘, 그리움, 편안함, 감사)
- 📅 "과거 오늘" 기능 (같은 날짜 과거 레시피 회상)
- 📊 개인 요리 패턴 분석

## 기술 스택
- **Frontend**: Flutter 3.x (크로스 플랫폼)
- **State Management**: Provider + ChangeNotifier
- **Local Storage**: Hive NoSQL (완전 오프라인)
- **AI/ML**: OpenAI GPT-4o-mini
- **HTTP Client**: dio
- **Design**: Material Design 3 기반 빈티지 아이보리 테마

## 지원 플랫폼
- iOS, Android, Web, macOS, Windows

## 아키텍처 특징
- Bottom Navigation 5탭 구조 (홈, 검색, 통계, 보관함, 설정)
- 완전 오프라인 우선 설계 (AI 분석은 옵션)
- Provider 기반 심플한 상태 관리
- Hive를 통한 빠른 NoSQL 로컬 저장