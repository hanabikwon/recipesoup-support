import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 빈티지 아이보리 톤의 인라인 정보 카드
///
/// VintageInfoDialog와 동일한 디자인 언어를 사용하며,
/// 다이얼로그가 아닌 화면 내 인라인 안내 메시지에 사용합니다.
class VintageInfoCard extends StatelessWidget {
  /// 카드 제목
  final String title;

  /// 메인 메시지 내용
  final String message;

  /// 제목 아이콘 (기본값: Icons.info_outline)
  final IconData titleIcon;

  /// 아이콘 색상 (기본값: AppTheme.accentOrange)
  final Color? iconColor;

  const VintageInfoCard({
    super.key,
    required this.title,
    required this.message,
    this.titleIcon = Icons.info_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, // 빈티지 아이보리 카드 배경
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              titleIcon,
              color: iconColor ?? AppTheme.accentOrange, // 빈티지 오렌지 아이콘
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
