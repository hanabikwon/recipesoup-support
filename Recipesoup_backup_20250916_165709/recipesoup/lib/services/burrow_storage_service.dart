import 'dart:developer' as developer;
import 'package:hive/hive.dart';
import '../models/burrow_milestone.dart';

/// 토끼굴 마일스톤 전용 Hive 저장소 서비스
/// 기존 HiveService와 분리하여 독립적인 박스 관리
class BurrowStorageService {
  final String _milestoneBoxName = 'burrow_milestones';
  final String _progressBoxName = 'unlock_progress';
  
  Box<Map<String, dynamic>>? _milestoneBox;
  Box<Map<String, dynamic>>? _progressBox;
  
  /// 초기화
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_milestoneBoxName)) {
        _milestoneBox = await Hive.openBox<Map<String, dynamic>>(_milestoneBoxName);
      } else {
        _milestoneBox = Hive.box<Map<String, dynamic>>(_milestoneBoxName);
      }
      
      if (!Hive.isBoxOpen(_progressBoxName)) {
        _progressBox = await Hive.openBox<Map<String, dynamic>>(_progressBoxName);
      } else {
        _progressBox = Hive.box<Map<String, dynamic>>(_progressBoxName);
      }
      
      developer.log('BurrowStorageService initialized', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to initialize BurrowStorageService: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 마일스톤 박스 가져오기
  Future<Box<Map<String, dynamic>>> get _getMilestoneBox async {
    if (_milestoneBox == null || !_milestoneBox!.isOpen) {
      await initialize();
    }
    return _milestoneBox!;
  }
  
  /// 진행상황 박스 가져오기
  Future<Box<Map<String, dynamic>>> get _getProgressBox async {
    if (_progressBox == null || !_progressBox!.isOpen) {
      await initialize();
    }
    return _progressBox!;
  }
  
  // === 마일스톤 저장/로드 ===
  
  /// 모든 마일스톤 저장
  Future<void> saveMilestones(List<BurrowMilestone> milestones) async {
    try {
      final box = await _getMilestoneBox;
      
      // 기존 데이터 클리어
      await box.clear();
      
      // 새 마일스톤들 저장
      final milestoneData = <String, Map<String, dynamic>>{};
      for (int i = 0; i < milestones.length; i++) {
        milestoneData['milestone_$i'] = milestones[i].toJson();
      }
      
      await box.putAll(milestoneData);
      
      developer.log('Saved ${milestones.length} milestones', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to save milestones: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 모든 마일스톤 로드
  Future<List<BurrowMilestone>> loadMilestones() async {
    try {
      final box = await _getMilestoneBox;
      
      if (box.isEmpty) {
        developer.log('No milestones found, returning empty list', name: 'BurrowStorageService');
        return [];
      }
      
      final milestones = <BurrowMilestone>[];
      for (final jsonData in box.values) {
        try {
          final milestone = BurrowMilestone.fromJson(jsonData);
          milestones.add(milestone);
        } catch (e) {
          developer.log('Failed to parse milestone: $e', name: 'BurrowStorageService');
          // 개별 마일스톤 파싱 실패시 계속 진행
        }
      }
      
      developer.log('Loaded ${milestones.length} milestones', name: 'BurrowStorageService');
      return milestones;
    } catch (e) {
      developer.log('Failed to load milestones: $e', name: 'BurrowStorageService');
      return [];
    }
  }
  
  /// 단일 마일스톤 업데이트
  Future<void> updateMilestone(BurrowMilestone milestone) async {
    try {
      final box = await _getMilestoneBox;
      
      // 기존 마일스톤 찾기 (level과 burrowType으로 식별)
      String? keyToUpdate;
      for (final entry in box.toMap().entries) {
        final jsonData = entry.value;
        final level = jsonData['level'] as int?;
        final burrowTypeStr = jsonData['burrowType'] as String?;
        
        if (level == milestone.level && 
            burrowTypeStr == milestone.burrowType.name) {
          keyToUpdate = entry.key;
          break;
        }
      }
      
      if (keyToUpdate != null) {
        await box.put(keyToUpdate, milestone.toJson());
        developer.log('Updated milestone: ${milestone.title}', name: 'BurrowStorageService');
      } else {
        developer.log('Milestone not found for update: ${milestone.title}', name: 'BurrowStorageService');
      }
    } catch (e) {
      developer.log('Failed to update milestone: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 여러 마일스톤 업데이트
  Future<void> updateMilestones(List<BurrowMilestone> milestones) async {
    for (final milestone in milestones) {
      await updateMilestone(milestone);
    }
  }
  
  // === 진행상황 저장/로드 ===
  
  /// 모든 진행상황 저장
  Future<void> saveProgress(List<UnlockProgress> progressList) async {
    try {
      final box = await _getProgressBox;
      
      // 기존 데이터 클리어
      await box.clear();
      
      // 새 진행상황들 저장
      final progressData = <String, Map<String, dynamic>>{};
      for (final progress in progressList) {
        progressData['progress_${progress.roomType.name}'] = progress.toJson();
      }
      
      await box.putAll(progressData);
      
      developer.log('Saved ${progressList.length} progress items', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to save progress: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 모든 진행상황 로드
  Future<List<UnlockProgress>> loadProgress() async {
    try {
      final box = await _getProgressBox;
      
      if (box.isEmpty) {
        developer.log('No progress found, returning empty list', name: 'BurrowStorageService');
        return [];
      }
      
      final progressList = <UnlockProgress>[];
      for (final jsonData in box.values) {
        try {
          final progress = UnlockProgress.fromJson(jsonData);
          progressList.add(progress);
        } catch (e) {
          developer.log('Failed to parse progress: $e', name: 'BurrowStorageService');
          // 개별 진행상황 파싱 실패시 계속 진행
        }
      }
      
      developer.log('Loaded ${progressList.length} progress items', name: 'BurrowStorageService');
      return progressList;
    } catch (e) {
      developer.log('Failed to load progress: $e', name: 'BurrowStorageService');
      return [];
    }
  }
  
  /// 단일 진행상황 업데이트
  Future<void> updateProgress(UnlockProgress progress) async {
    try {
      final box = await _getProgressBox;
      final key = 'progress_${progress.roomType.name}';
      
      await box.put(key, progress.toJson());
      
      developer.log('Updated progress for ${progress.roomType.name}', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to update progress: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 여러 진행상황 업데이트
  Future<void> updateProgressList(List<UnlockProgress> progressList) async {
    for (final progress in progressList) {
      await updateProgress(progress);
    }
  }
  
  /// 특정 특별 공간의 진행상황 로드
  Future<UnlockProgress?> loadProgressForRoom(SpecialRoom room) async {
    try {
      final box = await _getProgressBox;
      final key = 'progress_${room.name}';
      final jsonData = box.get(key);
      
      if (jsonData != null) {
        return UnlockProgress.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      developer.log('Failed to load progress for ${room.name}: $e', name: 'BurrowStorageService');
      return null;
    }
  }
  
  // === 데이터 관리 ===
  
  /// 모든 마일스톤 데이터 삭제
  Future<void> clearAllMilestones() async {
    try {
      final box = await _getMilestoneBox;
      await box.clear();
      developer.log('Cleared all milestones', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to clear milestones: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 모든 진행상황 데이터 삭제
  Future<void> clearAllProgress() async {
    try {
      final box = await _getProgressBox;
      await box.clear();
      developer.log('Cleared all progress', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to clear progress: $e', name: 'BurrowStorageService');
      rethrow;
    }
  }
  
  /// 모든 토끼굴 데이터 삭제 (리셋용)
  Future<void> resetAllData() async {
    await clearAllMilestones();
    await clearAllProgress();
    developer.log('Reset all burrow data', name: 'BurrowStorageService');
  }
  
  // === 통계 및 디버그 ===
  
  /// 저장된 마일스톤 수
  Future<int> getMilestoneCount() async {
    try {
      final box = await _getMilestoneBox;
      return box.length;
    } catch (e) {
      return 0;
    }
  }
  
  /// 저장된 진행상황 수
  Future<int> getProgressCount() async {
    try {
      final box = await _getProgressBox;
      return box.length;
    } catch (e) {
      return 0;
    }
  }
  
  /// 스토리지 사용량 체크 (디버그용)
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final milestoneCount = await getMilestoneCount();
      final progressCount = await getProgressCount();
      
      return {
        'milestoneCount': milestoneCount,
        'progressCount': progressCount,
        'milestoneBoxName': _milestoneBoxName,
        'progressBoxName': _progressBoxName,
        'milestoneBoxOpen': _milestoneBox?.isOpen ?? false,
        'progressBoxOpen': _progressBox?.isOpen ?? false,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 정리
  Future<void> dispose() async {
    try {
      if (_milestoneBox != null && _milestoneBox!.isOpen) {
        await _milestoneBox!.close();
      }
      
      if (_progressBox != null && _progressBox!.isOpen) {
        await _progressBox!.close();
      }
      
      developer.log('BurrowStorageService disposed', name: 'BurrowStorageService');
    } catch (e) {
      developer.log('Failed to dispose BurrowStorageService: $e', name: 'BurrowStorageService');
    }
  }
}