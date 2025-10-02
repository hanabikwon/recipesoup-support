import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 빈티지 아이보리 톤의 통일된 정보/에러 다이얼로그
///
/// Rate Limit, 에러, 경고 등 모든 중요 알림에서 일관된 디자인 제공
class VintageInfoDialog extends StatelessWidget {
  /// 다이얼로그 제목
  final String title;

  /// 메인 메시지 내용
  final String message;

  /// 정보 박스 내부 메시지 (선택사항)
  final String? infoBoxMessage;

  /// 정보 박스 아이콘 (선택사항, 기본값: Icons.info_outline)
  final IconData? infoBoxIcon;

  /// 확인 버튼 텍스트 (기본값: '확인')
  final String buttonText;

  /// 확인 버튼 클릭 시 콜백
  final VoidCallback? onConfirm;

  /// 제목 아이콘 (기본값: Icons.info_outline)
  final IconData titleIcon;

  /// 다이얼로그를 닫을 수 없게 설정 (barrierDismissible과 함께 사용)
  final bool showCloseButton;

  const VintageInfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.infoBoxMessage,
    this.infoBoxIcon,
    this.buttonText = '확인',
    this.onConfirm,
    this.titleIcon = Icons.info_outline,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      title: Row(
        children: [
          Icon(
            titleIcon,
            color: AppTheme.accentOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (infoBoxMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    infoBoxIcon ?? Icons.info_outline,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoBoxMessage!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Rate Limit 전용 팩토리 생성자
  factory VintageInfoDialog.rateLimit() {
    return const VintageInfoDialog(
      title: '잠시만 기다려주세요 🐰',
      message: '시간당 AI 분석 요청 한도를 초과했습니다.',
      infoBoxMessage: '시간당 최대 50회까지 분석 가능합니다',
      titleIcon: Icons.hourglass_empty,
      buttonText: '확인',
      showCloseButton: false,
    );
  }

  /// 네트워크 에러 전용 팩토리 생성자
  factory VintageInfoDialog.networkError({String? customMessage}) {
    return VintageInfoDialog(
      title: 'AI 분석 실패',
      message: customMessage ?? 'AI 분석 서비스에 연결할 수 없습니다.\n잠시 후 다시 시도해주세요.',
      infoBoxMessage: '네트워크 연결을 확인해주세요',
      infoBoxIcon: Icons.wifi_off_outlined,
      titleIcon: Icons.error_outline,
    );
  }

  /// URL 파싱 에러 전용 팩토리 생성자
  factory VintageInfoDialog.urlParsingError() {
    return const VintageInfoDialog(
      title: '레시피 추출 실패',
      message: '이 URL에서 레시피 정보를 찾을 수 없습니다.',
      infoBoxMessage: '레시피 블로그나 요리 사이트 링크를 입력해주세요',
      infoBoxIcon: Icons.link_off,
      titleIcon: Icons.error_outline,
    );
  }

  /// 일반 에러 전용 팩토리 생성자
  factory VintageInfoDialog.generalError({
    required String title,
    required String message,
    String? infoBoxMessage,
  }) {
    return VintageInfoDialog(
      title: title,
      message: message,
      infoBoxMessage: infoBoxMessage,
      titleIcon: Icons.error_outline,
    );
  }
}
