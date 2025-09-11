import 'package:flutter_test/flutter_test.dart';
import 'package:recipesoup/models/mood.dart';

void main() {
  group('Mood Enum Tests', () {
    test('should have exactly 8 mood states', () {
      // Given & When
      final moods = Mood.values;
      
      // Then
      expect(moods.length, equals(8));
    });
    
    test('should have correct mood names', () {
      // Given
      final expectedMoods = [
        'happy', 'peaceful', 'sad', 'tired', 
        'excited', 'nostalgic', 'comfortable', 'grateful'
      ];
      
      // When
      final actualMoods = Mood.values.map((m) => m.english).toList();
      
      // Then
      expect(actualMoods, equals(expectedMoods));
    });
    
    test('should have correct emoji mappings', () {
      // Given & When & Then
      expect(Mood.happy.emoji, equals('😊'));
      expect(Mood.peaceful.emoji, equals('😌'));
      expect(Mood.sad.emoji, equals('😢'));
      expect(Mood.tired.emoji, equals('😴'));
      expect(Mood.excited.emoji, equals('🤩'));
      expect(Mood.nostalgic.emoji, equals('🥺'));
      expect(Mood.comfortable.emoji, equals('☺️'));
      expect(Mood.grateful.emoji, equals('🙏'));
    });
    
    test('should have correct Korean mappings', () {
      // Given & When & Then
      expect(Mood.happy.korean, equals('기쁨'));
      expect(Mood.peaceful.korean, equals('평온'));
      expect(Mood.sad.korean, equals('슬픔'));
      expect(Mood.tired.korean, equals('피로'));
      expect(Mood.excited.korean, equals('설렘'));
      expect(Mood.nostalgic.korean, equals('그리움'));
      expect(Mood.comfortable.korean, equals('편안함'));
      expect(Mood.grateful.korean, equals('감사'));
    });
    
    test('should have correct English mappings', () {
      // Given & When & Then
      expect(Mood.happy.english, equals('happy'));
      expect(Mood.peaceful.english, equals('peaceful'));
      expect(Mood.sad.english, equals('sad'));
      expect(Mood.tired.english, equals('tired'));
      expect(Mood.excited.english, equals('excited'));
      expect(Mood.nostalgic.english, equals('nostalgic'));
      expect(Mood.comfortable.english, equals('comfortable'));
      expect(Mood.grateful.english, equals('grateful'));
    });
    
    test('should preserve enum index for Hive storage', () {
      // Given
      final happyMood = Mood.happy;
      final sadMood = Mood.sad;
      
      // When
      final happyIndex = happyMood.index;
      final sadIndex = sadMood.index;
      
      // Then
      expect(happyIndex, equals(0)); // 첫 번째 enum
      expect(sadIndex, equals(2)); // 세 번째 enum
      
      // 복원 테스트
      final restoredHappy = Mood.values[happyIndex];
      final restoredSad = Mood.values[sadIndex];
      
      expect(restoredHappy, equals(Mood.happy));
      expect(restoredSad, equals(Mood.sad));
    });
    
    test('should handle all mood values for UI display', () {
      // Given & When
      for (final mood in Mood.values) {
        // Then - 모든 필드가 비어있지 않아야 함
        expect(mood.emoji.isNotEmpty, isTrue, 
               reason: '${mood.name} emoji should not be empty');
        expect(mood.korean.isNotEmpty, isTrue,
               reason: '${mood.name} korean should not be empty');
        expect(mood.english.isNotEmpty, isTrue,
               reason: '${mood.name} english should not be empty');
      }
    });
    
    test('should convert to display string correctly', () {
      // Given
      final mood = Mood.happy;
      
      // When
      final displayString = '${mood.emoji} ${mood.korean}';
      
      // Then
      expect(displayString, equals('😊 기쁨'));
    });
  });
}