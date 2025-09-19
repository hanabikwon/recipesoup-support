import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/burrow_milestone.dart';
import '../../providers/burrow_provider.dart';
import '../../utils/ultra_burrow_image_handler.dart';

/// Ultra 개선된 특별 공간 카드
/// burrow-fix-ver2.txt에서 계획된 테마 힌트 카피 구현
class UltraSpecialRoomCard extends StatelessWidget {
  final BurrowMilestone milestone;
  final VoidCallback? onTap;

  const UltraSpecialRoomCard({
    super.key,
    required this.milestone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: milestone.isUnlocked ? 8 : 3,
        shadowColor: milestone.isUnlocked 
            ? _getThemeColor().withValues(alpha: 77)
            : Colors.black.withValues(alpha: 26),
        color: milestone.isUnlocked 
            ? const Color(0xFFFFFEFB)
            : const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: milestone.isUnlocked 
                ? _getThemeColor()
                : const Color(0xFFE0E0E0),
            width: milestone.isUnlocked ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: _getThemeColor().withValues(alpha: 26),
          highlightColor: _getThemeColor().withValues(alpha: 13),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // 특별 공간 썸네일
                    _buildThumbnail(),
                    
                    const SizedBox(width: 16),
                    
                    // 메인 콘텐츠
                    Expanded(
                      child: _buildContent(context),
                    ),
                    
                    // 우측 상태
                    _buildStatusIcon(),
                  ],
                ),
                
                // 진행도 바 (잠긴 상태일 때만)
                if (!milestone.isUnlocked)
                  _buildProgressBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 특별 공간 썸네일
  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: milestone.isUnlocked 
                ? _getThemeColor().withValues(alpha: 77)
                : Colors.black.withValues(alpha: 38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: milestone.isUnlocked
            ? UltraBurrowImageHandler.ultraSafeImage(
                imagePath: milestone.imagePath,
                milestone: milestone,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              )
            : _buildLockedImage(),
      ),
    );
  }

  /// 잠긴 특별 공간 이미지 (burrow_locked.png 직접 사용)
  Widget _buildLockedImage() {
    return Image.asset(
      'assets/images/burrow/special_rooms/burrow_locked.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🔥 LOCKED IMAGE ERROR: Failed to load burrow_locked.png: $error');
        return _buildEnhancedLockedPlaceholder();
      },
    );
  }

  /// 개선된 잠긴 특별 공간 플레이스홀더
  Widget _buildEnhancedLockedPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8E3D8), // 연한 베이지
            const Color(0xFFD0C7B8), // 진한 베이지
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFBDBDBD).withValues(alpha: 77),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 패턴
          Positioned.fill(
            child: CustomPaint(
              painter: MysteryPatternPainter(),
            ),
          ),
          // 메인 아이콘과 텍스트
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 자물쇠 아이콘 (더 큰 크기)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A6B).withValues(alpha: 51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: const Color(0xFF6B7A4B),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // 물음표 텍스트
              Text(
                '???',
                style: TextStyle(
                  color: const Color(0xFF6B7A4B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          // 반짝이는 효과 (옵션)
          if (milestone.specialRoom != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getThemeColor().withValues(alpha: 153),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getThemeColor().withValues(alpha: 77),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// 메인 콘텐츠
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀
        Row(
          children: [
            if (milestone.isUnlocked) ...[
              Text(
                '[특별 공간]',
                style: TextStyle(
                  color: _getThemeColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.star,
                color: _getThemeColor(),
                size: 16,
              ),
            ] else ...[
              Text(
                '[${milestone.title}]',
                style: TextStyle(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 공간 이름
        Text(
          milestone.isUnlocked 
              ? milestone.title
              : '???',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: milestone.isUnlocked 
                ? const Color(0xFF2E3D1F)
                : const Color(0xFF757575),
          ),
        ),
        
        const SizedBox(height: 6),
        
        // 설명 또는 테마 힌트
        Text(
          milestone.isUnlocked 
              ? _getUnlockedDescription()
              : _getThemeHint(),
          style: TextStyle(
            color: milestone.isUnlocked 
                ? const Color(0xFF5A6B49)
                : const Color(0xFF757575),
            fontSize: 13,
            height: 1.3,
            fontStyle: milestone.isUnlocked 
                ? FontStyle.normal 
                : FontStyle.italic,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 상태 아이콘
  Widget _buildStatusIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: milestone.isUnlocked 
            ? _getThemeColor().withValues(alpha: 26)
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        milestone.isUnlocked 
            ? Icons.chevron_right
            : Icons.help_outline,
        color: milestone.isUnlocked 
            ? _getThemeColor()
            : const Color(0xFF9E9E9E),
        size: 20,
      ),
    );
  }

  /// 진행도 바 (잠긴 상태일 때)
  Widget _buildProgressBar(BuildContext context) {
    return Consumer<BurrowProvider>(
      builder: (context, burrowProvider, child) {
        final progress = _getProgress(burrowProvider);
        final progressPercent = (progress * 100).toInt();
        
        return Container(
          margin: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // 진행도 텍스트
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '진행도:',
                    style: TextStyle(
                      color: const Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      color: _getThemeColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 진행도 바
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getThemeColor().withValues(alpha: 179),
                          _getThemeColor(),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 테마별 색상
  Color _getThemeColor() {
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return const Color(0xFFE91E63); // 화려한 핑크 (무도회장)
      case SpecialRoom.hotSpring:
        return const Color(0xFF00BCD4); // 온천 블루
      case SpecialRoom.orchestra:
        return const Color(0xFF9C27B0); // 음악 퍼플
      case SpecialRoom.alchemyLab:
        return const Color(0xFF4CAF50); // 연금술 그린
      case SpecialRoom.fineDining:
        return const Color(0xFFFF9800); // 미식 오렌지
      default:
        return const Color(0xFF8B9A6B);
    }
  }

  /// 테마 힌트 (계획된 카피 적용)
  String _getThemeHint() {
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return '화려한 밤의 축제가 펼쳐지는 신비한 공간이 있다는데...';
      case SpecialRoom.hotSpring:
        return '따뜻한 온천수가 솟아나는 힐링의 공간이 있다는데...';
      case SpecialRoom.orchestra:
        return '아름다운 선율이 울려퍼지는 음악의 공간이 있다는데...';
      case SpecialRoom.alchemyLab:
        return '신비한 실험이 일어나는 연금술의 공간이 있다는데...';
      case SpecialRoom.fineDining:
        return '완벽한 요리가 탄생하는 미식의 공간이 있다는게...';
      default:
        return '특별한 공간이 숨어있는 것 같은데...';
    }
  }

  /// 언락된 상태 설명 (계획된 카피)
  String _getUnlockedDescription() {
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return '화려한 파티와 춤이 펼쳐지는 토끼들의 사교 공간';
      case SpecialRoom.hotSpring:
        return '편안한 휴식과 치유가 있는 토끼들의 온천';
      case SpecialRoom.orchestra:
        return '감동적인 음악이 흐르는 토끼들의 콘서트홀';
      case SpecialRoom.alchemyLab:
        return '특별한 레시피를 연구하는 토끼들의 실험실';
      case SpecialRoom.fineDining:
        return '최고의 요리를 즐기는 토끼들의 고급 레스토랑';
      default:
        return '특별한 공간이 열렸어요!';
    }
  }

  /// 진행도 계산 (임시 구현)
  double _getProgress(BurrowProvider burrowProvider) {
    // 실제로는 BurrowProvider에서 특별 공간별 진행도를 가져와야 함
    // 여기서는 임시로 레시피 수에 따른 진행도 계산
    final totalRecipes = burrowProvider.getAllRecipesCallback?.call().length ?? 0;
    
    switch (milestone.specialRoom) {
      case SpecialRoom.ballroom:
        return (totalRecipes / 30).clamp(0.0, 1.0);
      case SpecialRoom.hotSpring:
        return (totalRecipes / 50).clamp(0.0, 1.0);
      case SpecialRoom.orchestra:
        return (totalRecipes / 25).clamp(0.0, 1.0);
      case SpecialRoom.alchemyLab:
        return (totalRecipes / 40).clamp(0.0, 1.0);
      case SpecialRoom.fineDining:
        return (totalRecipes / 60).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }
}

/// 미스터리한 패턴을 그리는 커스텀 페인터
class MysteryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B9A6B).withValues(alpha: 26)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 미묘한 격자 패턴
    final spacing = size.width / 6;
    for (int i = 1; i < 6; i++) {
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

    // 중앙에 작은 원들
    final centerPaint = Paint()
      ..color = const Color(0xFF6B7A4B).withValues(alpha: 13)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 15, centerPaint);
    canvas.drawCircle(center, 25, centerPaint..color = const Color(0xFF6B7A4B).withValues(alpha: 8));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}