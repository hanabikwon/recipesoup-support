import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 필수 필드를 나타내는 뱃지 위젯
/// 주황색 타원형 배경에 "필수" 텍스트를 표시합니다.
class RequiredBadge extends StatelessWidget {
  /// 뱃지 텍스트 (기본값: "필수")
  final String text;
  
  /// 뱃지 크기 조정 (기본값: 1.0)
  final double scale;
  
  /// 배경색 커스터마이징 (기본값: AppTheme.accentOrange)
  final Color? backgroundColor;
  
  /// 텍스트 색상 커스터마이징 (기본값: AppTheme.accentOrange)
  final Color? textColor;

  const RequiredBadge({
    super.key,
    this.text = '필수',
    this.scale = 1.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.accentOrange;
    final txtColor = textColor ?? Colors.white;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 3 * scale,
      ),
      decoration: BoxDecoration(
        color: bgColor, // 완전 불투명한 배경
        borderRadius: BorderRadius.circular(12 * scale), // 타원형을 위한 높은 radius
        border: Border.all(
          color: bgColor.withValues(alpha: 204), // 80% 투명도 테두리
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          color: txtColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// 필수 필드 라벨과 뱃지를 함께 표시하는 헬퍼 위젯
class LabelWithRequiredBadge extends StatelessWidget {
  /// 라벨 텍스트
  final String label;
  
  /// 라벨 스타일
  final TextStyle? labelStyle;
  
  /// 뱃지 커스터마이징
  final String? badgeText;
  final double badgeScale;
  final Color? badgeBackgroundColor;
  final Color? badgeTextColor;
  
  /// 라벨과 뱃지 사이의 간격 (기본값: 6.0)
  final double spacing;

  const LabelWithRequiredBadge({
    super.key,
    required this.label,
    this.labelStyle,
    this.badgeText,
    this.badgeScale = 1.0,
    this.badgeBackgroundColor,
    this.badgeTextColor,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final defaultLabelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    );

    return Row(
      children: [
        Text(
          label,
          style: labelStyle ?? defaultLabelStyle,
        ),
        SizedBox(width: spacing),
        RequiredBadge(
          text: badgeText ?? '필수',
          scale: badgeScale,
          backgroundColor: badgeBackgroundColor,
          textColor: badgeTextColor,
        ),
      ],
    );
  }
}