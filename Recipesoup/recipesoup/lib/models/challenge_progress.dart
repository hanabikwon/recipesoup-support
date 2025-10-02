/// 사용자의 챌린지 진행 상황 추적 모델
/// Hive에 저장되어 로컬에서 사용자의 챌린지 완료 기록 관리
class ChallengeProgress {
  /// 챌린지 ID
  final String challengeId;
  
  /// 챌린지 상태
  final ChallengeStatus status;
  
  /// 챌린지 시작 날짜
  final DateTime? startedAt;
  
  /// 챌린지 완료 날짜
  final DateTime? completedAt;
  
  /// 사용자가 작성한 도전 메모/후기
  final String? userNote;
  
  /// 사용자가 업로드한 완성 사진 경로
  final String? userImagePath;
  
  /// 사용자 평점 (1-5점)
  final int? userRating;

  /// 챌린지 시도 횟수
  final int attemptCount;
  
  /// 현재 진행 단계 (진행 중일 때만 사용)
  final int? currentStep;

  ChallengeProgress({
    required this.challengeId,
    this.status = ChallengeStatus.notStarted,
    this.startedAt,
    this.completedAt,
    this.userNote,
    this.userImagePath,
    this.userRating,
    this.attemptCount = 0,
    this.currentStep,
  });

  /// JSON에서 ChallengeProgress 객체 생성
  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      challengeId: json['challenge_id'] as String,
      status: ChallengeStatus.fromString(json['status'] as String? ?? 'not_started'),
      startedAt: json['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['started_at'] as int)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completed_at'] as int)
          : null,
      userNote: json['user_note'] as String?,
      userImagePath: json['user_image_path'] as String?,
      userRating: json['user_rating'] as int?,
      attemptCount: json['attempt_count'] as int? ?? 0,
      currentStep: json['current_step'] as int?,
    );
  }

  /// ChallengeProgress 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'status': status.value,
      'started_at': startedAt?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'user_note': userNote,
      'user_image_path': userImagePath,
      'user_rating': userRating,
      'attempt_count': attemptCount,
      'current_step': currentStep,
    };
  }

  /// 챌린지 시작
  ChallengeProgress start() {
    return copyWith(
      status: ChallengeStatus.inProgress,
      startedAt: DateTime.now(),
      attemptCount: attemptCount + 1,
    );
  }

  /// 챌린지 완료
  ChallengeProgress complete({
    String? userNote,
    String? userImagePath,
    int? userRating,
  }) {
    return copyWith(
      status: ChallengeStatus.completed,
      completedAt: DateTime.now(),
      userNote: userNote,
      userImagePath: userImagePath,
      userRating: userRating,
    );
  }

  /// 챌린지 포기
  ChallengeProgress abandon() {
    return copyWith(
      status: ChallengeStatus.abandoned,
    );
  }

  /// 챌린지 재시작
  ChallengeProgress restart() {
    return copyWith(
      status: ChallengeStatus.inProgress,
      startedAt: DateTime.now(),
      attemptCount: attemptCount + 1,
      userNote: null,
      userImagePath: null,
      userRating: null,
    );
  }

  /// 완료 여부
  bool get isCompleted => status == ChallengeStatus.completed;

  /// 진행 중 여부
  bool get isInProgress => status == ChallengeStatus.inProgress;
  
  /// 시작됨 여부 (진행 중이거나 완료된 경우)
  bool get isStarted => status == ChallengeStatus.inProgress || status == ChallengeStatus.completed;

  /// 시작하지 않음
  bool get isNotStarted => status == ChallengeStatus.notStarted;

  /// 소요 시간 계산 (완료된 경우에만)
  Duration? get completionDuration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  /// copyWith 메서드
  ChallengeProgress copyWith({
    String? challengeId,
    ChallengeStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? userNote,
    String? userImagePath,
    int? userRating,
    int? attemptCount,
    int? currentStep,
  }) {
    return ChallengeProgress(
      challengeId: challengeId ?? this.challengeId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userNote: userNote ?? this.userNote,
      userImagePath: userImagePath ?? this.userImagePath,
      userRating: userRating ?? this.userRating,
      attemptCount: attemptCount ?? this.attemptCount,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeProgress &&
      runtimeType == other.runtimeType &&
      challengeId == other.challengeId;

  @override
  int get hashCode => challengeId.hashCode;

  @override
  String toString() {
    return 'ChallengeProgress{challengeId: $challengeId, status: ${status.value}}';
  }
}

/// 챌린지 진행 상태
enum ChallengeStatus {
  notStarted('not_started', '시작 전', '🔒'),
  inProgress('in_progress', '진행 중', '⏳'),
  completed('completed', '완료', '✅'),
  abandoned('abandoned', '포기', '❌');

  const ChallengeStatus(this.value, this.displayName, this.emoji);

  final String value;
  final String displayName;
  final String emoji;

  static ChallengeStatus fromString(String value) {
    for (var status in ChallengeStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return ChallengeStatus.notStarted;
  }
}