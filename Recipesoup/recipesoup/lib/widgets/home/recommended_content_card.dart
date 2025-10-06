import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../config/theme.dart';

/// 추천 콘텐츠(영화/책)를 캐러셀로 보여주는 카드 위젯
class RecommendedContentCard extends StatefulWidget {
  final List<Map<String, dynamic>> contentList;
  final VoidCallback? onTap;

  const RecommendedContentCard({
    super.key,
    required this.contentList,
    this.onTap,
  });

  @override
  State<RecommendedContentCard> createState() => _RecommendedContentCardState();
}

class _RecommendedContentCardState extends State<RecommendedContentCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.contentList.isEmpty) {
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

  /// 섹션 헤더 (콘텐츠 큐레이션)
  Widget _buildSectionHeader(BuildContext context) {
    final currentContent = widget.contentList[_currentIndex];
    final category = currentContent['category'] as String? ?? '';

    return Row(
      children: [
        const Icon(
          Icons.collections_bookmark,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '콘텐츠 큐레이션',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
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
      itemCount: widget.contentList.length,
      itemBuilder: (context, index, realIndex) {
        return _buildContentCard(context, widget.contentList[index]);
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
    final totalItems = widget.contentList.length;
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

  /// 콘텐츠 카드 메인 컨테이너
  Widget _buildContentCard(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'movie';
    final title = data['title'] as String? ?? '제목 없음';
    final subtitle = data['subtitle'] as String? ?? '';
    final director = data['director'] as String?;
    final author = data['author'] as String?;
    final description = data['description'] as String? ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
            // 왼쪽: 이미지 영역 (세로 상단 정렬)
            _buildImageArea(context, data),
            const SizedBox(width: 20), // 간격 12 -> 20으로 확장

            // 오른쪽: 텍스트 콘텐츠 (위쪽 정렬 유지)
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 텍스트 높이에 맞춰 조절
                  children: [
                    // 제목과 카테고리
                    _buildTextHeader(context, title, subtitle, type, director, author),

                    const SizedBox(height: 8),

                    // 구분선
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.dividerColor,
                    ),

                    const SizedBox(height: 8),

                    // 설명
                    _buildContent(context, description),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 텍스트 헤더 (제목만)
  Widget _buildTextHeader(BuildContext context, String title, String subtitle, String type, String? director, String? author) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 부제목
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),

          // 감독/작가 정보
          if (director != null || author != null) ...[
            const SizedBox(height: 8),
            Text(
              type == 'book' ? '저자: $author' : '감독: $director',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
  }


  /// 콘텐츠 내용 (전체 표시)
  Widget _buildContent(BuildContext context, String description) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
      maxLines: null,
      overflow: TextOverflow.visible,
    );
  }

  /// 카테고리별 색상 매핑 (모두 올리브 그린으로 통일)
  Color _getCategoryColor(String category) {
    // 모든 카테고리를 올리브 그린으로 통일
    return const Color(0xFF6B7A5B); // 올리브 그린
  }

  /// 에러 카드
  Widget _buildErrorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: const Color(0xFFE8E3D8),
                width: 1,
              ),
            ),
            child: Text(
              '추천 콘텐츠를 불러올 수 없습니다.\n잠시 후 다시 시도해 주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 영역 (안전한 null 체크 포함)
  Widget _buildImageArea(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'movie';

    // 카드 콘텐츠 영역 기준 30% 계산 (모든 섹션과 통일)
    final contentWidth = MediaQuery.of(context).size.width - 64;
    final imageWidth = contentWidth * 0.3;

    // 타입별 비율 결정
    final aspectRatio = _isMovieType(type) ? 2.0 / 3.0 : 10.0 / 16.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: imageWidth * 0.8, // 동적 최소 너비
        maxWidth: imageWidth * 1.2, // 동적 최대 너비
        minHeight: imageWidth / aspectRatio * 0.8, // 동적 최소 높이
        maxHeight: imageWidth / aspectRatio * 1.2, // 동적 최대 높이
      ),
      child: SizedBox(
        width: imageWidth,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildImageContent(context, data),
        ),
      ),
    );
  }

  /// 이미지 콘텐츠
  Widget _buildImageContent(BuildContext context, Map<String, dynamic> data) {
    final imagePath = _getImagePath(data);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(context, data['type'] as String);
          },
        ),
      ),
    );
  }

  /// 이미지 플레이스홀더
  Widget _buildImagePlaceholder(BuildContext context, String type) {
    final color = _getCategoryColor('영화').withValues(alpha: 179);
    final icon = _isMovieType(type) ? Icons.movie : Icons.menu_book;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 51),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: color,
        ),
      ),
    );
  }

  /// 이미지 경로 생성 (JSON image 필드 우선, 동적 생성 fallback)
  String _getImagePath(Map<String, dynamic> data) {
    // 1. JSON image 필드 우선 체크 (Ultra Think: 명시적 필드 우선)
    final explicitImage = data['image'] as String?;
    if (explicitImage != null && explicitImage.isNotEmpty) {
      return explicitImage;
    }

    // 2. 기존 동적 로직을 안전한 fallback으로 유지 (Ultra Think: 기존 기능 완전 보존)
    final type = data['type'] as String? ?? 'movie';
    final id = data['id'] as String? ?? 'default';
    final folder = _isMovieType(type) ? 'movies' : 'books';
    return 'assets/images/content/$folder/$id.webp';
  }

  /// 영화 타입 여부 확인 (안전한 null 체크 포함)
  bool _isMovieType(String? type) {
    if (type == null) return true; // 기본값은 영화로 처리
    return ['movie', 'documentary', 'drama', 'animation'].contains(type.toLowerCase());
  }
}
