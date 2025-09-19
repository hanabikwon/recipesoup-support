import 'package:flutter/material.dart';

/// 감정 상태를 정의하는 Enum
/// 8가지 감정으로 요리와 연결된 감성을 표현
enum Mood {
  happy('😊', '기쁨', 'happy'),
  peaceful('😌', '평온', 'peaceful'),
  sad('😢', '슬픔', 'sad'),
  tired('😴', '피로', 'tired'),
  excited('🤩', '설렘', 'excited'),
  nostalgic('🥺', '그리움', 'nostalgic'),
  comfortable('☺️', '편안함', 'comfortable'),
  grateful('🙏', '감사', 'grateful');
  
  const Mood(this.emoji, this.korean, this.english);
  
  /// 감정을 나타내는 이모지
  final String emoji;
  
  /// 한국어 감정명
  final String korean;
  
  /// 영어 감정명
  final String english;
  
  /// UI 표시용 문자열 (이모지 + 한국어)
  String get displayName => '$emoji $korean';
  
  /// Hive 저장용 index에서 Mood 복원
  static Mood fromIndex(int index) {
    if (index < 0 || index >= Mood.values.length) {
      throw ArgumentError('Invalid mood index: $index');
    }
    return Mood.values[index];
  }
  
  /// 감정별 설명 텍스트
  String get description {
    switch (this) {
      case Mood.happy:
        return '기쁘고 즐거운 마음으로 요리했을 때';
      case Mood.peaceful:
        return '평온하고 차분한 마음으로 요리했을 때';
      case Mood.sad:
        return '슬프거나 힘들 때 위로가 되는 요리';
      case Mood.tired:
        return '피곤할 때 간단히 만든 요리';
      case Mood.excited:
        return '설레고 기대되는 마음으로 만든 요리';
      case Mood.nostalgic:
        return '그리운 추억이 담긴 요리';
      case Mood.comfortable:
        return '편안하고 안정된 마음으로 만든 요리';
      case Mood.grateful:
        return '감사한 마음을 담아 만든 요리';
    }
  }

  /// 감정별 Material 아이콘
  IconData get icon {
    switch (this) {
      case Mood.happy:
        return Icons.sentiment_very_satisfied;
      case Mood.peaceful:
        return Icons.spa;
      case Mood.sad:
        return Icons.sentiment_dissatisfied;
      case Mood.tired:
        return Icons.bedtime;
      case Mood.excited:
        return Icons.star;
      case Mood.nostalgic:
        return Icons.home;
      case Mood.comfortable:
        return Icons.weekend;
      case Mood.grateful:
        return Icons.volunteer_activism;
    }
  }
}