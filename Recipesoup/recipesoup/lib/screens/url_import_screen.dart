import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/mood.dart';
import '../models/recipe.dart';
import '../models/recipe_analysis.dart';
import '../services/url_scraper_service.dart';
import '../services/openai_service.dart';
import '../widgets/common/required_badge.dart';
import '../widgets/common/vintage_info_card.dart';
import 'create_screen.dart';

/// URL에서 레시피를 가져와서 분석하는 화면
class UrlImportScreen extends StatefulWidget {
  const UrlImportScreen({super.key});

  @override
  State<UrlImportScreen> createState() => _UrlImportScreenState();
}

class _UrlImportScreenState extends State<UrlImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _urlScraperService = UrlScraperService();
  final _openAiService = OpenAiService();
  
  bool _isLoading = false;
  String? _error;
  ScrapedContent? _scrapedContent;
  RecipeAnalysis? _analysisResult;
  String _currentLoadingMessage = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('링크로 가져오기'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.spacing24),
              _buildUrlInputSection(),
              const SizedBox(height: AppTheme.spacing32),
              _buildActionButtons(),
              if (_error != null) ...[
                const SizedBox(height: AppTheme.spacing16),
                _buildErrorCard(),
              ],
              if (_scrapedContent != null && _analysisResult == null) ...[
                const SizedBox(height: AppTheme.spacing16),
                _buildScrapedPreview(),
              ],
              if (_analysisResult != null) ...[
                const SizedBox(height: AppTheme.spacing16),
                _buildAnalysisResult(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: const Icon(
              Icons.link,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              '블로그나 웹사이트의 레시피 URL을 입력하면 재료와 조리법을 추출해드려요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LabelWithRequiredBadge(
          label: '레시피 URL',
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: '예: https://blog.naver.com/... 또는 https://...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link, color: AppTheme.primaryColor),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'URL을 입력해주세요';
            }
            if (Uri.tryParse(value)?.hasScheme != true) {
              return '올바른 URL 형식이 아닙니다';
            }
            return null;
          },
          onFieldSubmitted: (_) => _processUrl(),
        ),
        // 지원 사이트 안내 문구 제거됨
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _processUrl,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, size: 20),
            label: Text(_isLoading ? _currentLoadingMessage.isNotEmpty ? _currentLoadingMessage : '분석 중...' : '레시피 가져오기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
          ),
        ),
        if (_analysisResult != null) ...[
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _createRecipe,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('레시피 작성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorCard() {
    if (_error == null) return Container();

    // VintageInfoCard 컴포넌트 사용
    return VintageInfoCard(
      title: '잠시만 기다려주세요 🐰',
      message: _error!,
    );
  }

  Widget _buildScrapedPreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.web,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '웹페이지 내용',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '제목: ${_scrapedContent!.title}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '내용 길이: ${_scrapedContent!.text.length}자',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '레시피 관련: ${_scrapedContent!.hasRecipeContent ? "예" : "아니오"}',
            style: TextStyle(
              color: _scrapedContent!.hasRecipeContent 
                  ? AppTheme.successColor 
                  : AppTheme.warningColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.vintageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentOrange,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'AI 분석 결과',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          // 요리명
          _buildAnalysisItem(
            '요리명',
            _analysisResult!.dishName,
            Icons.restaurant,
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // 재료
          _buildAnalysisItem(
            '재료',
            _analysisResult!.ingredients.map((i) => '${i.name}${i.amount != null ? ' ${i.amount}' : ''}').join(', '),
            Icons.shopping_basket,
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // 조리법
          _buildAnalysisItem(
            '조리법',
            _analysisResult!.instructions.asMap().entries
                .map((entry) => '${entry.key + 1}. ${entry.value}')
                .join('\n'),
            Icons.list_alt,
          ),
          
          if (_analysisResult!.estimatedTime.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '조리 시간',
              _analysisResult!.estimatedTime,
              Icons.timer,
            ),
          ],
          
          if (_analysisResult!.difficulty.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '난이도',
              _analysisResult!.difficulty,
              Icons.bar_chart,
            ),
          ],
          
          if (_analysisResult!.servings.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildAnalysisItem(
              '인분',
              _analysisResult!.servings,
              Icons.people,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          content,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _processUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _scrapedContent = null;
      _analysisResult = null;
      _currentLoadingMessage = '레시피 재료 준비중';
    });

    try {
      // 1단계: URL에서 콘텐츠 스크래핑
      final scrapedContent = await _urlScraperService.scrapeRecipeFromUrl(
        _urlController.text.trim(),
      );

      setState(() {
        _scrapedContent = scrapedContent;
        _currentLoadingMessage = '레시피 재료 준비중';
      });

      // 콘텐츠가 너무 짧으면 에러 (조건 완화: 10자 → 5자)
      if (scrapedContent.text.length < 5) {
        setState(() {
          _error = '페이지에서 내용을 추출할 수 없습니다. 다른 레시피 URL을 시도해보세요.\n추출된 내용: ${scrapedContent.text.length}자';
          _isLoading = false;
        });
        return;
      }
      
      // 레시피 관련 내용이 없으면 경고 표시 (하지만 AI 분석은 계속 진행)
      if (!scrapedContent.hasRecipeContent) {
        // ScaffoldMessenger로 경고 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('레시피 관련 키워드를 찾지 못했지만, AI 분석을 통해 레시피를 추출해보겠습니다.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      // 웹페이지 내용 표시 후 잠시 대기 (사용자가 내용을 확인할 수 있도록)
      await Future.delayed(Duration(milliseconds: 1500));
      
      // 자동으로 AI 분석 시작하도록 로딩 상태 유지
      setState(() {
        _error = null;
        // _isLoading은 true 유지하여 AI 분석 계속 진행
      });

      // 2단계: AI로 레시피 분석중 (백그라운드에서 웹 스크래핑 완료됨)
      setState(() {
        _currentLoadingMessage = 'AI로 레시피 분석중';
      });
      
      await Future.delayed(Duration(milliseconds: 800));
      
      // 3단계: 레시피 마무리중
      setState(() {
        _currentLoadingMessage = '레시피 마무리중';
      });
      
      final analysisResult = await _openAiService.analyzeText(
        scrapedContent.text,
        onProgress: null, // 내부 프로그레스 메시지 무시
      );

      await Future.delayed(Duration(milliseconds: 600));

      // 4단계: 레시피 작성 완료
      setState(() {
        _analysisResult = analysisResult;
        _currentLoadingMessage = '레시피 작성 완료 🐰';
        _isLoading = false;
      });

      await Future.delayed(Duration(milliseconds: 400));

    } catch (e) {
      // 에러 메시지 구체화
      String errorMessage;
      final errorStr = e.toString().toLowerCase();
      final url = _urlController.text.trim().toLowerCase();

      // Rate Limit 에러 감지 및 전용 다이얼로그 표시
      if (errorStr.contains('rate limit') || errorStr.contains('429') || errorStr.contains('quota')) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentLoadingMessage = '';
          });
          _showRateLimitDialog();
        }
        return;
      }

      // 영상 링크 감지 (YouTube, TikTok, Instagram 등)
      if (url.contains('youtube.com') || url.contains('youtu.be') ||
          url.contains('tiktok.com') || url.contains('instagram.com') ||
          url.contains('reels') || url.contains('shorts')) {
        errorMessage = '영상 링크 분석은 준비중이에요.\n블로그나 웹사이트의 레시피 글 링크를 사용해주세요.';
      } else if (errorStr.contains('network') || errorStr.contains('timeout') || errorStr.contains('connection')) {
        errorMessage = '네트워크 연결을 확인해주세요.\n인터넷 연결 상태를 점검해보세요.';
      } else {
        // 기본 에러 메시지
        errorMessage = '레시피를 가져올 수 없습니다.\n다른 URL을 시도해주세요.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _currentLoadingMessage = '';
      });
    }
  }

  void _createRecipe() {
    if (_analysisResult == null || _scrapedContent == null) return;

    // 분석 결과로 Recipe 객체 생성
    final recipe = Recipe.generateNew(
      title: _analysisResult!.dishName,
      emotionalStory: '', // 사용자가 나중에 입력
      mood: Mood.happy, // 기본값
      ingredients: _analysisResult!.toIngredients(),
      sauce: _analysisResult!.sauce, // AI 분석 결과에서 소스 정보 가져오기
      instructions: _analysisResult!.instructions,
      tags: _analysisResult!.tags, // AI 생성 태그 포함
      sourceUrl: _scrapedContent!.sourceUrl,
    );

    // CreateScreen으로 이동 (생성 모드, AI 분석 결과로 미리 채움)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          editingRecipe: recipe,
          isEditMode: false, // 새로운 레시피 생성 모드
        ),
      ),
    );
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        title: Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              color: AppTheme.accentOrange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              '잠시만 기다려주세요 🐰',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시간당 AI 분석 요청 한도를 초과했습니다.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '시간당 최대 50회까지 분석 가능합니다',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '잠시 후 다시 시도해주세요.\n조금만 기다리면 다시 사용하실 수 있습니다.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}