import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../models/mood.dart';
import '../../utils/date_utils.dart';
import '../../screens/create_screen.dart';
import '../../screens/detail_screen.dart';

/// 최근 저장한 레시피를 보여주는 카드 위젯
/// 레시피가 없을 때는 빈 상태 UI를 표시
class RecentRecipeCard extends StatelessWidget {
  final Recipe? recipe;
  final VoidCallback? onCreatePressed;
  final VoidCallback? onRecipePressed;

  const RecentRecipeCard({
    super.key,
    this.recipe,
    this.onCreatePressed,
    this.onRecipePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: [],
              border: Border.all(
                color: const Color(0xFFE8E3D8),
                width: 1,
              ),
            ),
            child: recipe != null 
              ? _buildRecipeContent(context)
              : _buildEmptyContent(context),
          ),
        ],
      ),
    );
  }

  /// 섹션 헤더 (카드 외부)
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.edit_note,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '최근 저장한 레시피',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// 레시피가 있을 때의 콘텐츠
  Widget _buildRecipeContent(BuildContext context) {
    if (recipe == null) return const SizedBox.shrink();

    return InkWell(
      onTap: onRecipePressed ?? () => _navigateToDetail(context, recipe!),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppTheme.borderRadiusMedium),
        bottomRight: Radius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 이미지 또는 감정 이모지 영역
            _buildRecipeImage(),
            const SizedBox(width: 12),
            // 텍스트 정보 영역
            Expanded(
              child: _buildRecipeInfo(context),
            ),
            // 화살표 아이콘
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 레시피 이미지 또는 감정 이모지
  Widget _buildRecipeImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: _buildDefaultEmoji(),
    );
  }

  /// 기본 감정 이모지 표시
  Widget _buildDefaultEmoji() {
    return Center(
      child: Icon(
        recipe?.mood.icon ?? Mood.happy.icon,
        size: 30,
        color: AppTheme.textSecondary,
      ),
    );
  }

  /// 레시피 정보 (제목, 시간, 감정 스토리, 태그)
  Widget _buildRecipeInfo(BuildContext context) {
    if (recipe == null) return const SizedBox.shrink();

    final timeAgo = _getTimeAgoText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 시간
        Row(
          children: [
            Expanded(
              child: Text(
                recipe!.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        
        // 감정 스토리
        if (recipe!.emotionalStory.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '"${recipe!.emotionalStory}"',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // 태그들
        if (recipe!.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTagsRow(context),
        ],
      ],
    );
  }

  /// 태그 행 생성
  Widget _buildTagsRow(BuildContext context) {
    final displayTags = recipe!.tags.take(3).toList();
    
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: displayTags.map((tag) => _buildTag(context, tag)).toList(),
          ),
        ),
        if (recipe!.tags.length > 3)
          Text(
            '+${recipe!.tags.length - 3}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
      ],
    );
  }

  /// 개별 태그 위젯
  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  /// 레시피가 없을 때의 콘텐츠
  Widget _buildEmptyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 안내 텍스트
          Text(
            '아직 작성한 레시피가 없네요.\n마음을 담아 나만의 레시피를\n기록해보세요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 작성하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreatePressed ?? () => _navigateToCreate(context),
              icon: const Icon(
                Icons.add,
                size: 20,
              ),
              label: const Text('첫 레시피 작성하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 경과 텍스트 생성
  String _getTimeAgoText() {
    if (recipe == null) return '';

    final now = DateTime.now();
    final diff = now.difference(recipe!.createdAt);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return RecipeDateUtils.formatKoreanDate(recipe!.createdAt);
    }
  }

  /// 레시피 상세 화면으로 이동
  void _navigateToDetail(BuildContext context, Recipe recipe) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      debugPrint('레시피 상세 화면 이동 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('레시피를 여는 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 레시피 작성 화면으로 이동
  void _navigateToCreate(BuildContext context) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateScreen(),
        ),
      );
    } catch (e) {
      debugPrint('레시피 작성 화면 이동 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('레시피 작성 화면을 여는 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}