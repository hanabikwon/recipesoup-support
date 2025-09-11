# 작업 완료 시 체크리스트

## 코드 작성 후 필수 실행 사항

### 1. 정적 분석 (필수)
```bash
flutter analyze
```
- 코딩 컨벤션 준수 확인
- 잠재적 에러 및 경고 해결
- 타입 안전성 검증

### 2. 테스트 실행 (필수)
```bash
# 전체 테스트 실행
flutter test

# 특정 테스트만 실행 (필요시)
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```
- 모든 기존 테스트 통과 확인
- 새로운 기능에 대한 테스트 추가
- 코드 커버리지 80% 이상 유지

### 3. 코드 포맷팅 (필수)
```bash
flutter format .
```
- 일관된 코드 스타일 유지
- 가독성 향상

### 4. Mock 생성 (필요시)
```bash
flutter packages pub run build_runner build
```
- 새로운 서비스나 모델 추가 시
- 테스트에서 Mock 사용하는 경우

### 5. 환경별 테스트 (권장)
```bash
# 개발 환경에서 실행 테스트
flutter run

# 웹 빌드 테스트
flutter build web
```

## 코드 품질 가이드라인

### 성능 최적화
- const 위젯 사용 최대화
- 불필요한 rebuild 방지
- 이미지 캐싱 및 최적화

### 에러 처리
- try-catch 블록 적절히 사용
- 사용자 친화적 에러 메시지
- Provider에서 에러 상태 관리

### 접근성
- Semantics 위젯 활용
- 키보드 네비게이션 지원
- 색상 대비 확인

## Git 커밋 전 체크리스트
- [ ] `flutter analyze` 통과
- [ ] `flutter test` 모든 테스트 통과
- [ ] `flutter format .` 적용
- [ ] 새로운 기능에 대한 테스트 작성
- [ ] 문서 업데이트 (필요시)
- [ ] .env 파일 .gitignore 확인

## 배포 전 추가 체크리스트
- [ ] 프로덕션 빌드 테스트
- [ ] 모든 플랫폼에서 동작 확인
- [ ] API 키 등 민감정보 보안 확인
- [ ] 앱 아이콘 및 스플래시 스크린 적용
- [ ] 앱 스토어 메타데이터 준비

## 문제 해결
### 일반적인 문제들
1. **테스트 실패**: Mock 클래스 재생성 필요
2. **빌드 에러**: 의존성 버전 충돌 확인
3. **성능 이슈**: Flutter Inspector 사용
4. **UI 렌더링 문제**: 위젯 트리 구조 검토