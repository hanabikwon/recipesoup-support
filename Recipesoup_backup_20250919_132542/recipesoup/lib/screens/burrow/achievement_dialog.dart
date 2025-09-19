import 'package:flutter/material.dart';
import '../../models/burrow_milestone.dart';
import '../../utils/burrow_image_handler.dart';

/// 성취 언락 알림 다이얼로그
/// 마일스톤이 언락될 때 표시되는 축하 화면
class AchievementDialog extends StatefulWidget {
  final BurrowMilestone milestone;
  final DateTime unlockedAt;
  final String? triggerRecipeId;

  const AchievementDialog({
    super.key,
    required this.milestone,
    required this.unlockedAt,
    this.triggerRecipeId,
  });

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 스케일 애니메이션 (등장 효과)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 반짝이 애니메이션 (반복)
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // 애니메이션 시작
    _scaleController.forward();
    _sparkleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖼️ Building achievement dialog with image: ${widget.milestone.imagePath}');
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getMilestoneColor(),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getMilestoneColor().withValues(alpha: 77),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 배경 이미지 (800x1000 세로형 이미지)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FutureBuilder<BoxDecoration?>(
                    future: BurrowImageHandler.backgroundDecoration(
                      imagePath: widget.milestone.imagePath,
                      fit: BoxFit.cover,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Container(decoration: snapshot.data);
                      } else {
                        // 폴백 그라디언트 배경
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getMilestoneColor().withValues(alpha: 77),
                                _getMilestoneColor().withValues(alpha: 26),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              
              // 상단 그라디언트 오버레이 (닫기 버튼 영역)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 128),
                        Colors.black.withValues(alpha: 77),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // 하단 그라디언트 오버레이 (정보 영역)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 102),
                        Colors.black.withValues(alpha: 204),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // 콘텐츠
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상단 헤더 (축하 메시지)
                  _buildHeader(),
                  
                  // 마일스톤 정보
                  _buildMilestoneContent(),
                  
                  // 하단 액션 버튼
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 축하 헤더
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMilestoneColor().withValues(alpha: 26),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          // 반짝이 아이콘
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_sparkleAnimation.value * 0.2),
                child: Icon(
                  _getMilestoneIcon(),
                  size: 48,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4.0,
                      color: Colors.black.withValues(alpha: 128),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // 축하 메시지
          Text(
            widget.milestone.specialRoom != null ? '🎉 특별한 공간 발견!' : '🏆 새로운 성취!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            _getAchievementMessage(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 마일스톤 상세 정보
  Widget _buildMilestoneContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 마일스톤 이미지
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getMilestoneColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getMilestoneColor().withValues(alpha: 51),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildMilestoneImage(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 마일스톤 제목 (카드와 동일한 크기로 축소)
          Text(
            widget.milestone.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // 22 → 18로 축소 (카드와 동일)
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // 마일스톤 설명 (카드와 동일한 크기로 축소)
          Text(
            widget.milestone.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14, // 16 → 14로 축소 (카드와 동일)
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          // 달성 정보
          _buildUnlockInfo(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 달성 정보 위젯
  Widget _buildUnlockInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E3D8),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 달성 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                color: _getMilestoneColor(),
                size: 16,
              ),
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '달성일: ',
                      style: TextStyle(
                        color: _getMilestoneColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: _formatDateTime(widget.unlockedAt),
                      style: TextStyle(
                        color: _getMilestoneColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 특별 공간인 경우 추가 정보
          if (widget.milestone.specialRoom != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getMilestoneColor().withValues(alpha: 26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getSpecialRoomMessage(),
                style: TextStyle(
                  color: _getMilestoneColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          // 마일스톤 레벨 정보 (일반 성장 트랙)
          if (widget.milestone.specialRoom == null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: const Color(0xFFD2A45B),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Lv.${widget.milestone.level} 달성',
                  style: const TextStyle(
                    color: Color(0xFFD2A45B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 하단 액션 버튼들
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 토끼굴 보기 버튼
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _getMilestoneColor(),
                side: BorderSide(
                  color: _getMilestoneColor(),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // 토끼굴 화면으로 돌아가기 (이미 토끼굴 화면에서 호출됨)
              },
              child: Text(
                widget.milestone.specialRoom != null ? '특별 공간 보기' : '성장 기록 보기',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 확인 버튼
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getMilestoneColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// 마일스톤 이미지 위젯 (BurrowImageHandler 사용)
  Widget _buildMilestoneImage() {
    return BurrowImageHandler.safeImage(
      imagePath: widget.milestone.imagePath,
      milestone: widget.milestone,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
    );
  }

  /// 마일스톤별 색상 반환
  Color _getMilestoneColor() {
    if (widget.milestone.specialRoom != null) {
      switch (widget.milestone.specialRoom!) {
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
        // 새로 추가된 특별 공간들 (11개)
        case SpecialRoom.alps:
          return const Color(0xFF2196F3); // 파랑 (도전)
        case SpecialRoom.camping:
          return const Color(0xFF4CAF50); // 녹색 (자연)
        case SpecialRoom.autumn:
          return const Color(0xFFFF5722); // 주황 (가을)
        case SpecialRoom.springPicnic:
          return const Color(0xFF8BC34A); // 연녹 (봄)
        case SpecialRoom.surfing:
          return const Color(0xFF03DAC6); // 청록 (서핑)
        case SpecialRoom.snorkel:
          return const Color(0xFF006064); // 진청 (스노클링)
        case SpecialRoom.summerbeach:
          return const Color(0xFFFFC107); // 황금 (여름)
        case SpecialRoom.baliYoga:
          return const Color(0xFF673AB7); // 보라 (요가)
        case SpecialRoom.orientExpress:
          return const Color(0xFF795548); // 갈색 (여행)
        case SpecialRoom.canvas:
          return const Color(0xFFE91E63); // 분홍 (예술)
        case SpecialRoom.vacance:
          return const Color(0xFFFF9800); // 주황 (휴식)
      }
    } else {
      // 일반 성장 트랙
      return const Color(0xFF8B9A6B);
    }
  }

  /// 마일스톤별 아이콘 반환
  IconData _getMilestoneIcon() {
    if (widget.milestone.specialRoom != null) {
      switch (widget.milestone.specialRoom!) {
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
        // 새로 추가된 특별 공간들 (11개)
        case SpecialRoom.alps:
          return Icons.terrain;
        case SpecialRoom.camping:
          return Icons.nature;
        case SpecialRoom.autumn:
          return Icons.park;
        case SpecialRoom.springPicnic:
          return Icons.local_florist;
        case SpecialRoom.surfing:
          return Icons.surfing;
        case SpecialRoom.snorkel:
          return Icons.scuba_diving;
        case SpecialRoom.summerbeach:
          return Icons.beach_access;
        case SpecialRoom.baliYoga:
          return Icons.self_improvement;
        case SpecialRoom.orientExpress:
          return Icons.train;
        case SpecialRoom.canvas:
          return Icons.palette;
        case SpecialRoom.vacance:
          return Icons.beach_access;
      }
    } else {
      // 레벨별 아이콘
      switch (widget.milestone.level) {
        case 1:
          return Icons.home_outlined;
        case 2:
          return Icons.home;
        case 3:
          return Icons.home_work_outlined;
        case 4:
          return Icons.home_work;
        case 5:
          return Icons.account_balance;
        default:
          return Icons.star;
      }
    }
  }

  /// 성취 메시지 반환
  String _getAchievementMessage() {
    if (widget.milestone.specialRoom != null) {
      return '숨겨진 조건을 만족하여 특별한 공간을 발견했습니다!';
    } else {
      return '성장 여정에서 새로운 단계에 도달했습니다!';
    }
  }

  /// 특별 공간 메시지 반환
  String _getSpecialRoomMessage() {
    if (widget.milestone.specialRoom == null) return '';
    
    switch (widget.milestone.specialRoom!) {
      case SpecialRoom.ballroom:
        return '✨ 사교의 공간이 열렸습니다';
      case SpecialRoom.hotSpring:
        return '🌿 힐링의 공간이 열렸습니다';
      case SpecialRoom.orchestra:
        return '🎵 음악의 공간이 열렸습니다';
      case SpecialRoom.alchemyLab:
        return '⚗️ 실험의 공간이 열렸습니다';
      case SpecialRoom.fineDining:
        return '👑 완벽의 공간이 열렸습니다';
      // 새로 추가된 특별 공간들 (11개)
      case SpecialRoom.alps:
        return '🏔️ 도전의 공간이 열렸습니다';
      case SpecialRoom.camping:
        return '🏕️ 자연의 공간이 열렸습니다';
      case SpecialRoom.autumn:
        return '🍂 가을의 공간이 열렸습니다';
      case SpecialRoom.springPicnic:
        return '🌸 봄의 공간이 열렸습니다';
      case SpecialRoom.surfing:
        return '🏄 서핑의 공간이 열렸습니다';
      case SpecialRoom.snorkel:
        return '🤿 스노클링의 공간이 열렸습니다';
      case SpecialRoom.summerbeach:
        return '🏖️ 여름 해변의 공간이 열렸습니다';
      case SpecialRoom.baliYoga:
        return '🧘 명상의 공간이 열렸습니다';
      case SpecialRoom.orientExpress:
        return '🚂 여행의 공간이 열렸습니다';
      case SpecialRoom.canvas:
        return '🎨 예술의 공간이 열렸습니다';
      case SpecialRoom.vacance:
        return '🌴 휴식의 공간이 열렸습니다';
    }
  }

  /// 날짜 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}