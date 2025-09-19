import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/burrow_milestone.dart';
import '../models/recipe.dart';
import 'hive_service.dart';

/// 특별한 공간 전용 unlock 서비스
/// 개별 레시피 조건 분석하는 복잡한 로직을 격리
class SpecialRoomService {
  final HiveService _hiveService;

  SpecialRoomService({
    required HiveService hiveService,
  }) : _hiveService = hiveService;

  /// 특별한 공간 마일스톤 unlock 체크
  Future<List<BurrowMilestone>> checkUnlocks(Recipe triggerRecipe) async {
    try {
      developer.log('Checking special rooms for recipe: ${triggerRecipe.title}', name: 'SpecialRoomService');

      final milestones = await _loadMilestones();
      final specialMilestones = milestones.where((m) => m.burrowType == BurrowType.special && !m.isUnlocked).toList();

      final newUnlocks = <BurrowMilestone>[];

      for (final milestone in specialMilestones) {
        if (milestone.specialRoom != null) {
          final shouldUnlock = await _checkSpecialRoomCondition(milestone.specialRoom!, triggerRecipe);
          if (shouldUnlock) {
            developer.log('Unlocking special room: ${milestone.specialRoom}', name: 'SpecialRoomService');
            newUnlocks.add(milestone);
          }
        }
      }

      developer.log('Special rooms found ${newUnlocks.length} new unlocks', name: 'SpecialRoomService');
      return newUnlocks;

    } catch (e) {
      developer.log('Error in special room check: $e', name: 'SpecialRoomService');
      return [];
    }
  }

  /// 특별한 공간 조건 체크 (기존 로직 복사)
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

  // ===== 개별 조건 체크 메서드들 (기존 BurrowUnlockService에서 복사) =====

  Future<bool> _checkBallroomCondition(Recipe triggerRecipe) async {
    final mentionedPeople = _extractMentionedPeople(triggerRecipe);
    developer.log('Ballroom check: mentioned people = $mentionedPeople', name: 'SpecialRoomService');
    return mentionedPeople.length >= 2;
  }

  Future<bool> _checkHotSpringCondition(Recipe triggerRecipe) async {
    const keywords = ['온천', '스파', '휴식', '힐링', '명상', '건강', '웰빙', '온수', '따뜻한', '온도'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    final hasKeyword = keywords.any((keyword) => content.contains(keyword));
    developer.log('Hot spring check: has keyword = $hasKeyword', name: 'SpecialRoomService');
    return hasKeyword;
  }

  Future<bool> _checkOrchestraCondition(Recipe triggerRecipe) async {
    const keywords = ['음악', '오케스트라', '연주', '악기', '클래식', '심포니', '하모니', '멜로디', '리듬', '음성'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    final hasKeyword = keywords.any((keyword) => content.contains(keyword));
    developer.log('Orchestra check: has keyword = $hasKeyword', name: 'SpecialRoomService');
    return hasKeyword;
  }

  Future<bool> _checkAlchemyLabCondition(Recipe triggerRecipe) async {
    const keywords = ['실험', '연구', '과학', '화학', '분석', '테스트', '실험실', '연구소', '발견', '개발'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    final hasKeyword = keywords.any((keyword) => content.contains(keyword));
    developer.log('Alchemy lab check: has keyword = $hasKeyword', name: 'SpecialRoomService');
    return hasKeyword;
  }

  Future<bool> _checkFineDiningCondition(Recipe triggerRecipe) async {
    const keywords = ['고급', '파인', '레스토랑', '미슐랭', '셰프', '요리사', '정찬', '코스', '와인', '디너'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    final hasKeyword = keywords.any((keyword) => content.contains(keyword));
    developer.log('Fine dining check: has keyword = $hasKeyword', name: 'SpecialRoomService');
    return hasKeyword;
  }

  // 새로운 특별 공간 조건들
  Future<bool> _checkAlpsCondition(Recipe triggerRecipe) async {
    const keywords = ['알프스', '산', '등산', '하이킹', '고산', '눈', '스키', '추위', '산악', '정상'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkCampingCondition(Recipe triggerRecipe) async {
    const keywords = ['캠핑', '텐트', '모닥불', '바베큐', '아웃도어', '야외', '자연', '숲', '바비큐', '캠프'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkAutumnCondition(Recipe triggerRecipe) async {
    const keywords = ['가을', '단풍', '낙엽', '추수', '감', '밤', '은행', '호박', '고구마', '단감'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkSpringPicnicCondition(Recipe triggerRecipe) async {
    const keywords = ['봄', '피크닉', '꽃', '벚꽃', '나들이', '소풍', '야외', '공원', '잔디', '산책'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkSurfingCondition(Recipe triggerRecipe) async {
    const keywords = ['서핑', '파도', '바다', '해변', '비치', '물결', '보드', '해안', '바닷가', '파도타기'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkSnorkelCondition(Recipe triggerRecipe) async {
    const keywords = ['스노클링', '다이빙', '바다', '물고기', '산호', '바닷속', '수중', '마스크', '물속', '해양'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkSummerbeachCondition(Recipe triggerRecipe) async {
    const keywords = ['여름', '해변', '바다', '수영', '휴가', '휴양', '선크림', '파라솔', '비치', '바캉스'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkBaliYogaCondition(Recipe triggerRecipe) async {
    const keywords = ['발리', '요가', '명상', '힐링', '스파', '마사지', '휴양', '리조트', '발리섬', '인도네시아'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkOrientExpressCondition(Recipe triggerRecipe) async {
    const keywords = ['기차', '여행', '오리엔트', '익스프레스', '철도', '유럽', '여정', '승차', '기차역', '열차'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkCanvasCondition(Recipe triggerRecipe) async {
    const keywords = ['그림', '캔버스', '미술', '화가', '예술', '작품', '전시', '갤러리', '붓', '물감'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  Future<bool> _checkVacanceCondition(Recipe triggerRecipe) async {
    const keywords = ['휴가', '바캉스', '여행', '휴양', '리조트', '호텔', '관광', '휴식', '여유', '힐링'];
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    return keywords.any((keyword) => content.contains(keyword));
  }

  /// 언급된 사람 수 추출 (기존 로직 복사)
  List<String> _extractMentionedPeople(Recipe triggerRecipe) {
    final content = '${triggerRecipe.title} ${triggerRecipe.emotionalStory} ${triggerRecipe.instructions.join(' ')}';
    final keywords = ['친구', '가족', '엄마', '아빠', '형제', '자매', '할머니', '할아버지', '동료', '애인', '연인', '남자친구', '여자친구', '사람들', '모임'];
    return keywords.where((keyword) => content.contains(keyword)).toList();
  }

  /// 마일스톤 로드 (기존 로직 복사)
  Future<List<BurrowMilestone>> _loadMilestones() async {
    try {
      final milestoneData = await _hiveService.getValue('burrow_milestones');
      if (milestoneData != null && milestoneData is List) {
        return milestoneData
            .map((data) => BurrowMilestone.fromJson(Map<String, dynamic>.from(data)))
            .toList();
      }
    } catch (e) {
      developer.log('Error loading milestones: $e', name: 'SpecialRoomService');
    }

    return [];
  }
}