import 'package:flutter/material.dart';

/// 빈티지 아이보리 색상 시스템
/// DESIGN.md를 기반으로 정의된 감성적인 테마 색상들

class AppTheme {
  // Primary Colors - 연한 올리브 계열
  static const primaryColor = Color(0xFF8B9A6B);        // 연한 올리브 그린
  static const primaryLight = Color(0xFFB3C199);        // 밝은 올리브
  static const primaryDark = Color(0xFF6B7A4B);         // 진한 올리브

  // Secondary Colors - 빈티지 브라운 계열  
  static const secondaryColor = Color(0xFFA0826D);      // 웜 브라운
  static const secondaryLight = Color(0xFFD4B8A3);      // 연한 브라운
  static const secondaryDark = Color(0xFF7A5A42);       // 진한 브라운

  // Background Colors - 아이보리 & 크림
  static const backgroundColor = Color(0xFFFAF8F3);     // 아이보리 백그라운드
  static const surfaceColor = Color(0xFFFFFEFB);       // 카드 표면 (밝은 아이보리)
  static const cardColor = Color(0xFFF8F6F1);          // 카드 배경 (따뜻한 아이보리)

  // Text Colors
  static const textPrimary = Color(0xFF2E3D1F);        // 다크 올리브 (메인 텍스트)
  static const textSecondary = Color(0xFF5A6B49);      // 미드 올리브 (보조 텍스트)
  static const textTertiary = Color(0xFF8B9A6B);       // 연한 올리브 (힌트 텍스트)

  // Accent Colors - 빈티지 감성
  static const accentOrange = Color(0xFFD2A45B);       // 빈티지 오렌지 (강조)
  static const accentRed = Color(0xFFB5704F);          // 빈티지 레드 (토마토)
  static const accentGreen = Color(0xFF7A9B5C);        // 허브 그린

  // FAB Menu Colors - 빈티지 채소/과일 테마
  static const fabQuickRecipe = Color(0xFFD2A45B);     // 호박/당근 오렌지
  static const fabFridge = Color(0xFF7A9B5C);          // 허브/상추 그린
  static const fabLink = Color(0xFF9B8B7E);            // 가지/버섯 브라운
  static const fabPhoto = Color(0xFFB5704F);           // 토마토 레드
  static const fabCustom = Color(0xFFC9A86A);          // 밀/곡물 베이지

  // Status Colors
  static const successColor = Color(0xFF7A9B5C);       // 허브 그린
  static const warningColor = Color(0xFFD2A45B);       // 빈티지 오렌지
  static const errorColor = Color(0xFFB5704F);         // 빈티지 레드
  static const infoColor = Color(0xFF8B9A6B);          // 연한 올리브

  // Special Colors
  static const fabColor = Color(0xFFD2A45B);           // FAB 색상 (빈티지 오렌지)
  static const dividerColor = Color(0xFFE8E3D8);       // 연한 베이지 구분선
  static const disabledColor = Color(0xFFB8C2A7);      // 비활성화 상태
  static const shadowColor = Color(0x1A2E3D1F);        // 그림자 색상 (10% opacity)

  // Spacing Scale
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Padding & Margin
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXL = 24.0;

  // Elevation
  static const double elevationCard = 2.0;
  static const double elevationFab = 6.0;
  static const double elevationDialog = 8.0;
  static const double elevationBottomSheet = 12.0;

  /// 빈티지 아이보리 테마 생성
  static ThemeData get vintageIvoryTheme {
    return ThemeData(
      useMaterial3: true,
      
      // 색상 체계
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: textPrimary,
      ),

      // 텍스트 테마
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      ),

      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // 카드 테마
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
        margin: EdgeInsets.all(marginSmall),
      ),

      // 승격된 버튼 테마 (Primary 버튼)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationCard,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 외곽선 버튼 테마 (Secondary 버튼)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingMedium,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingMedium,
            vertical: paddingSmall,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingMedium,
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textTertiary),
      ),

      // FAB 테마
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: fabColor,
        foregroundColor: Colors.white,
        elevation: elevationFab,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusLarge)),
        ),
      ),

      // 구분선 테마
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1.0,
        space: spacing16,
      ),

      // 체크박스 테마
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),

      // 라디오 버튼 테마
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),

      // 스위치 테마
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return null;
        }),
      ),

      // 슬라이더 테마
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryLight,
        thumbColor: primaryColor,
      ),

      // BottomNavigationBar 테마
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        elevation: elevationCard,
        type: BottomNavigationBarType.fixed,
      ),

      // 스낵바 테마
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusSmall)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationCard,
      ),

      // 다이얼로그 테마
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusLarge)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: textSecondary,
        ),
      ),
    );
  }

  /// 감정별 색상 매핑 (감정 기반 앱 특화)
  static const Map<String, Color> emotionColors = {
    'happy': Color(0xFFE8B4B8),      // 기쁨 - 소프트 핑크
    'peaceful': accentGreen,         // 평온 - 허브 그린
    'sad': Color(0xFFB8A9C9),        // 슬픔 - 라벤더 그레이
    'tired': Color(0xFF9B9B9B),      // 피로 - 쿨 그레이
    'excited': accentOrange,         // 설렘 - 밝은 오렌지
    'nostalgic': secondaryColor,     // 그리움 - 따뜻한 브라운
    'comfortable': Color(0xFFABC4D6), // 편안함 - 소프트 블루
    'grateful': Color(0xFFEAD896),   // 감사 - 소프트 옐로우
  };

  /// 감정별 이모지 매핑
  static const Map<String, String> emotionEmojis = {
    'happy': '😊',
    'peaceful': '😌', 
    'sad': '😢',
    'tired': '😴',
    'excited': '🤩',
    'nostalgic': '🥺',
    'comfortable': '☺️',
    'grateful': '🙏',
  };

  /// 빈티지 테마 그라디언트 (특별한 배경용)
  static const LinearGradient vintageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundColor,
      surfaceColor,
    ],
  );

  /// 카드 그림자 (완전 제거 - 플랫 디자인)
  static const List<BoxShadow> vintageShadow = [];

  /// FAB 그림자 (강조된 그림자)
  static const List<BoxShadow> fabShadow = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}