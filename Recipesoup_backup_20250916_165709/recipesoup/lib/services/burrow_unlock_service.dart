import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:hive/hive.dart'; // 🔥 ULTRA THINK: 직접 Hive 접근을 위한 import
import '../models/recipe.dart';
import '../models/mood.dart';
import '../models/burrow_milestone.dart';
import '../services/hive_service.dart';
import '../services/burrow_storage_service.dart';

/// 토끼굴 마일스톤 언락 서비스
/// 성장 트랙과 특별 공간의 언락 조건을 체크하고 관리
class BurrowUnlockService {
  final HiveService _hiveService;
  final BurrowStorageService _storageService;
  
  // 중복 방지를 위한 처리된 레시피 IDs 캐시
  final Set<String> _processedRecipeIds = <String>{};
  
  // 언락 큐 (동시 다중 언락 방지)
  final List<UnlockQueueItem> _unlockQueue = [];
  
  // 🔥 CRITICAL FIX: HiveService 싱글톤 강제 전달 (더 이상 별도 인스턴스 생성 방지)
  BurrowUnlockService({
    required HiveService hiveService, // 🔥 CRITICAL: 필수 매개변수로 변경
    BurrowStorageService? storageService,
  }) : _hiveService = hiveService, // 🔥 CRITICAL: 직접 할당
       _storageService = storageService ?? BurrowStorageService();
       
  // 🔥 CRITICAL FIX: 레거시 생성자 (deprecated, 사용 금지)
  @Deprecated('Use BurrowUnlockService(hiveService: HiveService()) instead')
  BurrowUnlockService.legacy({
    HiveService? hiveService,
    BurrowStorageService? storageService,
  }) : _hiveService = hiveService ?? HiveService(),
       _storageService = storageService ?? BurrowStorageService();

  /// HiveService getter for provider access
  HiveService get hiveService => _hiveService;

  /// 초기화 - 기본 마일스톤 생성 및 진행상황 로드
  Future<void> initialize() async {
    try {
      await _storageService.initialize();
      await _createDefaultMilestones();
      await _loadProgressData();
      developer.log('BurrowUnlockService initialized', name: 'BurrowUnlockService');
    } catch (e) {
      developer.log('Failed to initialize BurrowUnlockService: $e', name: 'BurrowUnlockService');
      rethrow;
    }
  }
  
  /// 기본 마일스톤들 생성 (32단계 논리적 성장여정)
  Future<void> _createDefaultMilestones() async {
    final existingMilestones = await _loadMilestones();
    if (existingMilestones.isNotEmpty) return; // 이미 존재하면 생성하지 않음
    
    final milestones = <BurrowMilestone>[
      // ===== 🌱 기초 입문 단계 (1-8레벨): 요리 시작 =====
      BurrowMilestone.growth(
        level: 1,
        requiredRecipes: 1,
        title: '아늑한 토끼굴',
        description: '첫 레시피와 함께 열린 작은 굴, 여정의 시작',
      ),
      BurrowMilestone.growth(
        level: 2,
        requiredRecipes: 3,
        title: '작은 토끼굴',
        description: '점점 커지는 요리에 대한 관심과 열정',
      ),
      BurrowMilestone.growth(
        level: 3,
        requiredRecipes: 5,
        title: '홈쿡 토끼굴',
        description: '집에서 만드는 요리의 즐거움 발견',
      ),
      BurrowMilestone.growth(
        level: 4,
        requiredRecipes: 7,
        title: '정원사 토끼굴',
        description: '재료를 심고 가꾸며 느끼는 자연의 소중함',
      ),
      BurrowMilestone.growth(
        level: 5,
        requiredRecipes: 10,
        title: '수확의 토끼굴',
        description: '첫 수확의 기쁨과 성취감이 가득',
      ),
      BurrowMilestone.growth(
        level: 6,
        requiredRecipes: 12,
        title: '가족식사 토끼굴',
        description: '사랑하는 가족과 함께하는 따뜻한 식탁',
      ),
      BurrowMilestone.growth(
        level: 7,
        requiredRecipes: 15,
        title: '시장탐험 토끼굴',
        description: '다양한 식재료를 찾아 탐험하는 재미',
      ),
      BurrowMilestone.growth(
        level: 8,
        requiredRecipes: 18,
        title: '어부의 토끼굴',
        description: '자연에서 건져올린 싱싱한 식재료',
      ),
      
      // ===== 📚 학습 발전 단계 (9-16레벨): 기술 습득 =====
      BurrowMilestone.growth(
        level: 9,
        requiredRecipes: 21,
        title: '발전하는 토끼굴',
        description: '더 많은 가능성을 품은 토끼굴',
      ),
      BurrowMilestone.growth(
        level: 10,
        requiredRecipes: 25,
        title: '회복의 토끼굴',
        description: '건강 관리와 치유의 요리법 터득',
      ),
      BurrowMilestone.growth(
        level: 11,
        requiredRecipes: 28,
        title: '견습 요리사 토끼굴',
        description: '본격적인 요리의 길로 들어선 견습생',
      ),
      BurrowMilestone.growth(
        level: 12,
        requiredRecipes: 32,
        title: '연구실 토끼굴',
        description: '과학적으로 분석하는 레시피 연구',
      ),
      BurrowMilestone.growth(
        level: 13,
        requiredRecipes: 35,
        title: '실험정신 토끼굴',
        description: '새로운 조합과 실험을 즐기며 도전',
      ),
      BurrowMilestone.growth(
        level: 14,
        requiredRecipes: 39,
        title: '서재 토끼굴',
        description: '넓고 깊은 요리 지식이 쌓인 보물 창고',
      ),
      BurrowMilestone.growth(
        level: 15,
        requiredRecipes: 42,
        title: '버섯채집가 토끼굴',
        description: '고급 재료와 특별한 식재료 탐구',
      ),
      BurrowMilestone.growth(
        level: 16,
        requiredRecipes: 46,
        title: '요리책 저자 토끼굴',
        description: '첫 번째 요리책을 완성한 작가',
      ),
      
      // ===== 🎨 창작 숙련 단계 (17-24레벨): 전문성 개발 =====
      BurrowMilestone.growth(
        level: 17,
        requiredRecipes: 50,
        title: '스케치 토끼굴',
        description: '요리 재료를 관찰하며 그리는 화실 모임',
      ),
      BurrowMilestone.growth(
        level: 18,
        requiredRecipes: 54,
        title: '장인정신 토끼굴',
        description: '요리를 담아낼 그릇까지 직접 빚는 공방',
      ),
      BurrowMilestone.growth(
        level: 19,
        requiredRecipes: 58,
        title: '전문주방 토끼굴',
        description: '프로페셔널한 장비가 갖춰진 전문 주방',
      ),
      BurrowMilestone.growth(
        level: 20,
        requiredRecipes: 62,
        title: '요리선생 토끼굴',
        description: '요리의 기본기를 가르치는 멘토링 시간',
      ),
      BurrowMilestone.growth(
        level: 21,
        requiredRecipes: 66,
        title: '미쉐린 토끼굴',
        description: '뛰어난 레스토랑을 방문하는 미식 탐험가',
      ),
      BurrowMilestone.growth(
        level: 22,
        requiredRecipes: 70,
        title: '대규모 토끼굴',
        description: '넓게 확장된 웅장한 규모의 토끼굴',
      ),
      BurrowMilestone.growth(
        level: 23,
        requiredRecipes: 74,
        title: '소믈리에 토끼굴',
        description: '요리와 완벽한 마리아쥬를 이루는 와인 셀렉션',
      ),
      BurrowMilestone.growth(
        level: 24,
        requiredRecipes: 78,
        title: '요리경연 토끼굴',
        description: '치열한 요리 경연에서 실력을 겨루는 콘테스트',
      ),
      
      // ===== 🌍 마스터 단계 (25-30레벨): 세계적 인정 =====
      BurrowMilestone.growth(
        level: 25,
        requiredRecipes: 82,
        title: '요리축제 토끼굴',
        description: '마을 사람들과 어우러져 요리를 즐기는 축제',
      ),
      BurrowMilestone.growth(
        level: 26,
        requiredRecipes: 86,
        title: '미식여행 토끼굴',
        description: '세계 각지의 미식 여행으로 넓어지는 견문',
      ),
      BurrowMilestone.growth(
        level: 27,
        requiredRecipes: 90,
        title: '세계적 요리사 토끼굴',
        description: '국제적 명성의 셰프들과 협업하는 주방',
      ),
      BurrowMilestone.growth(
        level: 28,
        requiredRecipes: 94,
        title: '티 소믈리에 토끼굴',
        description: '일본 전통 차문화의 정수를 배우는 토끼굴',
      ),
      BurrowMilestone.growth(
        level: 29,
        requiredRecipes: 98,
        title: '치즈투어 토끼굴',
        description: '전통 있는 이탈리아 치즈 공장 견학',
      ),
      BurrowMilestone.growth(
        level: 30,
        requiredRecipes: 102,
        title: '감사의 토끼굴',
        description: '다같이 둘러앉아 행복이 가득한 식탁',
      ),
      
      // ===== 🏆 최종 완성 단계 (31-32레벨): 꿈의 실현 =====
      BurrowMilestone.growth(
        level: 31,
        requiredRecipes: 106,
        title: '시그니처 요리 토끼굴',
        description: '나만의 시그니처 요리가 탄생한 순간',
      ),
      BurrowMilestone.growth(
        level: 32,
        requiredRecipes: 110,
        title: '꿈의 레스토랑 토끼굴',
        description: '꿈에 그리던 작고 따스한 레스토랑을 연 토끼',
      ),
      
      // ===== 특별 공간들 (숨겨진 조건 기반) - 기존 5개 + 새로운 11개 =====
      BurrowMilestone.special(
        room: SpecialRoom.ballroom,
        title: '무도회장',
        description: '다른 이를 위하는 마음이 열어준 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.hotSpring,
        title: '온천탕',
        description: '지친 마음을 달래는 위로의 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.orchestra,
        title: '음악회장',
        description: '다양한 감정의 하모니가 만든 아름다운 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.alchemyLab,
        title: '연금술실',
        description: '실패를 성공으로 바꾼 도전정신의 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.fineDining,
        title: '파인다이닝',
        description: '완벽을 추구하는 열정이 만든 고급스러운 공간',
      ),
      
      // 새로 추가된 11개 특별 공간들
      BurrowMilestone.special(
        room: SpecialRoom.alps,
        title: '알프스 별장',
        description: '극한의 도전을 통해 발견한 고산의 숨겨진 별장',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.camping,
        title: '자연 캠핑장',
        description: '자연의 재료로만 요리하는 야생 요리사의 성지',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.autumn,
        title: '가을 정원',
        description: '계절의 감성을 담은 가을 정원의 비밀 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.springPicnic,
        title: '봄날의 피크닉',
        description: '야외 요리를 사랑하는 피크닉 마스터의 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.surfing,
        title: '서핑 비치',
        description: '바다의 에너지를 요리에 담는 서퍼의 해변',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.snorkel,
        title: '스노클링 만',
        description: '바다 탐험을 통해 찾은 신선한 해산물의 보고',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.summerbeach,
        title: '여름 해변',
        description: '휴양지의 여유로운 분위기가 넘치는 해변 요리 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.baliYoga,
        title: '발리 요가 센터',
        description: '명상과 건강한 요리가 만나는 평화로운 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.orientExpress,
        title: '오리엔트 특급열차',
        description: '여행의 추억과 이국적 요리가 어우러진 낭만의 공간',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.canvas,
        title: '예술가의 아틀리에',
        description: '창작의 영감이 요리로 피어나는 예술가의 작업실',
      ),
      BurrowMilestone.special(
        room: SpecialRoom.vacance,
        title: '바캉스 빌라',
        description: '완전한 휴식과 여유로운 요리가 만나는 휴양 공간',
      ),
    ];
    
    // Storage Service에 저장
    await _storageService.saveMilestones(milestones);
    developer.log('Created ${milestones.length} default milestones with 32-level growth journey', name: 'BurrowUnlockService');
  }
  
  /// 진행상황 데이터 로드
  Future<void> _loadProgressData() async {
    try {
      final progressList = await _loadProgress();
      
      // 처리된 레시피 ID들을 캐시에 로드
      for (final progress in progressList) {
        _processedRecipeIds.addAll(progress.processedRecipeIds);
      }
      
      developer.log('Loaded ${_processedRecipeIds.length} processed recipe IDs', name: 'BurrowUnlockService');
    } catch (e) {
      developer.log('Failed to load progress data: $e', name: 'BurrowUnlockService');
    }
  }
  
  /// 새 레시피에 대한 마일스톤 체크 (메인 엔트리포인트)
  Future<List<BurrowMilestone>> checkUnlocksForRecipe(Recipe recipe) async {
    // 이미 처리된 레시피는 스킵 (중복 처리 방지)
    if (_processedRecipeIds.contains(recipe.id)) {
      developer.log('Recipe ${recipe.id} already processed, skipping unlock check', name: 'BurrowUnlockService');
      return [];
    }
    
    final newUnlocks = <BurrowMilestone>[];
    
    // 🔥 ULTRA THINK FIX: 성장 트랙과 특별한 공간을 독립적으로 체크
    
    // 성장 트랙 체크 (독립적 try-catch)
    try {
      debugPrint('🚨 STEP 1A: Checking growth track...');
      final growthUnlocks = await _checkGrowthTrack();
      newUnlocks.addAll(growthUnlocks);
      debugPrint('🚨 STEP 1B: Growth track found ${growthUnlocks.length} unlocks');
    } catch (e) {
      debugPrint('🚨 WARNING: Growth track check failed: $e');
      developer.log('Growth track check failed: $e', name: 'BurrowUnlockService');
      // 성장 트랙 실패해도 특별한 공간은 계속 체크
    }
    
    // 특별 공간 체크 (독립적 try-catch) 
    try {
      debugPrint('🚨 STEP 2A: Checking special rooms...');
      final specialUnlocks = await _checkSpecialRooms(recipe);
      newUnlocks.addAll(specialUnlocks);
      debugPrint('🚨 STEP 2B: Special rooms found ${specialUnlocks.length} unlocks');
    } catch (e) {
      debugPrint('🚨 WARNING: Special rooms check failed: $e');
      developer.log('Special rooms check failed: $e', name: 'BurrowUnlockService');
      // 특별한 공간 실패해도 처리 계속
    }
    
    try {
      // 처리된 레시피 마킹
      _processedRecipeIds.add(recipe.id);
      
      // 언락된 마일스톤들을 큐에 추가
      if (newUnlocks.isNotEmpty) {
        debugPrint('🚨🚨🚨 CRITICAL UNLOCK PROCESS: About to unlock ${newUnlocks.length} milestones');
        
        for (final milestone in newUnlocks) {
          debugPrint('🚨 BEFORE UNLOCK: L${milestone.level} isUnlocked = ${milestone.isUnlocked}');
          
          _unlockQueue.add(UnlockQueueItem(
            milestone: milestone,
            unlockedAt: DateTime.now(),
            triggerRecipeId: recipe.id,
          ));
          
          milestone.unlock();
          debugPrint('🚨 AFTER UNLOCK: L${milestone.level} isUnlocked = ${milestone.isUnlocked}');
        }
        
        debugPrint('🚨🚨🚨 CRITICAL: About to save ${newUnlocks.length} milestones to storage');
        
        // 🔥 CRITICAL FIX: 모든 마일스톤을 다시 로드하고, 언락된 것들을 업데이트
        final allMilestones = await _loadMilestones();
        
        // 언락된 마일스톤들을 찾아서 unlock 상태 적용
        for (final unlockedMilestone in newUnlocks) {
          final storageIndex = allMilestones.indexWhere((m) => m.id == unlockedMilestone.id);
          if (storageIndex != -1) {
            debugPrint('🚨 APPLYING UNLOCK to storage milestone L${allMilestones[storageIndex].level}');
            allMilestones[storageIndex].unlock();
            debugPrint('🚨 Storage milestone L${allMilestones[storageIndex].level} now unlocked: ${allMilestones[storageIndex].isUnlocked}');
          }
        }
        
        await _updateMilestones(allMilestones);
        
        debugPrint('🚨🚨🚨 CRITICAL: Milestone save completed - checking if persisted');
        final checkMilestones = await _loadMilestones();
        final checkGrowth = checkMilestones.where((m) => m.isGrowthTrack).toList();
        for (final milestone in checkGrowth) {
          debugPrint('🚨 VERIFICATION: L${milestone.level} isUnlocked = ${milestone.isUnlocked}');
        }
        
        developer.log('Unlocked ${newUnlocks.length} milestones for recipe ${recipe.id}', name: 'BurrowUnlockService');
      } else {
        debugPrint('🚨 STEP 3: No new unlocks found for recipe ${recipe.id}');
      }
      
    } catch (e) {
      debugPrint('🚨 ERROR: Failed to save unlocks for recipe ${recipe.id}: $e');
      developer.log('Failed to save unlocks for recipe ${recipe.id}: $e', name: 'BurrowUnlockService');
      // 에러 발생시 처리된 레시피에서 제거 (재시도 가능하도록)
      _processedRecipeIds.remove(recipe.id);
    }
    
    debugPrint('🚨 FINAL: checkUnlocksForRecipe returning ${newUnlocks.length} unlocks');
    return newUnlocks;
  }


  /// 특별 공간 조건 체크
  Future<List<BurrowMilestone>> _checkSpecialRooms(Recipe triggerRecipe) async {
    final milestones = await _loadMilestones();
    final specialMilestones = milestones.where((m) => m.isSpecialRoom && !m.isUnlocked).toList();

    final newUnlocks = <BurrowMilestone>[];

    for (final milestone in specialMilestones) {
      if (milestone.specialRoom != null) {
        final shouldUnlock = await _checkSpecialRoomCondition(milestone.specialRoom!, triggerRecipe);
        if (shouldUnlock) {
          newUnlocks.add(milestone);
        }
      }
    }

    return newUnlocks;
  }

  
  /// 성장 트랙 마일스톤 체크
  Future<List<BurrowMilestone>> _checkGrowthTrack() async {
    debugPrint('🚨🚨🚨 CRITICAL: _checkGrowthTrack STARTED');
    
    // 🔥 CRITICAL DEBUG: HiveService 인스턴스 정보 로깅
    debugPrint('🔥 DEBUG: BurrowUnlockService HiveService instance: ${_hiveService.hashCode}');
    
    // 🔥 CRITICAL FIX: 더 긴 지연 (박스 동기화 보장)
    debugPrint('🔥 DEBUG: Waiting for box synchronization...');
    await Future.delayed(Duration(milliseconds: 300)); // 증가된 대기 시간
    
    // 🔥 CRITICAL FIX: 변수 선언을 스코프 밖으로 이동
    List<Recipe> allRecipes = [];
    int recipeCount = 0;
    
    try {
      // 🔥 CRITICAL DEBUG: 단계별 디버그
      debugPrint('🔥 DEBUG: About to call _hiveService.getAllRecipes()...');
      
      allRecipes = await _hiveService.getAllRecipes();
      recipeCount = allRecipes.length;
      
      debugPrint('🚨🚨🚨 CRITICAL RESULT: HiveService returned $recipeCount recipes');
      debugPrint('🔥 DEBUG: Recipe list type: ${allRecipes.runtimeType}');
      debugPrint('🔥 DEBUG: Is list empty: ${allRecipes.isEmpty}');
      
      // 🔥 ULTRA THINK: HiveService를 완전히 우회하여 직접 Hive.box() 접근
      debugPrint('🔥 ULTRA DEBUG: Bypassing HiveService, accessing Hive.box directly...');
      try {
        final directBox = Hive.box<Map<String, dynamic>>('recipes');
        debugPrint('🔥 DIRECT ACCESS: Direct box hashCode: ${directBox.hashCode}');
        debugPrint('🔥 DIRECT ACCESS: Direct box isOpen: ${directBox.isOpen}');
        debugPrint('🔥 DIRECT ACCESS: Direct box length: ${directBox.length}');
        debugPrint('🔥 DIRECT ACCESS: Direct box keys: ${directBox.keys.toList()}');
        
        if (directBox.length > 0) {
          debugPrint('🔥 DIRECT ACCESS: SUCCESS! Found ${directBox.length} recipes in direct box');
          // 직접 Box에서 레시피 읽기
          final directRecipes = directBox.values
              .map((jsonData) => Recipe.fromJson(jsonData))
              .toList();
          debugPrint('🔥 DIRECT ACCESS: Successfully parsed ${directRecipes.length} recipes');
          
          // 🔥 ULTRA CRITICAL: 직접 접근에서 데이터가 있다면, HiveService 문제 확실!
          allRecipes = directRecipes;
          recipeCount = directRecipes.length;
          debugPrint('🔥 CRITICAL FIX: Using direct box data - $recipeCount recipes found!');
        } else {
          debugPrint('🔥 DIRECT ACCESS: Direct box also empty - data truly not saved');
        }
      } catch (directError) {
        debugPrint('🔥 DIRECT ACCESS ERROR: $directError');
      }
      
      if (recipeCount > 0) {
        debugPrint('🔥 SUCCESS: Found recipes in BurrowUnlockService!');
        for (int i = 0; i < allRecipes.length && i < 3; i++) {
          debugPrint('🚨 Recipe $i: "${allRecipes[i].title}" (ID: ${allRecipes[i].id})');
        }
        if (recipeCount > 3) {
          debugPrint('🚨 ... and ${recipeCount - 3} more recipes');
        }
      } else {
        debugPrint('🚨🚨🚨 CRITICAL ERROR: NO RECIPES FOUND IN BURROW SERVICE!');
        debugPrint('🔥 DEBUG: This indicates the HiveService instances are not synchronized');
        
        // 🔥 CRITICAL DEBUG: 재시도 메커니즘
        for (int retry = 1; retry <= 3; retry++) {
          debugPrint('🔥 RETRY $retry: Attempting to read recipes again...');
          await Future.delayed(Duration(milliseconds: 500 * retry));
          
          final retryRecipes = await _hiveService.getAllRecipes();
          if (retryRecipes.isNotEmpty) {
            debugPrint('🔥 SUCCESS on retry $retry: Found ${retryRecipes.length} recipes');
            return await _checkGrowthTrack(); // 재귀 호출
          } else {
            debugPrint('🔥 RETRY $retry FAILED: Still 0 recipes');
          }
        }
      }
      
      developer.log('🔥 UNLOCK DEBUG: Total recipes in Hive: $recipeCount', name: 'BurrowUnlockService');
      
    } catch (e) {
      debugPrint('🚨 ERROR in _checkGrowthTrack getAllRecipes: $e');
      developer.log('ERROR in getAllRecipes: $e', name: 'BurrowUnlockService');
      return [];
    }
    
    final milestones = await _loadMilestones();
    final growthMilestones = milestones.where((m) => m.isGrowthTrack).toList();
    
    debugPrint('🚨🚨🚨 CRITICAL: Found ${growthMilestones.length} growth milestones');
    
    developer.log('🔥 UNLOCK DEBUG: Growth milestones loaded: ${growthMilestones.length}', name: 'BurrowUnlockService');
    
    final newUnlocks = <BurrowMilestone>[];
    
    for (final milestone in growthMilestones) {
      developer.log('🔥 UNLOCK DEBUG: Checking milestone L${milestone.level}: unlocked=${milestone.isUnlocked}, needs=${milestone.requiredRecipes}, current=$recipeCount', name: 'BurrowUnlockService');
      
      if (!milestone.isUnlocked && milestone.requiredRecipes != null) {
        if (recipeCount >= milestone.requiredRecipes!) {
          developer.log('🔥 UNLOCK DEBUG: ✅ UNLOCKING milestone L${milestone.level}!', name: 'BurrowUnlockService');
          newUnlocks.add(milestone);
        } else {
          developer.log('🔥 UNLOCK DEBUG: ❌ Not enough recipes for L$milestone.level ($recipeCount/$milestone.requiredRecipes)', name: 'BurrowUnlockService');
        }
      } else {
        developer.log('🔥 UNLOCK DEBUG: ⏭️  Skipping L${milestone.level} (already unlocked or no recipe requirement)', name: 'BurrowUnlockService');
      }
    }
    
    developer.log('🔥 UNLOCK DEBUG: Found ${newUnlocks.length} new growth unlocks', name: 'BurrowUnlockService');
    return newUnlocks;
  }
  
  
  /// 개별 특별 공간 언락 조건 체크
  Future<bool> _checkSpecialRoomCondition(SpecialRoom room, Recipe triggerRecipe) async {
    switch (room) {
      // 기존 특별 공간들
      case SpecialRoom.ballroom:
        return await _checkBallroomCondition(triggerRecipe);
      case SpecialRoom.hotSpring:
        return await _checkHotSpringCondition(triggerRecipe);
      case SpecialRoom.orchestra:
        return await _checkOrchestraCondition(triggerRecipe);
      case SpecialRoom.alchemyLab:
        return await _checkAlchemyLabCondition(triggerRecipe);
      case SpecialRoom.fineDining:
        return await _checkFineDiningCondition(triggerRecipe);
        
      // 새로운 11개 특별 공간들
      case SpecialRoom.alps:
        return await _checkAlpsCondition(triggerRecipe);
      case SpecialRoom.camping:
        return await _checkCampingCondition(triggerRecipe);
      case SpecialRoom.autumn:
        return await _checkAutumnCondition(triggerRecipe);
      case SpecialRoom.springPicnic:
        return await _checkSpringPicnicCondition(triggerRecipe);
      case SpecialRoom.surfing:
        return await _checkSurfingCondition(triggerRecipe);
      case SpecialRoom.snorkel:
        return await _checkSnorkelCondition(triggerRecipe);
      case SpecialRoom.summerbeach:
        return await _checkSummerbeachCondition(triggerRecipe);
      case SpecialRoom.baliYoga:
        return await _checkBaliYogaCondition(triggerRecipe);
      case SpecialRoom.orientExpress:
        return await _checkOrientExpressCondition(triggerRecipe);
      case SpecialRoom.canvas:
        return await _checkCanvasCondition(triggerRecipe);
      case SpecialRoom.vacance:
        return await _checkVacanceCondition(triggerRecipe);
    }
  }
  
  /// 무도회장 조건: 사교적 요리사 (3개 레시피에서 3명 이상 언급)
  Future<bool> _checkBallroomCondition(Recipe triggerRecipe) async {
    final progress = await _getOrCreateProgress(SpecialRoom.ballroom, 3);
    
    // 이미 처리된 레시피면 스킵
    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }
    
    // 감정 스토리에서 사람 언급 체크
    final mentionedPeople = _extractMentionedPeople(triggerRecipe.emotionalStory);
    
    if (mentionedPeople.isNotEmpty) {
      // 새로 언급된 사람들을 메타데이터에 추가
      final existingPeople = Set<String>.from(progress.getMetadata<List>('mentionedPeople') ?? []);
      existingPeople.addAll(mentionedPeople);
      progress.setMetadata('mentionedPeople', existingPeople.toList());
      
      // 레시피 처리 마킹 및 카운트 증가
      if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
        progress.incrementCount();
        
        developer.log('Ballroom progress: ${progress.currentCount}/3, people: ${existingPeople.length}',
                     name: 'BurrowUnlockService');
        
        await _saveProgress([progress]);
        
        // 조건 확인: 3개 레시피 + 3명 이상 언급
        return progress.isCompleted && existingPeople.length >= 3;
      }
    }
    
    return false;
  }
  
  /// 감정 스토리에서 사람 언급 추출
  Set<String> _extractMentionedPeople(String emotionalStory) {
    final people = <String>{};
    final story = emotionalStory.toLowerCase();
    
    // 한국어 관계 키워드들
    const relationKeywords = [
      '엄마', '아빠', '부모님', '어머니', '아버지',
      '가족', '형', '누나', '언니', '동생', '오빠',
      '친구', '동료', '선배', '후배', '동기',
      '남자친구', '여자친구', '연인', '애인', '남편', '아내',
      '할머니', '할아버지', '이모', '삼촌', '고모', '외삼촌',
      '아이', '딸', '아들', '손자', '손녀',
      '선생님', '교수님', '사장님', '팀장님',
      '이웃', '룸메이트', '반려동물'
    ];
    
    for (final keyword in relationKeywords) {
      if (story.contains(keyword)) {
        people.add(keyword);
      }
    }
    
    return people;
  }
  
  /// 온천탕 조건: 힐링 요리사 (sad/tired/nostalgic 각 1개씩)
  Future<bool> _checkHotSpringCondition(Recipe triggerRecipe) async {
    if (![Mood.sad, Mood.tired, Mood.nostalgic].contains(triggerRecipe.mood)) {
      return false; // 힐링 감정이 아니면 체크하지 않음
    }

    final progress = await _getOrCreateProgress(SpecialRoom.hotSpring, 3); // 총 3개 (각 1개씩)

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    // 감정별 카운트 추적
    final moodCounts = Map<String, int>.from(progress.getMetadata<Map>('moodCounts') ?? {});
    final moodKey = triggerRecipe.mood.name;

    if ((moodCounts[moodKey] ?? 0) < 1) {
      moodCounts[moodKey] = (moodCounts[moodKey] ?? 0) + 1;
      progress.setMetadata('moodCounts', moodCounts);

      if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
        progress.incrementCount();

        developer.log('HotSpring progress: $moodCounts', name: 'BurrowUnlockService');

        await _saveProgress([progress]);

        // 조건 확인: sad, tired, nostalgic 각각 1개 이상
        return (moodCounts['sad'] ?? 0) >= 1 &&
               (moodCounts['tired'] ?? 0) >= 1 &&
               (moodCounts['nostalgic'] ?? 0) >= 1;
      }
    }

    return false;
  }
  
  /// 음악회장 조건: 감정 마에스트로 (8가지 감정 모두 완성)
  Future<bool> _checkOrchestraCondition(Recipe triggerRecipe) async {
    
    final progress = await _getOrCreateProgress(SpecialRoom.orchestra, 8); // 8가지 감정
    
    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }
    
    // 감정별 달성 여부 추적
    final achievedMoods = Set<String>.from(progress.getMetadata<List>('achievedMoods') ?? []);
    final moodKey = triggerRecipe.mood.name;
    
    if (!achievedMoods.contains(moodKey)) {
      achievedMoods.add(moodKey);
      progress.setMetadata('achievedMoods', achievedMoods.toList());
      
      if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
        progress.currentCount = achievedMoods.length; // 직접 설정
        
        developer.log('Orchestra progress: ${achievedMoods.length}/8 moods', name: 'BurrowUnlockService');
        
        await _saveProgress([progress]);
        
        // 조건 확인: 8가지 감정 모두 달성 (평점 조건 제거)
        return achievedMoods.length >= 8;
      }
    }
    
    return false;
  }
  
  /// 연금술실 조건: 도전적 요리사 (실패→성공 3회)
  Future<bool> _checkAlchemyLabCondition(Recipe triggerRecipe) async {
    final progress = await _getOrCreateProgress(SpecialRoom.alchemyLab, 3);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    // 🔥 ULTRA THINK FIX: HiveService 파싱 에러로부터 보호
    try {
      debugPrint('🚨 AlchemyLab: Attempting to get all recipes...');

      // 동일한 제목의 이전 레시피들 찾기
      final allRecipes = await _hiveService.getAllRecipes();
      debugPrint('🚨 AlchemyLab: Successfully got ${allRecipes.length} recipes');

      final sameTitle = triggerRecipe.title.toLowerCase().trim();

      // 🔧 IMPROVED: 더 관대한 제목 매칭 (공백 및 특수문자 정규화)
      final normalizedTitle = sameTitle.replaceAll(RegExp(r'[^\w가-힣]'), '');

      final relatedRecipes = allRecipes.where((r) {
        final otherTitle = r.title.toLowerCase().trim().replaceAll(RegExp(r'[^\w가-힣]'), '');
        return otherTitle == normalizedTitle &&
               r.id != triggerRecipe.id &&
               r.rating != null;
      }).toList();

      debugPrint('🚨 AlchemyLab: Found ${relatedRecipes.length} related recipes for "$sameTitle"');

      if (relatedRecipes.isNotEmpty) {
        // 이전 평점 중 2점 이하가 있고, 현재 평점이 4점 이상인지 체크
        final hasFailure = relatedRecipes.any((r) => r.rating! <= 2);
        final currentSuccess = triggerRecipe.rating != null && triggerRecipe.rating! >= 4;

        debugPrint('🚨 AlchemyLab: hasFailure=$hasFailure, currentSuccess=$currentSuccess');

        if (hasFailure && currentSuccess) {
          if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
            progress.incrementCount();

            developer.log('AlchemyLab progress: ${progress.currentCount}/3 improvements', name: 'BurrowUnlockService');

            await _saveProgress([progress]);

            return progress.isCompleted;
          }
        }
      }

    } catch (e) {
      // 🔥 ULTRA THINK: HiveService 에러 시에도 연금술실이 완전히 차단되지 않도록
      debugPrint('🚨 CRITICAL: AlchemyLab HiveService error: $e');
      developer.log('AlchemyLab HiveService failed, but continuing: $e', name: 'BurrowUnlockService');

      // 🔧 FALLBACK: HiveService 실패 시 단순 조건으로 대체
      // 현재 레시피가 평점 4+ 이면 개선 시도로 간주
      if (triggerRecipe.rating != null && triggerRecipe.rating! >= 4) {
        if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
          progress.incrementCount();

          developer.log('AlchemyLab progress (fallback): ${progress.currentCount}/3', name: 'BurrowUnlockService');

          await _saveProgress([progress]);

          return progress.isCompleted;
        }
      }
    }

    return false;
  }
  
  /// 파인다이닝 조건: 완벽주의자 (평점 5점 레시피 5개)
  Future<bool> _checkFineDiningCondition(Recipe triggerRecipe) async {
    if (triggerRecipe.rating != 5) {
      return false; // 5점이 아니면 체크하지 않음
    }

    final progress = await _getOrCreateProgress(SpecialRoom.fineDining, 5);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('FineDining progress: ${progress.currentCount}/5 perfect recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 진행상황 가져오기 또는 생성
  Future<UnlockProgress> _getOrCreateProgress(SpecialRoom room, int requiredCount) async {
    final progressList = await _loadProgress();
    final existing = progressList.firstWhere(
      (p) => p.roomType == room,
      orElse: () => UnlockProgress(roomType: room, requiredCount: requiredCount),
    );
    
    return existing;
  }
  
  /// 언락 큐에서 다음 아이템 가져오기 (순차 처리용)
  UnlockQueueItem? popUnlockQueue() {
    if (_unlockQueue.isEmpty) return null;
    return _unlockQueue.removeAt(0);
  }
  
  /// 언락 큐 크기 
  int get unlockQueueSize => _unlockQueue.length;
  
  /// 모든 마일스톤 가져오기
  Future<List<BurrowMilestone>> getAllMilestones() async {
    return await _loadMilestones();
  }
  
  /// 성장 트랙 마일스톤들 가져오기
  Future<List<BurrowMilestone>> getGrowthMilestones() async {
    final milestones = await _loadMilestones();
    return milestones.where((m) => m.isGrowthTrack).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
  }
  
  /// 특별 공간 마일스톤들 가져오기
  Future<List<BurrowMilestone>> getSpecialMilestones() async {
    final milestones = await _loadMilestones();
    return milestones.where((m) => m.isSpecialRoom).toList();
  }
  
  /// 현재 진행상황들 가져오기 (디버그용)
  Future<List<UnlockProgress>> getCurrentProgress() async {
    return await _loadProgress();
  }
  
  // === 새로운 11개 특별 공간 조건 체크 메서드들 ===
  
  /// 알프스 별장 조건: 극한 도전자 (재료 5개 이상 + 평점 4+ 레시피 3개)
  Future<bool> _checkAlpsCondition(Recipe triggerRecipe) async {
    // 재료 5개 미만이거나 평점 4 미만이면 체크하지 않음
    if (triggerRecipe.ingredients.length < 5 ||
        triggerRecipe.rating == null || triggerRecipe.rating! < 4) {
      return false;
    }

    final progress = await _getOrCreateProgress(SpecialRoom.alps, 3);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('Alps progress: ${progress.currentCount}/3 extreme recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 캠핑장 조건: 자연 애호가 (자연 키워드 4개 레시피)
  Future<bool> _checkCampingCondition(Recipe triggerRecipe) async {
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const natureKeywords = [
      '자연', '야외', '캠핑', '숲', '산', '강', '바다', '하늘',
      '바람', '공기', '햇살', '나무', '풀', '꽃', '새', '별'
    ];

    // 자연 키워드가 포함되지 않으면 체크하지 않음
    final hasNatureKeyword = natureKeywords.any((keyword) => story.contains(keyword));
    if (!hasNatureKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.camping, 4);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('Camping progress: ${progress.currentCount}/4 nature recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 가을 정원 조건: 가을 감성가 (가을 키워드 4개 레시피)
  Future<bool> _checkAutumnCondition(Recipe triggerRecipe) async {
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const autumnKeywords = [
      '가을', '단풍', '추위', '쌀쌀', '고구마', '밤', '감', '코스모스',
      '낙엽', '억새', '국화', '단감', '배', '도토리', '은행'
    ];

    // 가을 키워드가 포함되지 않으면 체크하지 않음
    final hasAutumnKeyword = autumnKeywords.any((keyword) => story.contains(keyword));
    if (!hasAutumnKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.autumn, 4);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('Autumn progress: ${progress.currentCount}/4 autumn recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 봄날의 피크닉 조건: 외출 요리사 (외출 키워드 4개 레시피)
  Future<bool> _checkSpringPicnicCondition(Recipe triggerRecipe) async {
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const outdoorKeywords = [
      '나들이', '외출', '여행', '산책', '공원', '피크닉', '소풍',
      '드라이브', '나가서', '밖에서', '야외에서', '외식'
    ];

    final hasOutdoorKeyword = outdoorKeywords.any((keyword) => story.contains(keyword));
    if (!hasOutdoorKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.springPicnic, 4);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('SpringPicnic progress: ${progress.currentCount}/4 outdoor recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 서핑 비치 조건: 해변 요리사 (해변 키워드 + excited 감정 4개)
  Future<bool> _checkSurfingCondition(Recipe triggerRecipe) async {
    // excited 감정이 아니면 체크하지 않음
    if (triggerRecipe.mood != Mood.excited) return false;
    
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const beachKeywords = ['바다', '해변', '파도', '서핑', '바닷바람', '해수욕'];
    
    final hasBeachKeyword = beachKeywords.any((keyword) => story.contains(keyword));
    if (!hasBeachKeyword) return false;
    
    final progress = await _getOrCreateProgress(SpecialRoom.surfing, 4);
    
    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }
    
    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();
      
      developer.log('Surfing progress: ${progress.currentCount}/4 excited beach recipes', name: 'BurrowUnlockService');
      
      await _saveProgress([progress]);
      
      return progress.isCompleted;
    }
    
    return false;
  }
  
  /// 스노클링 만 조건: 바다 탐험가 (해산물 재료 4개 레시피)
  Future<bool> _checkSnorkelCondition(Recipe triggerRecipe) async {
    // 해산물 재료 체크
    const seafoodKeywords = ['생선', '새우', '게', '조개', '굴', '전복', '오징어', '문어', '연어', '고등어'];
    final hasSeafood = triggerRecipe.ingredients.any((ingredient) =>
        seafoodKeywords.any((keyword) => ingredient.name.toLowerCase().contains(keyword))
    );

    if (!hasSeafood) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.snorkel, 4);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('Snorkel progress: ${progress.currentCount}/4 seafood recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 여름 해변 조건: 휴양지 요리사 (comfortable 감정 + 휴식 키워드 4개 레시피)
  Future<bool> _checkSummerbeachCondition(Recipe triggerRecipe) async {
    // comfortable 감정이 아니면 체크하지 않음
    if (triggerRecipe.mood != Mood.comfortable) return false;

    final story = triggerRecipe.emotionalStory.toLowerCase();
    const relaxKeywords = ['휴식', '쉬는', '여유', '편안', '느긋', '휴가', '바캉스'];

    final hasRelaxKeyword = relaxKeywords.any((keyword) => story.contains(keyword));
    if (!hasRelaxKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.summerbeach, 4);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('Summerbeach progress: ${progress.currentCount}/4 comfortable rest recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 발리 요가 조건: 명상 요리사 (peaceful 감정 + 건강 키워드 3개 레시피)
  Future<bool> _checkBaliYogaCondition(Recipe triggerRecipe) async {
    // peaceful 감정이 아니면 체크하지 않음
    if (triggerRecipe.mood != Mood.peaceful) return false;

    final story = triggerRecipe.emotionalStory.toLowerCase();
    const healthKeywords = ['건강', '웰빙', '요가', '명상', '마음', '몸', '균형'];

    final hasHealthKeyword = healthKeywords.any((keyword) => story.contains(keyword));
    if (!hasHealthKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.baliYoga, 3);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('BaliYoga progress: ${progress.currentCount}/3 peaceful health recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 오리엔트 특급열차 조건: 여행 요리사 (여행 키워드 3개 레시피)
  Future<bool> _checkOrientExpressCondition(Recipe triggerRecipe) async {
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const travelKeywords = ['여행', '외국', '해외', '국가', '나라', '문화', '전통'];

    final hasTravelKeyword = travelKeywords.any((keyword) => story.contains(keyword));
    if (!hasTravelKeyword) return false;

    final progress = await _getOrCreateProgress(SpecialRoom.orientExpress, 3);

    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }

    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();

      developer.log('OrientExpress progress: ${progress.currentCount}/3 travel recipes', name: 'BurrowUnlockService');

      await _saveProgress([progress]);

      return progress.isCompleted;
    }

    return false;
  }
  
  /// 예술가의 아틀리에 조건: 예술가 요리사 (창작 키워드 + 평점 4+ 5개)
  Future<bool> _checkCanvasCondition(Recipe triggerRecipe) async {
    // 평점 4 미만이면 체크하지 않음
    if (triggerRecipe.rating == null || triggerRecipe.rating! < 4) {
      return false;
    }
    
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const artKeywords = ['예술', '창작', '아름다운', '색깔', '모양', '디자인', '작품'];
    
    final hasArtKeyword = artKeywords.any((keyword) => story.contains(keyword));
    if (!hasArtKeyword) return false;
    
    final progress = await _getOrCreateProgress(SpecialRoom.canvas, 5);
    
    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }
    
    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();
      
      developer.log('Canvas progress: ${progress.currentCount}/5 artistic recipes', name: 'BurrowUnlockService');
      
      await _saveProgress([progress]);
      
      return progress.isCompleted;
    }
    
    return false;
  }
  
  /// 바캉스 빌라 조건: 휴식 요리사 (grateful 감정 + 휴양 키워드 4개)
  Future<bool> _checkVacanceCondition(Recipe triggerRecipe) async {
    // grateful 감정이 아니면 체크하지 않음
    if (triggerRecipe.mood != Mood.grateful) return false;
    
    final story = triggerRecipe.emotionalStory.toLowerCase();
    const vacationKeywords = ['휴가', '바캉스', '리조트', '호텔', '여유', '감사'];
    
    final hasVacationKeyword = vacationKeywords.any((keyword) => story.contains(keyword));
    if (!hasVacationKeyword) return false;
    
    final progress = await _getOrCreateProgress(SpecialRoom.vacance, 4);
    
    if (progress.hasProcessedRecipe(triggerRecipe.id)) {
      return false;
    }
    
    if (progress.markRecipeAsProcessed(triggerRecipe.id)) {
      progress.incrementCount();
      
      developer.log('Vacance progress: ${progress.currentCount}/4 grateful vacation recipes', name: 'BurrowUnlockService');
      
      await _saveProgress([progress]);
      
      return progress.isCompleted;
    }
    
    return false;
  }

  // === Hive 저장/로드 헬퍼 메서드들 ===
  
  /// 마일스톤들 로드
  Future<List<BurrowMilestone>> _loadMilestones() async {
    try {
      return await _storageService.loadMilestones();
    } catch (e) {
      developer.log('Failed to load milestones: $e', name: 'BurrowUnlockService');
      return [];
    }
  }
  
  /// 단일 마일스톤 업데이트 (public)
  Future<void> updateMilestone(BurrowMilestone milestone) async {
    try {
      await _storageService.updateMilestone(milestone);
      developer.log('Updated milestone: ${milestone.title}', name: 'BurrowUnlockService');
    } catch (e) {
      developer.log('Failed to update milestone: $e', name: 'BurrowUnlockService');
      rethrow;
    }
  }

  /// 마일스톤들 업데이트
  Future<void> _updateMilestones(List<BurrowMilestone> milestones) async {
    try {
      await _storageService.updateMilestones(milestones);
      developer.log('Updated ${milestones.length} milestones', name: 'BurrowUnlockService');
    } catch (e) {
      developer.log('Failed to update milestones: $e', name: 'BurrowUnlockService');
    }
  }
  
  /// 진행상황들 저장
  Future<void> _saveProgress(List<UnlockProgress> progressList) async {
    try {
      await _storageService.saveProgress(progressList);
      developer.log('Saved ${progressList.length} progress items', name: 'BurrowUnlockService');
    } catch (e) {
      developer.log('Failed to save progress: $e', name: 'BurrowUnlockService');
    }
  }
  
  /// 진행상황들 로드
  Future<List<UnlockProgress>> _loadProgress() async {
    try {
      return await _storageService.loadProgress();
    } catch (e) {
      developer.log('Failed to load progress: $e', name: 'BurrowUnlockService');
      return [];
    }
  }
}