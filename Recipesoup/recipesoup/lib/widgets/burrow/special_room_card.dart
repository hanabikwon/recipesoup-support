import 'package:flutter/material.dart';
import '../../models/burrow_milestone.dart';
import '../../utils/burrow_error_handler.dart';

/// 특별 공간 마일스톤 카드
/// 숨겨진 조건 기반 마일스톤 표시용
class SpecialRoomCard extends StatelessWidget {
  final BurrowMilestone milestone;
  final bool isUnlocked;
  final UnlockProgress? progress;
  final String? hint;
  final VoidCallback? onTap;

  const SpecialRoomCard({
    super.key,
    required this.milestone,
    required this.isUnlocked,
    this.progress,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 모든 애니메이션 효과 완전 제거
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isUnlocked 
                ? const Color(0xFFFFFEFB) 
                : const Color(0xFFF8F6F1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked 
                  ? _getRoomColor() 
                  : const Color(0xFFE8E3D8),
              width: isUnlocked ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUnlocked ? 26 : 13),
                blurRadius: isUnlocked ? 12 : 4,
                offset: Offset(0, isUnlocked ? 4 : 2),
              ),
            ],
          ),
        child: SizedBox(
          height: 140,
          child: Stack(
            children: [
              // 배경 그라디언트 (언락된 경우)
              if (isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _getRoomColor().withValues(alpha: 13),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              
              // 메인 콘텐츠
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 특별 공간 이미지
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFF8F6F1),
                        border: Border.all(
                          color: isUnlocked ? _getRoomColor() : const Color(0xFFE8E3D8),
                          width: isUnlocked ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildRoomImage(),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // 특별 공간 정보
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // 공간 타입과 상태
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnlocked 
                                      ? _getRoomColor() 
                                      : const Color(0xFF8B9A6B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getRoomIcon(),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isUnlocked ? '특별 공간' : '신비한 공간',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isUnlocked)
                                const Icon(
                                  Icons.stars,
                                  color: Color(0xFFD2A45B),
                                  size: 20,
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 공간 제목
                          Text(
                            isUnlocked ? milestone.title : '???',
                            style: TextStyle(
                              color: const Color(0xFF2E3D1F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: isUnlocked ? 0 : 2,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // 설명 또는 힌트 (심플하게)
                          Text(
                            isUnlocked ? milestone.description : (hint ?? '특별한 조건을 만족하면 열려요...'),
                            style: TextStyle(
                              color: const Color(0xFF5A6B49),
                              fontSize: 13,
                              fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // 진행도 표시 (잠긴 상태에서)
                          if (!isUnlocked && progress != null)
                            _buildProgressIndicator(),
                          
                          // 언락 시간 (언락된 경우)
                          if (isUnlocked && milestone.unlockedAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoomColor().withValues(alpha: 26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '오픈: ${_formatDate(milestone.unlockedAt!)}',
                                style: TextStyle(
                                  color: _getRoomColor(),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 화살표 또는 잠금 아이콘
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isUnlocked && onTap != null)
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _getRoomColor(),
                            size: 16,
                          )
                        else if (!isUnlocked)
                          Icon(
                            Icons.help_outline,
                            color: const Color(0xFF8B9A6B).withValues(alpha: 153),
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 반짝이 효과 (언락된 특별 공간)
              if (isUnlocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getRoomColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getRoomColor().withValues(alpha: 128),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 특별 공간 이미지 위젯 (에러 처리 강화)
  Widget _buildRoomImage() {
    if (isUnlocked) {
      // 언락된 상태: 안전한 이미지 표시
      return BurrowErrorHandler.safeAssetImage(
        milestone.imagePath,
        fit: BoxFit.cover,
        milestone: milestone,
      );
    } else {
      // 잠긴 상태: burrow_locked.png 직접 사용
      return Image.asset(
        'assets/images/burrow/special_rooms/burrow_locked.webp',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('🔥 SPECIAL ROOM LOCKED IMAGE ERROR: $error');
          // 개선된 잠긴 상태 플레이스홀더
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8E3D8),
                  const Color(0xFFD0C7B8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 26),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 격자 패턴
                CustomPaint(
                  painter: SimpleGridPainter(),
                  size: Size.infinite,
                ),
                // 중앙 아이콘
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B9A6B).withValues(alpha: 51),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: const Color(0xFF6B7A4B),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '???',
                      style: TextStyle(
                        color: const Color(0xFF6B7A4B),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }


  /// 진행도 표시기
  Widget _buildProgressIndicator() {
    if (progress == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline,
              color: const Color(0xFF8B9A6B),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              '진행도 ${(progress!.progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF8B9A6B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E3D8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress!.progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF8B9A6B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 특별 공간별 색상
  Color _getRoomColor() {
    if (milestone.specialRoom == null) return const Color(0xFF8B9A6B);
    
    switch (milestone.specialRoom!) {
      case SpecialRoom.ballroom:
        return const Color(0xFFE91E63); // 핑크 (사교)
      case SpecialRoom.hotSpring:
        return const Color(0xFF00BCD4); // 청록 (힐링)
      case SpecialRoom.orchestra:
        return const Color(0xFF9C27B0); // 퍼플 (음악)
      case SpecialRoom.alchemyLab:
        return const Color(0xFFFF9800); // 오렌지 (실험)
      case SpecialRoom.fineDining:
        return const Color(0xFFFFD700); // 골드 (완벽)
      
      // 새로 추가된 11개 특별 공간들
      case SpecialRoom.alps:
        return const Color(0xFF2196F3); // 블루 (알프스)
      case SpecialRoom.camping:
        return const Color(0xFF4CAF50); // 그린 (자연)
      case SpecialRoom.autumn:
        return const Color(0xFFFF5722); // 딥오렌지 (가을)
      case SpecialRoom.springPicnic:
        return const Color(0xFF8BC34A); // 라이트그린 (봄)
      case SpecialRoom.surfing:
        return const Color(0xFF00BCD4); // 사이안 (바다)
      case SpecialRoom.snorkel:
        return const Color(0xFF3F51B5); // 인디고 (바다탐험)
      case SpecialRoom.summerbeach:
        return const Color(0xFFFFC107); // 앰버 (여름해변)
      case SpecialRoom.baliYoga:
        return const Color(0xFF795548); // 브라운 (명상)
      case SpecialRoom.orientExpress:
        return const Color(0xFF9C27B0); // 퍼플 (여행)
      case SpecialRoom.canvas:
        return const Color(0xFFE91E63); // 핑크 (예술)
      case SpecialRoom.vacance:
        return const Color(0xFF607D8B); // 블루그레이 (휴양)
    }
  }

  /// 특별 공간별 아이콘
  IconData _getRoomIcon() {
    if (milestone.specialRoom == null) return Icons.room;
    
    switch (milestone.specialRoom!) {
      case SpecialRoom.ballroom:
        return Icons.celebration;
      case SpecialRoom.hotSpring:
        return Icons.hot_tub;
      case SpecialRoom.orchestra:
        return Icons.music_note;
      case SpecialRoom.alchemyLab:
        return Icons.science;
      case SpecialRoom.fineDining:
        return Icons.restaurant;
      
      // 새로 추가된 11개 특별 공간들의 아이콘
      case SpecialRoom.alps:
        return Icons.landscape; // 알프스 (산)
      case SpecialRoom.camping:
        return Icons.nature; // 캠핑 (자연)
      case SpecialRoom.autumn:
        return Icons.park; // 가을 (공원)
      case SpecialRoom.springPicnic:
        return Icons.grass; // 봄 피크닉 (풀밭)
      case SpecialRoom.surfing:
        return Icons.surfing; // 서핑
      case SpecialRoom.snorkel:
        return Icons.water; // 스노클링 (물)
      case SpecialRoom.summerbeach:
        return Icons.beach_access; // 여름 해변
      case SpecialRoom.baliYoga:
        return Icons.self_improvement; // 발리 요가 (명상)
      case SpecialRoom.orientExpress:
        return Icons.train; // 오리엔트 특급 (기차)
      case SpecialRoom.canvas:
        return Icons.palette; // 캔버스 (예술)
      case SpecialRoom.vacance:
        return Icons.beach_access; // 휴양 (해변)
    }
  }


  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 간단한 격자 패턴을 그리는 페인터
class SimpleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B9A6B).withValues(alpha: 20)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 간단한 격자 패턴
    final spacing = size.width / 8;
    for (int i = 1; i < 8; i++) {
      // 세로선
      canvas.drawLine(
        Offset(i * spacing, 0),
        Offset(i * spacing, size.height),
        paint,
      );
      // 가로선  
      canvas.drawLine(
        Offset(0, i * spacing),
        Offset(size.width, i * spacing),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}