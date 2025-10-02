class AppMessage {
  final String id;
  final String type;
  final String title;
  final String preview;
  final String content;
  final String date;

  const AppMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.preview,
    required this.content,
    required this.date,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) {
    return AppMessage(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      preview: json['preview'] as String,
      content: json['content'] as String,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'preview': preview,
      'content': content,
      'date': date,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppMessage(id: $id, title: $title, type: $type)';
  }
}

/// 메시지 타입 enum
enum MessageType {
  announcement('announcement'),
  feature('feature'),
  improvement('improvement'),
  guide('guide');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.announcement,
    );
  }
}

