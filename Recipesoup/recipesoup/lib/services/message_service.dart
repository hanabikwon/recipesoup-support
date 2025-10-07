import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_message.dart';

class MessageService {
  static const String _messagesAssetPath = 'assets/data/announcements.json';

  /// JSON 파일에서 메시지 목록 로드
  Future<List<AppMessage>> loadMessages() async {
    try {
      // assets에서 JSON 파일 읽기
      final String jsonString = await rootBundle.loadString(_messagesAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // messages 배열 파싱
      final List<dynamic> messagesJson = jsonData['messages'] as List<dynamic>;

      final List<AppMessage> messages = messagesJson
          .map((messageJson) => AppMessage.fromJson(messageJson as Map<String, dynamic>))
          .toList();

      // 날짜 기준 내림차순 정렬 (최신순)
      messages.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

      return messages;
    } catch (e) {
      throw MessageServiceException('메시지 로드 실패: $e');
    }
  }

  /// 특정 타입의 메시지만 로드
  Future<List<AppMessage>> loadMessagesByType(String type) async {
    final allMessages = await loadMessages();
    return allMessages.where((message) => message.type == type).toList();
  }

  /// JSON 파일의 버전 정보 가져오기
  Future<String> getMessagesVersion() async {
    try {
      final String jsonString = await rootBundle.loadString(_messagesAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData['version'] as String? ?? '1.0.0';
    } catch (e) {
      return '1.0.0'; // 기본 버전
    }
  }

  /// 마지막 업데이트 날짜 가져오기
  Future<String> getLastUpdated() async {
    try {
      final String jsonString = await rootBundle.loadString(_messagesAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData['last_updated'] as String? ?? '';
    } catch (e) {
      return ''; // 업데이트 날짜 없음
    }
  }

  /// 메시지 개수 가져오기
  Future<int> getMessageCount() async {
    try {
      final messages = await loadMessages();
      return messages.length;
    } catch (e) {
      return 0;
    }
  }

  /// 특정 날짜 이후의 메시지만 가져오기
  Future<List<AppMessage>> loadMessagesAfterDate(DateTime date) async {
    final allMessages = await loadMessages();
    return allMessages.where((message) => DateTime.parse(message.date).isAfter(date)).toList();
  }

  /// 특정 ID의 메시지 찾기
  Future<AppMessage?> findMessageById(String messageId) async {
    try {
      final allMessages = await loadMessages();
      return allMessages.firstWhere((message) => message.id == messageId);
    } catch (e) {
      return null; // 메시지를 찾을 수 없음
    }
  }

  /// JSON 파일이 유효한지 검증
  Future<bool> validateJsonFile() async {
    try {
      await loadMessages();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 개발/테스트용: 샘플 메시지 생성
  AppMessage createSampleMessage({
    String? id,
    String? title,
    String? content,
    String type = 'announcement',
  }) {
    final now = DateTime.now();
    return AppMessage(
      id: id ?? 'sample_${now.millisecondsSinceEpoch}',
      type: type,
      title: title ?? '샘플 메시지',
      preview: content?.substring(0, 50) ?? '샘플 메시지 미리보기입니다.',
      content: content ?? '샘플 메시지 내용입니다.\n\n실제 메시지는 여기에 표시됩니다.',
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
  }
}

/// MessageService 전용 예외 클래스
class MessageServiceException implements Exception {
  final String message;

  const MessageServiceException(this.message);

  @override
  String toString() => 'MessageServiceException: $message';
}