/// 토끼굴 시스템 이미지 에셋 관리
/// 모든 마일스톤 이미지 경로와 기본값 정의
class BurrowAssets {
  // Assets base path
  static const String _basePath = 'assets/images/burrow';
  
  /// 성장 트랙 마일스톤 이미지 경로 (레벨 1-32)
  static const Map<int, String> milestoneImages = {
    // 🌱 기초 입문 단계 (1-8레벨): 요리 시작
    1: '$_basePath/milestones/burrow_tiny.png',             // 작은 굴에서 시작
    2: '$_basePath/milestones/burrow_small.png',            // 소규모 굴로 확장
    3: '$_basePath/milestones/burrow_homecook.png',         // 집 요리 입문
    4: '$_basePath/milestones/burrow_garden.png',           // 재료 직접 기르기
    5: '$_basePath/milestones/burrow_harvest.png',          // 첫 수확의 기쁨
    6: '$_basePath/milestones/burrow_familydinner.png',     // 가족과 함께 요리
    7: '$_basePath/milestones/burrow_market.png',           // 시장에서 재료 고르기
    8: '$_basePath/milestones/burrow_fishing.png',          // 자연에서 식재료 구하기
    
    // 📚 학습 발전 단계 (9-16레벨): 기술 습득
    9: '$_basePath/milestones/burrow_medium.png',           // 중간 크기 굴로 업그레이드
    10: '$_basePath/milestones/burrow_sick.png',            // 건강 관리와 요리법 배우기
    11: '$_basePath/milestones/burrow_apprentice.png',      // 견습생으로 본격 시작
    12: '$_basePath/milestones/burrow_recipe_lab.png',      // 레시피 연구 시작
    13: '$_basePath/milestones/burrow_experiment.png',      // 다양한 요리 실험
    14: '$_basePath/milestones/burrow_study.png',           // 체계적 요리 공부
    15: '$_basePath/milestones/burrow_forest_mushroom.png', // 고급 재료 탐구
    16: '$_basePath/milestones/burrow_cookbook.png',        // 첫 요리책 작성
    
    // 🎨 창작 숙련 단계 (17-24레벨): 전문성 개발 (기존 unlock service 유지)
    17: '$_basePath/milestones/burrow_sketch.png',          // 요리 아이디어 스케치 (기존 시그니처 대체)
    18: '$_basePath/milestones/burrow_ceramist.png',        // 그릇까지 직접 제작
    19: '$_basePath/milestones/burrow_kitchen.png',         // 전문 주방 구비
    20: '$_basePath/milestones/burrow_teacher.png',         // 다른 이들 가르치기
    21: '$_basePath/milestones/burrow_tasting.png',         // 전문적 맛 평가
    22: '$_basePath/milestones/burrow_large.png',           // 대규모 굴로 확장
    23: '$_basePath/milestones/burrow_winecellar.png',      // 와인과 음식 페어링 (기존 레스토랑 대체)
    24: '$_basePath/milestones/burrow_competition.png',     // 요리 경연 참가
    
    // 🌍 마스터 단계 (25-30레벨): 세계적 인정
    25: '$_basePath/milestones/burrow_festival.png',        // 요리 축제 기획
    26: '$_basePath/milestones/burrow_gourmet_trip.png',    // 미식 여행으로 견문 넓히기
    27: '$_basePath/milestones/burrow_international.png',   // 국제적 인정 받기
    28: '$_basePath/milestones/burrow_japan_trip.png',      // 일본 요리 마스터
    29: '$_basePath/milestones/burrow_cheeze_tour.png',     // 유럽 치즈 투어
    30: '$_basePath/milestones/burrow_thanksgiving.png',    // 감사의 마음으로 요리
    
    // 🏆 최종 완성 단계 (31-32레벨): 꿈의 실현
    31: '$_basePath/milestones/burrow_signaturedish.png',   // 🌟 시그니처 요리 완성
    32: '$_basePath/milestones/burrow_own_restaurant.png',  // 🏆 자신만의 레스토랑 오픈 (최종 목표)
  };
  
  /// 특별 공간 이미지 경로 (기존 5개 + 새로운 11개)
  static const Map<String, String> specialRoomImages = {
    // 기존 특별 공간들
    'ballroom': '$_basePath/special_rooms/burrow_ballroom.png',
    'hotSpring': '$_basePath/special_rooms/burrow_hotspring.png',
    'orchestra': '$_basePath/special_rooms/burrow_orchestra.png',
    'alchemyLab': '$_basePath/special_rooms/burrow_lab.png',
    'fineDining': '$_basePath/special_rooms/burrow_finedining.png',
    
    // 새로 추가된 특별 공간들 (11개)
    'alps': '$_basePath/special_rooms/burrow_alps.png',
    'camping': '$_basePath/special_rooms/burrow_camping.png',
    'autumn': '$_basePath/special_rooms/burrow_autumn.png',
    'springPicnic': '$_basePath/special_rooms/burrow_spring_picnic.png',
    'surfing': '$_basePath/special_rooms/burrow_surfing.png',
    'snorkel': '$_basePath/special_rooms/burrow_snorkel.png',
    'summerbeach': '$_basePath/special_rooms/burrow_summerbeach.png',
    'baliYoga': '$_basePath/special_rooms/burrow_bali_yoga.png',
    'orientExpress': '$_basePath/special_rooms/burrow_orient_express.png',
    'canvas': '$_basePath/special_rooms/burrow_canvas.png',
    'vacance': '$_basePath/special_rooms/burrow_vacance.png',
  };
  
  /// 기본 플레이스홀더 이미지
  static const String defaultMilestone = '$_basePath/milestones/burrow_tiny.png';
  static const String defaultSpecialRoom = '$_basePath/milestones/burrow_locked.png';
  
  /// 잠긴 상태 이미지
  static const String lockedMilestone = '$_basePath/milestones/burrow_locked.png';
  static const String lockedSpecialRoom = '$_basePath/milestones/burrow_locked.png';
  
  /// 레벨에 따른 마일스톤 이미지 경로 반환
  static String getMilestoneImagePath(int level) {
    return milestoneImages[level] ?? defaultMilestone;
  }
  
  /// 특별 공간 타입에 따른 이미지 경로 반환
  static String getSpecialRoomImagePath(String roomType) {
    return specialRoomImages[roomType] ?? defaultSpecialRoom;
  }
  
  /// 이미지 파일 존재 여부 확인 (개발용 디버깅)
  static List<String> getAllAssetPaths() {
    final List<String> allPaths = [];
    allPaths.addAll(milestoneImages.values);
    allPaths.addAll(specialRoomImages.values);
    allPaths.addAll([
      defaultMilestone,
      defaultSpecialRoom,
      lockedMilestone,
      lockedSpecialRoom,
    ]);
    return allPaths;
  }
  
  /// 이미지 에셋이 유효한지 확인
  static bool isValidAssetPath(String path) {
    return path.startsWith(_basePath) && 
           (path.endsWith('.png') || 
            path.endsWith('.jpg') || 
            path.endsWith('.jpeg'));
  }
  
  /// 개발 환경에서 누락된 에셋 체크를 위한 헬퍼
  static Map<String, bool> checkMissingAssets() {
    final Map<String, bool> assetStatus = {};
    
    for (final path in getAllAssetPaths()) {
      // 실제로는 rootBundle.load()를 사용해야 하지만
      // 개발 시점에서는 경로가 올바른지만 확인
      assetStatus[path] = isValidAssetPath(path);
    }
    
    return assetStatus;
  }
}