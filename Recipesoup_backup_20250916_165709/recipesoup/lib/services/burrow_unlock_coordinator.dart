import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:hive/hive.dart';
import '../models/recipe.dart';
import '../models/mood.dart';
import '../models/burrow_milestone.dart';
import '../services/hive_service.dart';
import '../services/burrow_storage_service.dart';

/// 토끼굴 마일스톤 언락 코디네이터
/// 성장 트랙과 특별 공간의 언락 조건을 체크하고 관리
class BurrowUnlockCoordinator {
  final HiveService _hiveService;
  final BurrowStorageService _storageService;

  // 중복 방지를 위한 처리된 레시피 IDs 캐시
  final Set<String> _processedRecipeIds = <String>{};

  // 언락 큐 (동시 다중 언락 방지)
  final List<UnlockQueueItem> _unlockQueue = [];

  BurrowUnlockCoordinator({
    required HiveService hiveService,
    BurrowStorageService? storageService,
  }) : _hiveService = hiveService,
       _storageService = storageService ?? BurrowStorageService();

  /// 초기화 - 기본 마일스톤 생성 및 진행상황 로드
  Future<void> initialize() async {
    try {
      await _storageService.initialize();
      await _createDefaultMilestones();
      await _loadProgressData();
      developer.log('BurrowUnlockCoordinator initialized', name: 'BurrowUnlockCoordinator');
    } catch (e) {
      developer.log('Failed to initialize BurrowUnlockCoordinator: $e', name: 'BurrowUnlockCoordinator');
      rethrow;
    }
  }

  /// 단일 마일스톤 업데이트
  Future<void> updateMilestone(BurrowMilestone milestone) async {
    try {
      await _storageService.updateMilestone(milestone);
      developer.log('Updated milestone: ${milestone.title}', name: 'BurrowUnlockCoordinator');
    } catch (e) {
      developer.log('Failed to update milestone: $e', name: 'BurrowUnlockCoordinator');
      rethrow;
    }
  }

  /// 레시피에 대한 모든 unlock 체크 (성장여정 + 특별한 공간)
  Future<List<BurrowMilestone>> checkUnlocksForRecipe(Recipe recipe) async {
    if (_processedRecipeIds.contains(recipe.id)) {
      developer.log('Recipe ${recipe.id} already processed, skipping', name: 'BurrowUnlockCoordinator');
      return [];
    }

    final newUnlocks = <BurrowMilestone>[];

    try {
      // 성장 트랙 체크
      final growthUnlocks = await _checkGrowthTrack();
      newUnlocks.addAll(growthUnlocks);

      // 특별 공간 체크
      final specialUnlocks = await _checkSpecialRooms(recipe);
      newUnlocks.addAll(specialUnlocks);

      // 처리된 레시피 마킹
      _processedRecipeIds.add(recipe.id);

      // 언락된 마일스톤들을 큐에 추가
      if (newUnlocks.isNotEmpty) {
        for (final milestone in newUnlocks) {
          _unlockQueue.add(UnlockQueueItem(
            milestone: milestone,
            unlockedAt: DateTime.now(),
            triggerRecipeId: recipe.id,
          ));

          milestone.unlock();
        }

        // 모든 마일스톤을 다시 로드하고, 언락된 것들을 업데이트
        final allMilestones = await _loadMilestones();

        // 언락된 마일스톤들을 찾아서 unlock 상태 적용
        for (final unlockedMilestone in newUnlocks) {
          final storageIndex = allMilestones.indexWhere((m) => m.id == unlockedMilestone.id);
          if (storageIndex != -1) {
            allMilestones[storageIndex].unlock();
          }
        }

        await _updateMilestones(allMilestones);

        developer.log('Unlocked ${newUnlocks.length} milestones for recipe ${recipe.id}', name: 'BurrowUnlockCoordinator');
      }

    } catch (e) {
      developer.log('Failed to check unlocks for recipe ${recipe.id}: $e', name: 'BurrowUnlockCoordinator');
      _processedRecipeIds.remove(recipe.id);
    }

    return newUnlocks;
  }

  /// 모든 레시피 가져오기 (BurrowProvider 호환성을 위한 메서드)
  Future<List<Recipe>> getAllRecipes() async {
    return await _hiveService.getAllRecipes();
  }

  /// 언락 큐에서 다음 아이템 가져오기
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

  /// 현재 진행상황들 가져오기
  Future<List<UnlockProgress>> getCurrentProgress() async {
    return await _loadProgress();
  }

  /// 마일스톤들 로드
  Future<List<BurrowMilestone>> _loadMilestones() async {
    try {
      return await _storageService.loadMilestones();
    } catch (e) {
      developer.log('Failed to load milestones: $e', name: 'BurrowUnlockCoordinator');
      return [];
    }
  }

  /// 마일스톤들 업데이트
  Future<void> _updateMilestones(List<BurrowMilestone> milestones) async {
    try {
      await _storageService.updateMilestones(milestones);
      developer.log('Updated ${milestones.length} milestones', name: 'BurrowUnlockCoordinator');
    } catch (e) {
      developer.log('Failed to update milestones: $e', name: 'BurrowUnlockCoordinator');
    }
  }

  /// 기본 마일스톤들 생성 (성장여정 32개 + 특별한공간 16개)
  Future<void> _createDefaultMilestones() async {
    final existingMilestones = await _loadMilestones();
    if (existingMilestones.isNotEmpty) return;

    final milestones = <BurrowMilestone>[];

    // ===== 성장여정 32개 마일스톤 데이터 =====
    final milestoneData = {
      // ===== 🌱 기초 입문 단계 (1-8레벨): 요리 시작 =====
      1: {'requiredRecipes': 1, 'title': '아늑한 토끼굴', 'description': '첫 레시피와 함께 열린 작은 굴, 여정의 시작', 'image': 'burrow_tiny.png'},
      2: {'requiredRecipes': 3, 'title': '작은 토끼굴', 'description': '점점 커지는 요리에 대한 관심과 열정', 'image': 'burrow_small.png'},
      3: {'requiredRecipes': 5, 'title': '홈쿡 토끼굴', 'description': '집에서 만드는 요리의 즐거움 발견', 'image': 'burrow_homecook.png'},
      4: {'requiredRecipes': 7, 'title': '정원사 토끼굴', 'description': '재료를 심고 가꾸며 느끼는 자연의 소중함', 'image': 'burrow_garden.png'},
      5: {'requiredRecipes': 10, 'title': '수확의 토끼굴', 'description': '첫 수확의 기쁨과 성취감이 가득', 'image': 'burrow_harvest.png'},
      6: {'requiredRecipes': 12, 'title': '가족식사 토끼굴', 'description': '사랑하는 가족과 함께하는 따뜻한 식탁', 'image': 'burrow_familydinner.png'},
      7: {'requiredRecipes': 15, 'title': '시장탐험 토끼굴', 'description': '다양한 식재료를 찾아 탐험하는 재미', 'image': 'burrow_market.png'},
      8: {'requiredRecipes': 18, 'title': '어부의 토끼굴', 'description': '자연에서 건져올린 싱싱한 식재료', 'image': 'burrow_fishing.png'},

      // ===== 📚 학습 발전 단계 (9-16레벨): 기술 습득 =====
      9: {'requiredRecipes': 21, 'title': '발전하는 토끼굴', 'description': '더 많은 가능성을 품은 토끼굴', 'image': 'burrow_medium.png'},
      10: {'requiredRecipes': 25, 'title': '회복의 토끼굴', 'description': '건강 관리와 치유의 요리법 터득', 'image': 'burrow_sick.png'},
      11: {'requiredRecipes': 28, 'title': '견습 요리사 토끼굴', 'description': '본격적인 요리의 길로 들어선 견습생', 'image': 'burrow_apprentice.png'},
      12: {'requiredRecipes': 32, 'title': '연구실 토끼굴', 'description': '과학적으로 분석하는 레시피 연구', 'image': 'burrow_recipe_lab.png'},
      13: {'requiredRecipes': 35, 'title': '실험정신 토끼굴', 'description': '새로운 조합과 실험을 즐기며 도전', 'image': 'burrow_experiment.png'},
      14: {'requiredRecipes': 39, 'title': '서재 토끼굴', 'description': '넓고 깊은 요리 지식이 쌓인 보물 창고', 'image': 'burrow_study.png'},
      15: {'requiredRecipes': 42, 'title': '버섯채집가 토끼굴', 'description': '고급 재료와 특별한 식재료 탐구', 'image': 'burrow_forest_mushroom.png'},
      16: {'requiredRecipes': 46, 'title': '요리책 저자 토끼굴', 'description': '첫 번째 요리책을 완성한 작가', 'image': 'burrow_cookbook.png'},

      // ===== 🎨 창작 숙련 단계 (17-24레벨): 전문성 개발 =====
      17: {'requiredRecipes': 50, 'title': '스케치 토끼굴', 'description': '요리 재료를 관찰하며 그리는 화실 모임', 'image': 'burrow_sketch.png'},
      18: {'requiredRecipes': 54, 'title': '장인정신 토끼굴', 'description': '요리를 담아냄 그릇까지 직접 빚는 공방', 'image': 'burrow_ceramist.png'},
      19: {'requiredRecipes': 58, 'title': '전문주방 토끼굴', 'description': '프로페셔널한 장비가 갖춰진 전문 주방', 'image': 'burrow_kitchen.png'},
      20: {'requiredRecipes': 62, 'title': '요리선생 토끼굴', 'description': '요리의 기본기를 가르치는 멘토링 시간', 'image': 'burrow_teacher.png'},
      21: {'requiredRecipes': 66, 'title': '미쉐린 토끼굴', 'description': '뛰어난 레스토랑을 방문하는 미식 탐험가', 'image': 'burrow_tasting.png'},
      22: {'requiredRecipes': 70, 'title': '대규모 토끼굴', 'description': '넓게 확장된 웅장한 규모의 토끼굴', 'image': 'burrow_large.png'},
      23: {'requiredRecipes': 74, 'title': '소믈리에 토끼굴', 'description': '요리와 완벽한 마리아쥬를 이루는 와인 셀렉션', 'image': 'burrow_winecellar.png'},
      24: {'requiredRecipes': 78, 'title': '요리경연 토끼굴', 'description': '치열한 요리 경연에서 실력을 겨루는 콘테스트', 'image': 'burrow_competition.png'},

      // ===== 🌍 마스터 단계 (25-30레벨): 세계적 인정 =====
      25: {'requiredRecipes': 82, 'title': '요리축제 토끼굴', 'description': '마을 사람들과 어우러져 요리를 즐기는 축제', 'image': 'burrow_festival.png'},
      26: {'requiredRecipes': 86, 'title': '미식여행 토끼굴', 'description': '세계 각지의 미식 여행으로 넓어지는 견문', 'image': 'burrow_gourmet_trip.png'},
      27: {'requiredRecipes': 90, 'title': '세계적 요리사 토끼굴', 'description': '국제적 명성의 셰프들과 협업하는 주방', 'image': 'burrow_international.png'},
      28: {'requiredRecipes': 94, 'title': '티 소믈리에 토끼굴', 'description': '일본 전통 차문화의 정수를 배우는 토끼굴', 'image': 'burrow_japan_trip.png'},
      29: {'requiredRecipes': 98, 'title': '치즈투어 토끼굴', 'description': '전통 있는 이탈리아 치즈 공장 견학', 'image': 'burrow_cheeze_tour.png'},
      30: {'requiredRecipes': 102, 'title': '감사의 토끼굴', 'description': '다같이 둘러앉아 행복이 가득한 식탁', 'image': 'burrow_thanksgiving.png'},

      // ===== 🏆 최종 완성 단계 (31-32레벨): 꿈의 실현 =====
      31: {'requiredRecipes': 106, 'title': '시그니처 요리 토끼굴', 'description': '나만의 시그니처 요리가 탄생한 순간', 'image': 'burrow_signaturedish.png'},
      32: {'requiredRecipes': 110, 'title': '꿈의 레스토랑 토끼굴', 'description': '꿈에 그리던 작고 따스한 레스토랑을 연 토끼', 'image': 'burrow_own_restaurant.png'},
    };

    // 성장 트랙 마일스톤들 (레벨 1-32) 생성
    for (int level = 1; level <= 32; level++) {
      final data = milestoneData[level];
      if (data != null) {
        milestones.add(BurrowMilestone(
          id: 'growth_$level',
          level: level,
          title: data['title'] as String,
          description: data['description'] as String,
          imagePath: 'assets/images/burrow/milestones/${data['image'] as String}',
          burrowType: BurrowType.growth,
          requiredRecipes: data['requiredRecipes'] as int,
          isUnlocked: false,
          unlockedAt: null,
        ));
      }
    }

    // ===== 기존 특별한 공간 16개 사용 (새로 만들지 않고 기존 enum 활용) =====
    // SpecialRoom enum에 정의된 16개 특별 공간들:
    // ballroom, hotSpring, orchestra, alchemyLab, fineDining,
    // alps, camping, autumn, springPicnic, surfing, snorkel,
    // summerbeach, baliYoga, orientExpress, canvas, vacance

    final specialRoomConfigs = {
      SpecialRoom.ballroom: {
        'title': '화려한 무도회장',
        'description': '사교적 요리사를 위한 우아한 파티 공간',
        'unlockConditions': {'social_recipes': 5, 'party_tags': 3}
      },
      SpecialRoom.hotSpring: {
        'title': '힐링 온천탕',
        'description': '피로를 풀어주는 따뜻한 치유의 공간',
        'unlockConditions': {'healing_recipes': 4, 'comfort_food': 3}
      },
      SpecialRoom.orchestra: {
        'title': '감정의 음악회장',
        'description': '감정 마에스트로를 위한 선율이 흐르는 공간',
        'unlockConditions': {'emotional_variety': 6, 'mood_diversity': 5}
      },
      SpecialRoom.alchemyLab: {
        'title': '요리 실험실',
        'description': '도전적 요리사를 위한 창의적 실험 공간',
        'unlockConditions': {'experimental_recipes': 5, 'new_ingredients': 10}
      },
      SpecialRoom.fineDining: {
        'title': '파인다이닝 레스토랑',
        'description': '완벽주의자를 위한 최고급 요리 공간',
        'unlockConditions': {'five_star_recipes': 10, 'gourmet_level': 8}
      },
      SpecialRoom.alps: {
        'title': '알프스 별장',
        'description': '극한 도전자를 위한 고산지대 요리 공간',
        'unlockConditions': {'challenge_recipes': 7, 'difficulty_hard': 5}
      },
      SpecialRoom.camping: {
        'title': '자연 캠핑장',
        'description': '자연 애호가를 위한 야외 요리 공간',
        'unlockConditions': {'outdoor_recipes': 5, 'nature_tags': 4}
      },
      SpecialRoom.autumn: {
        'title': '가을 정원',
        'description': '계절 감성가를 위한 단풍이 아름다운 공간',
        'unlockConditions': {'autumn_recipes': 8, 'seasonal_cooking': 6}
      },
      SpecialRoom.springPicnic: {
        'title': '봄 피크닉 장소',
        'description': '외출 요리사를 위한 봄꽃 가득한 야외 공간',
        'unlockConditions': {'picnic_recipes': 5, 'spring_ingredients': 6}
      },
      SpecialRoom.surfing: {
        'title': '서핑 비치',
        'description': '해변 요리사를 위한 파도 소리가 들리는 공간',
        'unlockConditions': {'beach_recipes': 4, 'seafood_specialty': 5}
      },
      SpecialRoom.snorkel: {
        'title': '스노클링 코브',
        'description': '바다 탐험가를 위한 신선한 해산물 공간',
        'unlockConditions': {'seafood_recipes': 8, 'ocean_ingredients': 6}
      },
      SpecialRoom.summerbeach: {
        'title': '여름 해변',
        'description': '휴양지 요리사를 위한 시원한 여름 공간',
        'unlockConditions': {'summer_recipes': 7, 'cool_dishes': 5}
      },
      SpecialRoom.baliYoga: {
        'title': '발리 요가 센터',
        'description': '명상 요리사를 위한 평온한 수련 공간',
        'unlockConditions': {'meditation_recipes': 4, 'peaceful_mood': 6}
      },
      SpecialRoom.orientExpress: {
        'title': '오리엔트 특급열차',
        'description': '여행 요리사를 위한 이국적 여행 공간',
        'unlockConditions': {'international_recipes': 6, 'travel_inspired': 5}
      },
      SpecialRoom.canvas: {
        'title': '예술가 아틀리에',
        'description': '예술가 요리사를 위한 창작의 영감이 넘치는 공간',
        'unlockConditions': {'artistic_recipes': 5, 'creative_presentation': 7}
      },
      SpecialRoom.vacance: {
        'title': '바캉스 빌라',
        'description': '휴식 요리사를 위한 여유로운 휴양 공간',
        'unlockConditions': {'vacation_recipes': 4, 'relaxation_mood': 5}
      },
    };

    // 기존 SpecialRoom enum을 사용한 특별 공간 마일스톤들 생성
    for (final entry in specialRoomConfigs.entries) {
      final room = entry.key;
      final config = entry.value;

      milestones.add(BurrowMilestone.special(
        room: room,
        title: config['title'] as String,
        description: config['description'] as String,
        unlockConditions: config['unlockConditions'] as Map<String, dynamic>,
      ));
    }

    await _storageService.saveMilestones(milestones);
    developer.log('🔥 ULTRA THINK: Created ${milestones.length} complete milestones (32 growth + 16 special)', name: 'BurrowUnlockCoordinator');
  }

  /// 진행상황 데이터 로드
  Future<void> _loadProgressData() async {
    try {
      final progressList = await _loadProgress();

      for (final progress in progressList) {
        _processedRecipeIds.addAll(progress.processedRecipeIds);
      }

      developer.log('Loaded ${_processedRecipeIds.length} processed recipe IDs', name: 'BurrowUnlockCoordinator');
    } catch (e) {
      developer.log('Failed to load progress data: $e', name: 'BurrowUnlockCoordinator');
    }
  }

  /// 성장 트랙 마일스톤 체크
  Future<List<BurrowMilestone>> _checkGrowthTrack() async {
    final allRecipes = await _hiveService.getAllRecipes();
    final recipeCount = allRecipes.length;

    final milestones = await _loadMilestones();
    final growthMilestones = milestones.where((m) => m.isGrowthTrack).toList();

    final newUnlocks = <BurrowMilestone>[];

    for (final milestone in growthMilestones) {
      if (!milestone.isUnlocked && milestone.requiredRecipes != null) {
        if (recipeCount >= milestone.requiredRecipes!) {
          newUnlocks.add(milestone);
        }
      }
    }

    return newUnlocks;
  }

  /// 특별 공간 마일스톤 체크
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

  /// 개별 특별 공간 언락 조건 체크
  Future<bool> _checkSpecialRoomCondition(SpecialRoom room, Recipe triggerRecipe) async {
    // 간단한 예시 구현 - 실제로는 각 방별로 다른 조건들
    return false; // 기본적으로 false 반환
  }

  /// 진행상황들 저장
  Future<void> _saveProgress(List<UnlockProgress> progressList) async {
    try {
      await _storageService.saveProgress(progressList);
      developer.log('Saved ${progressList.length} progress items', name: 'BurrowUnlockCoordinator');
    } catch (e) {
      developer.log('Failed to save progress: $e', name: 'BurrowUnlockCoordinator');
    }
  }

  /// 진행상황들 로드
  Future<List<UnlockProgress>> _loadProgress() async {
    try {
      return await _storageService.loadProgress();
    } catch (e) {
      developer.log('Failed to load progress: $e', name: 'BurrowUnlockCoordinator');
      return [];
    }
  }
}