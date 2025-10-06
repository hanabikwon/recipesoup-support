import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../config/theme.dart';

/// 요리 지식을 캐러셀로 보여주는 카드 위젯
class CookingKnowledgeCard extends StatefulWidget {
  final List<Map<String, dynamic>> knowledgeList;
  final VoidCallback? onTap;

  const CookingKnowledgeCard({
    super.key,
    required this.knowledgeList,
    this.onTap,
  });

  @override
  State<CookingKnowledgeCard> createState() => _CookingKnowledgeCardState();
}

class _CookingKnowledgeCardState extends State<CookingKnowledgeCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.knowledgeList.isEmpty) {
      return _buildErrorCard(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 8),
          _buildCarousel(context),
          const SizedBox(height: 12),
          _buildCompactIndicator(),
        ],
      ),
    );
  }

  /// 섹션 헤더 (레시피 너머의 이야기)
  Widget _buildSectionHeader(BuildContext context) {
    final currentKnowledge = widget.knowledgeList[_currentIndex];
    final category = currentKnowledge['category'] as String? ?? '';

    return Row(
      children: [
        const Icon(
          Icons.menu_book,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '레시피 너머의 이야기',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (category.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7A5B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6B7A5B).withValues(alpha: 128),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                category,
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

  /// 캐러셀 슬라이더
  Widget _buildCarousel(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: widget.knowledgeList.length,
      itemBuilder: (context, index, realIndex) {
        return _buildKnowledgeCard(context, widget.knowledgeList[index]);
      },
      options: CarouselOptions(
        height: 250,
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
        autoPlay: false,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// 미니멀 3개 도트 인디케이터
  Widget _buildCompactIndicator() {
    final totalItems = widget.knowledgeList.length;
    if (totalItems <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 왼쪽 도트 (이전 아이템 암시)
        _buildDot(false, isSmall: true),
        const SizedBox(width: 8),

        // 중앙 도트 (현재 위치 - 크게 강조)
        _buildDot(true, isSmall: false),
        const SizedBox(width: 8),

        // 오른쪽 도트 (다음 아이템 암시)
        _buildDot(false, isSmall: true),
      ],
    );
  }

  /// 단일 도트 (크기 2종류)
  Widget _buildDot(bool isActive, {required bool isSmall}) {
    return Container(
      width: isActive ? 10 : (isSmall ? 5 : 6),
      height: isActive ? 10 : (isSmall ? 5 : 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor
            : AppTheme.dividerColor.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  /// 지식 카드 메인 컨테이너
  Widget _buildKnowledgeCard(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '제목 없음';
    final content = data['content'] as String? ?? '';
    final imageUrl = data['image'] as String? ?? '';

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 영역 (30% 너비, 세로 상단 정렬)
              _buildKnowledgeImage(context, imageUrl),
              const SizedBox(width: 16),

              // 텍스트 컨텐츠 영역 (70% 너비)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 구분선
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.dividerColor,
                    ),
                    const SizedBox(height: 8),

                    // 내용
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  /// 지식 이미지 (30% 너비 정사각형, 왼쪽 정렬 - 모든 섹션과 통일)
  Widget _buildKnowledgeImage(BuildContext context, String imageUrl) {
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
                    Icons.menu_book,
                    color: AppTheme.textTertiary,
                    size: 32,
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
          _buildSectionHeader(context),
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
                  '요리 지식 정보를\n불러올 수 없습니다',
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
}
