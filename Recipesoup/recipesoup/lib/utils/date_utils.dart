class RecipeDateUtils {
  /// "과거 오늘" 기능 - 같은 월/일이지만 다른 년도인지 확인
  static bool isPastToday(DateTime recipeDate, DateTime baseDate) {
    return recipeDate.month == baseDate.month &&
        recipeDate.day == baseDate.day &&
        recipeDate.year != baseDate.year;
  }

  /// 몇 년 전인지 계산
  static int getYearsAgo(DateTime pastDate, DateTime currentDate) {
    return currentDate.year - pastDate.year;
  }

  /// "과거 오늘" 메시지 포맷팅
  static String formatPastTodayMessage(DateTime pastDate, DateTime currentDate) {
    final yearsAgo = getYearsAgo(pastDate, currentDate);
    return '$yearsAgo년 전 오늘';
  }

  /// 상대 시간 표시 (한국어)
  static String formatRelativeTime(DateTime dateTime, DateTime baseDate) {
    final difference = baseDate.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return '방금 전';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks주 전';
    }

    final months = (difference.inDays / 30).floor();
    return '$months달 전';
  }

  /// 한국어 날짜 포맷팅
  static String formatKoreanDate(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  /// 한국어 날짜 및 시간 포맷팅
  static String formatKoreanDateTime(DateTime dateTime) {
    final koreanDate = formatKoreanDate(dateTime);
    final koreanTime = formatKoreanTime(dateTime);
    return '$koreanDate $koreanTime';
  }

  /// 한국어 시간 포맷팅 (오전/오후)
  static String formatKoreanTime(DateTime dateTime) {
    final hour24 = dateTime.hour;
    final minute = dateTime.minute;

    String period;
    int hour12;

    if (hour24 == 0) {
      period = '오전';
      hour12 = 12;
    } else if (hour24 < 12) {
      period = '오전';
      hour12 = hour24;
    } else if (hour24 == 12) {
      period = '오후';
      hour12 = 12;
    } else {
      period = '오후';
      hour12 = hour24 - 12;
    }

    final minuteStr = minute.toString().padLeft(2, '0');
    return '$period $hour12:$minuteStr';
  }

  /// 한국어 요일 반환
  String getKoreanDayOfWeek(DateTime dateTime) {
    const dayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return dayNames[dateTime.weekday - 1];
  }

  /// 오늘인지 확인
  bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// 이번 주인지 확인
  bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(Duration(days: 7));
    
    return dateTime.isAfter(startOfWeek.subtract(Duration(seconds: 1))) &&
        dateTime.isBefore(endOfWeek);
  }

  /// 하루 시작 시점 반환 (00:00:00.000)
  DateTime getStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// 주 시작 시점 반환 (일요일 기준)
  DateTime getStartOfWeek(DateTime dateTime) {
    final startOfDay = getStartOfDay(dateTime);
    final daysFromSunday = dateTime.weekday % 7; // 일요일을 0으로 만듦
    return startOfDay.subtract(Duration(days: daysFromSunday));
  }

  /// 월 시작 시점 반환
  DateTime getStartOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// 날짜가 범위 내에 있는지 확인
  bool isDateInRange(DateTime date, DateTime startDate, DateTime endDate) {
    return date.isAfter(startDate.subtract(Duration(seconds: 1))) &&
        date.isBefore(endDate.add(Duration(seconds: 1)));
  }

  /// 두 날짜 사이의 일수 계산
  int getDaysBetween(DateTime startDate, DateTime endDate) {
    final start = getStartOfDay(startDate);
    final end = getStartOfDay(endDate);
    return end.difference(start).inDays.abs();
  }

  /// 날짜 범위 생성 (시작일부터 종료일까지 하루씩)
  List<DateTime> getDateRange(DateTime startDate, DateTime endDate) {
    final start = getStartOfDay(startDate);
    final end = getStartOfDay(endDate);
    final days = getDaysBetween(start, end);
    
    List<DateTime> dateRange = [];
    for (int i = 0; i <= days; i++) {
      dateRange.add(start.add(Duration(days: i)));
    }
    
    return dateRange;
  }

  /// 윤년인지 확인
  bool isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
  }
}