import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../models/app_message.dart';
import 'message_item.dart';
import 'message_detail_dialog.dart';

class MessageBottomSheet extends StatefulWidget {
  const MessageBottomSheet({super.key});

  /// 바텀시트를 표시하는 정적 메서드
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MessageBottomSheet(),
    );
  }

  @override
  State<MessageBottomSheet> createState() => _MessageBottomSheetState();
}

class _MessageBottomSheetState extends State<MessageBottomSheet> {
  @override
  void initState() {
    super.initState();
    // 바텀시트가 열릴 때 메시지 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      if (messageProvider.messages.isEmpty) {
        messageProvider.loadMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F3), // 빈티지 아이보리 배경
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, messageProvider),
              _buildContent(messageProvider),
            ],
          ),
        );
      },
    );
  }

  /// 헤더 영역 (제목 + 닫기 버튼)
  Widget _buildHeader(BuildContext context, MessageProvider messageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E3D8), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications,
            color: Color(0xFF2E3D1F), // 다크 올리브
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            '메시지함',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3D1F), // 다크 올리브
            ),
          ),
          const Spacer(),
          if (messageProvider.hasUnreadMessages) ...[
            Text(
              '${messageProvider.unreadCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB5704F), // 빈티지 레드
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => messageProvider.markAllAsRead(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B9A6B), // 연한 올리브
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text(
                '모두 읽음 처리',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Color(0xFF5A6B49), // 미드 올리브
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 콘텐츠 영역 (메시지 리스트)
  Widget _buildContent(MessageProvider messageProvider) {
    return Expanded(
      child: _buildMessageList(messageProvider),
    );
  }

  /// 메시지 리스트
  Widget _buildMessageList(MessageProvider messageProvider) {
    if (messageProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B9A6B)),
        ),
      );
    }

    if (messageProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFB5704F), // 빈티지 레드
            ),
            const SizedBox(height: 16),
            Text(
              messageProvider.error!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5A6B49), // 미드 올리브
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => messageProvider.loadMessages(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B9A6B), // 연한 올리브
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (messageProvider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: const Color(0xFF8B9A6B).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '새로운 메시지가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF5A6B49).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // 날짜별로 정렬된 메시지 리스트 (최신순)
    final sortedMessages = messageProvider.messagesSortedByDate;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        final isRead = messageProvider.isMessageRead(message.id);


        return MessageItem(
          message: message,
          isRead: isRead,
          onTap: () => _onMessageTap(context, message, messageProvider),
        );
      },
    );
  }

  /// 메시지 아이템 클릭 처리
  void _onMessageTap(BuildContext context, AppMessage message, MessageProvider messageProvider) async {
    // 읽음 처리
    await messageProvider.markAsRead(message.id);

    // 상세 다이얼로그 표시
    if (context.mounted) {
      await _showMessageDetail(context, message);
    }
  }

  /// 메시지 상세 다이얼로그 표시
  Future<void> _showMessageDetail(BuildContext context, AppMessage message) async {
    await showDialog(
      context: context,
      builder: (context) => MessageDetailDialog(message: message),
    );
  }
}