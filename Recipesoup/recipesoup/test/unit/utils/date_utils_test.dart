import 'package:flutter_test/flutter_test.dart';
import 'package:recipesoup/utils/date_utils.dart';

void main() {
  group('DateUtils Tests ("과거 오늘" 핵심 기능!)', () {
    late RecipeDateUtils dateUtils;
    
    setUp(() {
      dateUtils = RecipeDateUtils();
    });
    
    group('"과거 오늘" 기능 테스트', () {
      test('should detect same month and day from different years', () {
        // Given - 기준 날짜 (2024년 12월 15일)
        final baseDate = DateTime(2024, 12, 15, 14, 30);
        
        // 같은 월/일, 다른 년도들
        final lastYear = DateTime(2023, 12, 15, 18, 0);
        final twoYearsAgo = DateTime(2022, 12, 15, 9, 30);
        final differentDay = DateTime(2023, 12, 16, 18, 0);
        final sameYear = DateTime(2024, 12, 15, 10, 0);
        
        // When & Then
        expect(RecipeDateUtils.isPastToday(lastYear, baseDate), isTrue);
        expect(RecipeDateUtils.isPastToday(twoYearsAgo, baseDate), isTrue);
        expect(RecipeDateUtils.isPastToday(differentDay, baseDate), isFalse);
        expect(RecipeDateUtils.isPastToday(sameYear, baseDate), isFalse);
      });
      
      test('should get years ago count', () {
        // Given
        final today = DateTime(2024, 12, 15);
        final lastYear = DateTime(2023, 12, 15);
        final twoYearsAgo = DateTime(2022, 12, 15);
        
        // When & Then
        expect(RecipeDateUtils.getYearsAgo(lastYear, today), equals(1));
        expect(RecipeDateUtils.getYearsAgo(twoYearsAgo, today), equals(2));
        expect(RecipeDateUtils.getYearsAgo(today, today), equals(0));
      });
      
      test('should format past today messages', () {
        // Given
        final today = DateTime(2024, 12, 15);
        final lastYear = DateTime(2023, 12, 15, 19, 30);
        final twoYearsAgo = DateTime(2022, 12, 15, 14, 0);
        
        // When & Then
        expect(RecipeDateUtils.formatPastTodayMessage(lastYear, today), 
               equals('1년 전 오늘'));
        expect(RecipeDateUtils.formatPastTodayMessage(twoYearsAgo, today), 
               equals('2년 전 오늘'));
      });
    });
    
    group('상대 시간 표시 테스트', () {
      test('should format relative time in Korean', () {
        final now = DateTime(2024, 12, 15, 15, 0, 0);
        
        // Given - 다양한 시간차
        final fiveMinutesAgo = now.subtract(Duration(minutes: 5));
        final twoHoursAgo = now.subtract(Duration(hours: 2));
        final yesterday = now.subtract(Duration(days: 1));
        final lastWeek = now.subtract(Duration(days: 7));
        final lastMonth = now.subtract(Duration(days: 30));
        
        // When & Then
        expect(RecipeDateUtils.formatRelativeTime(fiveMinutesAgo, now), 
               equals('5분 전'));
        expect(RecipeDateUtils.formatRelativeTime(twoHoursAgo, now), 
               equals('2시간 전'));
        expect(RecipeDateUtils.formatRelativeTime(yesterday, now), 
               equals('1일 전'));
        expect(RecipeDateUtils.formatRelativeTime(lastWeek, now), 
               equals('1주 전'));
        expect(RecipeDateUtils.formatRelativeTime(lastMonth, now), 
               equals('1달 전'));
      });
      
      test('should handle just now case', () {
        final now = DateTime(2024, 12, 15, 15, 0, 0);
        final justNow = now.subtract(Duration(seconds: 30));
        
        expect(RecipeDateUtils.formatRelativeTime(justNow, now), 
               equals('방금 전'));
      });
      
      test('should handle future dates', () {
        final now = DateTime(2024, 12, 15, 15, 0, 0);
        final future = now.add(Duration(hours: 1));
        
        expect(RecipeDateUtils.formatRelativeTime(future, now), 
               equals('방금 전')); // 미래 시간은 "방금 전"으로 처리
      });
    });
    
    group('한국어 날짜 포맷팅 테스트', () {
      test('should format date in Korean style', () {
        final testDate = DateTime(2024, 12, 15, 14, 30, 45);
        
        // When & Then
        expect(RecipeDateUtils.formatKoreanDate(testDate), 
               equals('2024년 12월 15일'));
        expect(RecipeDateUtils.formatKoreanDateTime(testDate), 
               equals('2024년 12월 15일 오후 2:30'));
        expect(RecipeDateUtils.formatKoreanTime(testDate), 
               equals('오후 2:30'));
      });
      
      test('should format AM/PM correctly in Korean', () {
        final morning = DateTime(2024, 12, 15, 9, 30);
        final afternoon = DateTime(2024, 12, 15, 15, 45);
        final midnight = DateTime(2024, 12, 15, 0, 0);
        final noon = DateTime(2024, 12, 15, 12, 0);
        
        expect(RecipeDateUtils.formatKoreanTime(morning), 
               equals('오전 9:30'));
        expect(RecipeDateUtils.formatKoreanTime(afternoon), 
               equals('오후 3:45'));
        expect(RecipeDateUtils.formatKoreanTime(midnight), 
               equals('오전 12:00'));
        expect(RecipeDateUtils.formatKoreanTime(noon), 
               equals('오후 12:00'));
      });
    });
    
    group('요일 및 달력 기능 테스트', () {
      test('should return Korean day of week', () {
        // 2024년 12월 15일은 일요일
        final sunday = DateTime(2024, 12, 15);
        final monday = DateTime(2024, 12, 16);
        final saturday = DateTime(2024, 12, 21);
        
        expect(dateUtils.getKoreanDayOfWeek(sunday), equals('일요일'));
        expect(dateUtils.getKoreanDayOfWeek(monday), equals('월요일'));
        expect(dateUtils.getKoreanDayOfWeek(saturday), equals('토요일'));
      });
      
      test('should check if date is today', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 10, 0);
        final yesterday = now.subtract(Duration(days: 1));
        
        expect(dateUtils.isToday(today), isTrue);
        expect(dateUtils.isToday(yesterday), isFalse);
      });
      
      test('should check if date is this week', () {
        final now = DateTime.now();
        final thisWeek = now.subtract(Duration(days: 3));
        final lastWeek = now.subtract(Duration(days: 8));
        
        expect(dateUtils.isThisWeek(thisWeek), isTrue);
        expect(dateUtils.isThisWeek(lastWeek), isFalse);
      });
    });
    
    group('요리 패턴 분석용 날짜 기능 테스트', () {
      test('should get start of day', () {
        final testDate = DateTime(2024, 12, 15, 14, 30, 45, 123);
        final startOfDay = dateUtils.getStartOfDay(testDate);
        
        expect(startOfDay.year, equals(2024));
        expect(startOfDay.month, equals(12));
        expect(startOfDay.day, equals(15));
        expect(startOfDay.hour, equals(0));
        expect(startOfDay.minute, equals(0));
        expect(startOfDay.second, equals(0));
        expect(startOfDay.millisecond, equals(0));
      });
      
      test('should get start of week', () {
        // 2024년 12월 15일 (일요일)
        final sunday = DateTime(2024, 12, 15);
        final startOfWeek = dateUtils.getStartOfWeek(sunday);
        
        // 한국 기준: 일요일이 주의 시작
        expect(startOfWeek.day, equals(15));
        expect(startOfWeek.hour, equals(0));
        expect(startOfWeek.minute, equals(0));
      });
      
      test('should get start of month', () {
        final testDate = DateTime(2024, 12, 15, 14, 30);
        final startOfMonth = dateUtils.getStartOfMonth(testDate);
        
        expect(startOfMonth.year, equals(2024));
        expect(startOfMonth.month, equals(12));
        expect(startOfMonth.day, equals(1));
        expect(startOfMonth.hour, equals(0));
        expect(startOfMonth.minute, equals(0));
      });
    });
    
    group('날짜 범위 및 필터링 테스트', () {
      test('should check if date is within range', () {
        final start = DateTime(2024, 12, 1);
        final end = DateTime(2024, 12, 31);
        final withinRange = DateTime(2024, 12, 15);
        final outsideRange = DateTime(2025, 1, 5);
        
        expect(dateUtils.isDateInRange(withinRange, start, end), isTrue);
        expect(dateUtils.isDateInRange(outsideRange, start, end), isFalse);
      });
      
      test('should get days between dates', () {
        final start = DateTime(2024, 12, 1);
        final end = DateTime(2024, 12, 15);
        
        expect(dateUtils.getDaysBetween(start, end), equals(14));
        expect(dateUtils.getDaysBetween(end, start), equals(14)); // 절댓값
      });
      
      test('should generate date range', () {
        final start = DateTime(2024, 12, 1);
        final end = DateTime(2024, 12, 3);
        final range = dateUtils.getDateRange(start, end);
        
        expect(range, hasLength(3));
        expect(range[0].day, equals(1));
        expect(range[1].day, equals(2));
        expect(range[2].day, equals(3));
      });
    });
    
    group('특별한 날짜 처리 테스트', () {
      test('should handle leap year correctly', () {
        final leapYear = DateTime(2024, 2, 29);
        
        expect(dateUtils.isLeapYear(2024), isTrue);
        expect(dateUtils.isLeapYear(2023), isFalse);
        expect(RecipeDateUtils.formatKoreanDate(leapYear), 
               equals('2024년 2월 29일'));
      });
      
      test('should handle year boundaries', () {
        final newYear = DateTime(2024, 1, 1, 0, 0, 1);
        final lastYear = DateTime(2023, 12, 31, 23, 59, 59);
        
        expect(RecipeDateUtils.getYearsAgo(lastYear, newYear), equals(1));
        expect(RecipeDateUtils.formatRelativeTime(lastYear, newYear), 
               equals('방금 전')); // 2초 차이는 방금 전
      });
    });
  });
}