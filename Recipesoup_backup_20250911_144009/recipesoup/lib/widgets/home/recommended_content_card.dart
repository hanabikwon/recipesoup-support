import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// 추천 콘텐츠(영화/책)를 보여주는 카드 위젯
class RecommendedContentCard extends StatelessWidget {
  final Map<String, dynamic>? contentData;
  final VoidCallback? onTap;

  const RecommendedContentCard({
    super.key,
    required this.contentData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contentData == null) {
      return _buildErrorCard(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, contentData),
          const SizedBox(height: 8),
          _buildContentCard(context),
        ],
      ),
    );
  }

  /// 섹션 헤더 (콘텐츠 큐레이션)
  Widget _buildSectionHeader(BuildContext context, Map<String, dynamic>? data) {
    final category = data?['category'] as String? ?? '';
    
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

  /// 콘텐츠 카드 메인 컨테이너
  Widget _buildContentCard(BuildContext context) {
    final data = contentData!;
    final type = data['type'] as String? ?? 'movie';
    final title = data['title'] as String? ?? '제목 없음';
    final subtitle = data['subtitle'] as String? ?? '';
    final director = data['director'] as String?;
    final author = data['author'] as String?;
    final description = data['description'] as String? ?? '';
    final category = data['category'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: 이미지 영역 (세로 중앙 정렬)
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
                    _buildTextHeader(context, title, subtitle, category, type, director, author),
                    
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
      ),
    );
  }

  /// 텍스트 헤더 (제목만)
  Widget _buildTextHeader(BuildContext context, String title, String subtitle, String category, String type, String? director, String? author) {
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
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
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
            ),
          ],
        ],
      );
  }


  /// 콘텐츠 내용 (동적 높이 지원)
  Widget _buildContent(BuildContext context, String description) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
      // maxLines와 overflow 제거하여 전체 텍스트 표시
    );
  }

  /// 카테고리별 색상 매핑 (모두 올리브 그린으로 통일)
  Color _getCategoryColor(String category) {
    // 모든 카테고리를 올리브 그린으로 통일
    return const Color(0xFF6B7A5B); // 올리브 그린
    
    // 기존 개별 색상 코드 (참고용)
    // switch (category.toLowerCase()) {
    //   case '영화': return const Color(0xFF2196F3); // 파란색
    //   case '드라마': return const Color(0xFF9C27B0); // 보라색
    //   case '애니메이션': return const Color(0xFFFF9800); // 주황색
    //   case '다큐멘터리': return const Color(0xFF4CAF50); // 초록색
    //   case '에세이': return const Color(0xFF6B7A5B); // 올리브 그린
    //   case '소설': return const Color(0xFF795548); // 갈색
    //   case '요리책': return const Color(0xFF6B7A5B); // 올리브 그린
    //   default: return const Color(0xFF9E9E9E); // 회색
    // }
  }

  /// 에러 카드
  Widget _buildErrorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, null),
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

  /// 이미지 경로 생성 (안전한 null 체크 포함)
  String _getImagePath(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'movie';
    final id = data['id'] as String? ?? 'default';
    final folder = _isMovieType(type) ? 'movies' : 'books';
    return 'assets/images/content/$folder/$id.jpg';
  }

  /// 영화 타입 여부 확인 (안전한 null 체크 포함)
  bool _isMovieType(String? type) {
    if (type == null) return true; // 기본값은 영화로 처리
    return ['movie', 'documentary', 'drama', 'animation'].contains(type.toLowerCase());
  }
}