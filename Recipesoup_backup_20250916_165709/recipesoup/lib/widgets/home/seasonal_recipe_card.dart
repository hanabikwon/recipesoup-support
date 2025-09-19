import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// 제철 레시피를 보여주는 카드 위젯
/// 펼쳐보기/접기 기능 포함
class SeasonalRecipeCard extends StatefulWidget {
  final Map<String, dynamic>? recipeData;
  final VoidCallback? onTap;

  const SeasonalRecipeCard({
    super.key,
    required this.recipeData,
    this.onTap,
  });

  @override
  State<SeasonalRecipeCard> createState() => _SeasonalRecipeCardState();
}

class _SeasonalRecipeCardState extends State<SeasonalRecipeCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipeData == null) {
      return _buildErrorCard(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, widget.recipeData),
          const SizedBox(height: 16),
          _buildRecipeCard(context),
        ],
      ),
    );
  }

  /// 섹션 헤더 (요즘 주목받는 레시피)
  Widget _buildSectionHeader(BuildContext context, Map<String, dynamic>? data) {
    final badge = data?['badge'] as String? ?? '';
    
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '요즘 주목받는 레시피',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBadgeColor(badge),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBadgeColor(badge).withValues(alpha: 128),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// 레시피 카드 메인 컨테이너
  Widget _buildRecipeCard(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [],
          border: Border.all(
            color: const Color(0xFFE8E3D8),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardContent(context),
            _buildExpandButton(context),
          ],
        ),
      ),
    );
  }

  /// 카드 내용
  Widget _buildCardContent(BuildContext context) {
    final data = widget.recipeData!;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역 (30% 너비, 왼쪽 정렬)
          _buildRecipeImage(context, data),
          const SizedBox(width: 16),
          
          // 텍스트 콘텐츠 영역 (70% 너비)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                _buildHeaderRow(context, data),
                const SizedBox(height: 12),
                
                // 메타 정보 (조리시간, 난이도, 칼로리)
                _buildMetaInfo(context, data),
                const SizedBox(height: 12),
                
                // 설명 부분 (애니메이션으로 전환)
                AnimatedCrossFade(
                  firstChild: _buildShortDescription(context, data),
                  secondChild: _buildFullDescription(context, data),
                  crossFadeState: _isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 헤더 행 (제목만)
  Widget _buildHeaderRow(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '제목 없음';

    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        fontSize: 16,
      ),
    );
  }

  /// 메타 정보 (조리시간, 난이도, 칼로리)
  Widget _buildMetaInfo(BuildContext context, Map<String, dynamic> data) {
    final cookingTime = data['cookingTime'] as String? ?? '';
    final difficulty = data['difficulty'] as String? ?? '';
    final calories = data['calories'] as String? ?? '';

    return Row(
      children: [
        // 조리시간
        if (cookingTime.isNotEmpty) ...[
          Icon(
            Icons.schedule,
            size: 14,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            cookingTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // 난이도
        if (difficulty.isNotEmpty) ...[
          Icon(
            Icons.star_outline,
            size: 14,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            difficulty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // 칼로리
        if (calories.isNotEmpty) ...[
          Icon(
            Icons.local_fire_department_outlined,
            size: 14,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            calories,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  /// 짧은 설명 (기본 표시)
  Widget _buildShortDescription(BuildContext context, Map<String, dynamic> data) {
    final shortDesc = data['shortDescription'] as String? ?? '';
    
    return Text(
      shortDesc,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
        height: 1.4,
      ),
    );
  }

  /// 전체 설명 (펼쳤을 때)
  Widget _buildFullDescription(BuildContext context, Map<String, dynamic> data) {
    final fullDesc = data['fullDescription'] as String? ?? '';
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        fullDesc,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  /// 펼쳐보기/접기 버튼
  Widget _buildExpandButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.borderRadiusMedium),
            bottomRight: Radius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpanded ? '접기' : '펼쳐보기',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 에러 카드 (데이터가 없을 때)
  Widget _buildErrorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, null),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: AppTheme.vintageShadow,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.textTertiary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  '제철 레시피 정보를\n불러올 수 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 뱃지 색상 결정 (모든 뱃지를 올리브 그린으로 통일)
  Color _getBadgeColor(String badge) {
    // 모든 뱃지를 올리브 그린으로 통일
    return const Color(0xFF6B7A5B); // 차분한 올리브 그린
  }

  /// 레시피 이미지 (30% 너비 정사각형, 왼쪽 정렬 - 모든 섹션과 통일)
  Widget _buildRecipeImage(BuildContext context, Map<String, dynamic> data) {
    final imageUrl = data['image'] as String? ?? '';
    // 카드 콘텐츠 영역 기준 30% 계산 (외부패딩32px + 내부패딩32px 제외)
    final contentWidth = MediaQuery.of(context).size.width - 64;
    final imageSize = contentWidth * 0.3;
    
    return Container(
      width: imageSize,
      height: imageSize, // Same as width for square
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.cardColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isNotEmpty
          ? Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textTertiary,
                      size: 32,
                    ),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: AppTheme.textTertiary,
                  size: 32,
                ),
              ),
            ),
      ),
    );
  }

  /// 펼쳐보기/접기 토글
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}