import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/burrow_milestone.dart';
import 'hive_service.dart';

/// 성장여정 전용 unlock 서비스
/// 레시피 개수만 체크하는 단순하고 안정적인 로직
class GrowthTrackService {
  final HiveService _hiveService;

  GrowthTrackService({
    required HiveService hiveService,
  }) : _hiveService = hiveService;

  /// 성장여정 마일스톤 unlock 체크
  /// 최신 마일스톤 상태를 파라미터로 받아서 중복 unlock 방지
  Future<List<BurrowMilestone>> checkUnlocks({List<BurrowMilestone>? currentMilestones}) async {
    try {
      // 레시피 개수 가져오기
      final allRecipes = await _hiveService.getAllRecipes();
      final recipeCount = allRecipes.length;

      developer.log('Growth track check: $recipeCount recipes found', name: 'GrowthTrackService');

      // 마일스톤 상태 가져오기 (최신 상태 우선 사용)
      final milestones = currentMilestones ?? await _loadMilestones();
      final growthMilestones = milestones.where((m) => m.burrowType == BurrowType.growth).toList();

      developer.log('🔥 DUPLICATE DEBUG: Found ${growthMilestones.length} growth milestones', name: 'GrowthTrackService');

      // unlock 조건 체크
      final newUnlocks = <BurrowMilestone>[];

      for (final milestone in growthMilestones) {
        developer.log('🔥 DUPLICATE DEBUG: L${milestone.level} - isUnlocked: ${milestone.isUnlocked}, requiredRecipes: ${milestone.requiredRecipes}, currentRecipes: $recipeCount', name: 'GrowthTrackService');
        
        // 🔥 중복 unlock 방지: 이미 unlock된 마일스톤은 스킵
        if (milestone.isUnlocked) {
          developer.log('🔥 DUPLICATE FIX: L${milestone.level} already unlocked, skipping', name: 'GrowthTrackService');
          continue;
        }
        
        if (milestone.requiredRecipes != null && recipeCount >= milestone.requiredRecipes!) {
          developer.log('🔥 NEW UNLOCK: Unlocking growth milestone L${milestone.level}', name: 'GrowthTrackService');
          newUnlocks.add(milestone);
        }
      }

      developer.log('Growth track found ${newUnlocks.length} new unlocks', name: 'GrowthTrackService');
      return newUnlocks;

    } catch (e) {
      developer.log('Error in growth track check: $e', name: 'GrowthTrackService');
      return [];
    }
  }

  /// 마일스톤 로드 (BurrowUnlockCoordinator와 동일한 저장소 사용)
  Future<List<BurrowMilestone>> _loadMilestones() async {
    try {
      final milestoneData = await _hiveService.getBurrowMilestones();
      if (milestoneData != null && milestoneData.isNotEmpty) {
        return milestoneData
            .map((data) => BurrowMilestone.fromJson(Map<String, dynamic>.from(data)))
            .toList();
      }
    } catch (e) {
      developer.log('Error loading milestones: $e', name: 'GrowthTrackService');
    }

    // 기본 마일스톤 생성
    return _createDefaultMilestones();
  }

  /// 기존 올바른 마일스톤 데이터를 사용한 기본 마일스톤 생성
  List<BurrowMilestone> _createDefaultMilestones() {
    final milestones = <BurrowMilestone>[];

    // 완전한 32단계 마일스톤 데이터 맵 (실제 이미지 파일명 매칭)
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
      18: {'requiredRecipes': 54, 'title': '장인정신 토끼굴', 'description': '요리를 담아냼 그릇까지 직접 빚는 공방', 'image': 'burrow_ceramist.png'},
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

    // 성장 트랙 마일스톤들 (레벨 1-32) - 완전한 성장 여정
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

    return milestones;
  }
}