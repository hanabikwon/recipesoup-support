import 'package:flutter/material.dart';
import '../../models/app_message.dart';

class MessageItem extends StatelessWidget {
  final AppMessage message;
  final bool isRead;
  final VoidCallback? onTap;

  const MessageItem({
    super.key,
    required this.message,
    required this.isRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead
            ? const Color(0xFFF5F3EE) // 읽은 메시지: 약간 더 어두운 아이보리
            : const Color(0xFFFFFFFF), // 안읽은 메시지: 흰색
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E3D8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B9A6B).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 레드닷 또는 읽음 상태 표시
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.transparent
                        : const Color(0xFFB5704F), // 빈티지 레드
                    shape: BoxShape.circle,
                  ),
                ),
                // 메시지 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        message.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: const Color(0xFF2E3D1F), // 다크 올리브
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 미리보기 텍스트
                      Text(
                        message.preview,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF5A6B49).withValues(alpha: 0.8), // 미드 올리브
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // 날짜
                      Text(
                        message.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B9A6B), // 연한 올리브
                        ),
                      ),
                    ],
                  ),
                ),
                // 화살표 아이콘
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8B9A6B), // 연한 올리브
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}