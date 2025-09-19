import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_message.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  List<AppMessage> _messages = [];
  Set<String> _readMessageIds = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppMessage> get messages => _messages;
  Set<String> get readMessageIds => _readMessageIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 안읽은 메시지 개수
  int get unreadCount => _messages.where((message) => !_readMessageIds.contains(message.id)).length;

  /// 레드닷 표시 여부 (안읽은 메시지가 있는가?)
  bool get hasUnreadMessages => unreadCount > 0;

  /// 메시지가 읽힌 상태인지 확인
  bool isMessageRead(String messageId) {
    return _readMessageIds.contains(messageId);
  }

  /// 안읽은 메시지들만 가져오기
  List<AppMessage> get unreadMessages => _messages.where((message) => !_readMessageIds.contains(message.id)).toList();

  /// 읽은 메시지들만 가져오기
  List<AppMessage> get readMessages => _messages.where((message) => _readMessageIds.contains(message.id)).toList();

  /// 초기화 - 앱 시작 시 호출
  Future<void> initialize() async {
    await _loadReadMessageIds();
    await loadMessages();
  }

  /// 메시지 목록 로드
  Future<void> loadMessages() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _messages = await _messageService.loadMessages();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '메시지를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 메시지를 읽음으로 표시
  Future<void> markAsRead(String messageId) async {
    if (_readMessageIds.contains(messageId)) return;

    _readMessageIds.add(messageId);
    await _saveReadMessageIds();
    notifyListeners();
  }

  /// 모든 메시지를 읽음으로 표시
  Future<void> markAllAsRead() async {
    final allIds = _messages.map((message) => message.id).toSet();
    _readMessageIds.addAll(allIds);
    await _saveReadMessageIds();
    notifyListeners();
  }

  /// 특정 메시지를 안읽음으로 표시 (관리자용)
  Future<void> markAsUnread(String messageId) async {
    _readMessageIds.remove(messageId);
    await _saveReadMessageIds();
    notifyListeners();
  }

  /// 읽음 상태 초기화 (개발/테스트용)
  Future<void> clearAllReadStatus() async {
    _readMessageIds.clear();
    await _saveReadMessageIds();
    notifyListeners();
  }

  /// SharedPreferences에서 읽음 상태 로드
  Future<void> _loadReadMessageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_message_ids') ?? [];
      _readMessageIds = readIds.toSet();
    } catch (e) {
      // SharedPreferences 로드 실패 시 빈 상태로 시작
      _readMessageIds = {};
    }
  }

  /// SharedPreferences에 읽음 상태 저장
  Future<void> _saveReadMessageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_message_ids', _readMessageIds.toList());
    } catch (e) {
      // 저장 실패 시 로그만 출력하고 계속 진행
      if (kDebugMode) {
        debugPrint('Failed to save read message IDs: $e');
      }
    }
  }

  /// 우선순위별 메시지 정렬
  List<AppMessage> get messagesSortedByPriority {
    final sortedMessages = List<AppMessage>.from(_messages);
    sortedMessages.sort((a, b) {
      // 우선순위: high > medium > low
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority = priorityOrder[a.priority] ?? 1;
      final bPriority = priorityOrder[b.priority] ?? 1;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // 우선순위가 같으면 날짜 기준 내림차순 (최신순)
      return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
    });
    return sortedMessages;
  }

  /// 타입별 메시지 가져오기
  List<AppMessage> getMessagesByType(String type) {
    return _messages.where((message) => message.type == type).toList();
  }

  /// 새로운 메시지 추가 (개발/테스트용)
  void addMessage(AppMessage message) {
    _messages.insert(0, message); // 최신 메시지를 맨 앞에 추가
    notifyListeners();
  }

  /// 에러 상태 클리어
  void clearError() {
    _error = null;
    notifyListeners();
  }
}