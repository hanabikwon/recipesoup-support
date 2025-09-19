import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/openai_service.dart';
import '../models/recipe.dart';
import '../models/mood.dart';
import '../widgets/vintage_loading_widget.dart';
import '../widgets/common/required_badge.dart';
import 'create_screen.dart';

class KeywordImportScreen extends StatefulWidget {
  const KeywordImportScreen({super.key});

  @override
  State<KeywordImportScreen> createState() => _KeywordImportScreenState();
}

class _KeywordImportScreenState extends State<KeywordImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keywordController = TextEditingController();
  final _openAiService = OpenAiService();
  bool _isLoading = false;
  String _loadingMessage = '';
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _keywordController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressAnimation(double targetProgress) {
    _progressTimer?.cancel();
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // 랜덤한 증가량으로 자연스럽게 증가
        final increment = Random().nextDouble() * 0.015 + 0.005; // 0.005~0.02 사이
        _loadingProgress = min(_loadingProgress + increment, targetProgress);
      });
      
      if (_loadingProgress >= targetProgress) {
        timer.cancel();
      }
    });
  }

  Future<void> _generateRecipeFromKeyword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final keyword = _keywordController.text.trim();

    setState(() {
      _isLoading = true;
      _loadingMessage = '레시피 재료 준비중';
      _loadingProgress = 0.1;
    });
    _startProgressAnimation(0.3);

    try {
      // 1단계: 레시피 재료 준비중
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _loadingMessage = 'AI로 레시피 작성중';
        _loadingProgress = 0.4;
      });
      _startProgressAnimation(0.7);

      // 키워드 기반 프롬프트 생성 (ApiConfig 사용)
      final prompt = ApiConfig.createKeywordRecipePrompt(keyword);

      // 2단계: AI로 레시피 작성중
      await Future.delayed(Duration(milliseconds: 800));
      
      setState(() {
        _loadingMessage = '레시피 마무리중';
        _loadingProgress = 0.8;
      });
      _startProgressAnimation(0.95);

      // OpenAI API를 통한 레시피 생성 (프로그레스 콜백 무시)
      final analysis = await _openAiService.analyzeText(
        prompt,
        onProgress: null, // 내부 프로그레스 메시지 무시
      );

      // 3단계: 레시피 마무리중 
      await Future.delayed(Duration(milliseconds: 600));
      
      setState(() {
        _loadingMessage = '레시피 작성 완료 🐰';
        _loadingProgress = 1.0;
      });

      await Future.delayed(Duration(milliseconds: 400));

      // 분석 결과를 Recipe 객체로 변환
      final recipe = Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: analysis.dishName,
        emotionalStory: '', // 사용자가 직접 작성할 수 있도록 비워둠
        ingredients: analysis.toIngredients(), // AnalysisIngredient를 Ingredient로 변환
        sauce: analysis.sauce, // AI 분석 결과에서 소스 정보 가져오기
        instructions: analysis.instructions,
        tags: [...analysis.tags, keyword.startsWith('#') ? keyword : '#$keyword'], // AI 생성 태그 + 키워드 포함
        createdAt: DateTime.now(),
        mood: Mood.comfortable, // 기본 감정 상태
        isFavorite: false,
      );

      if (!mounted) return;

      // CreateScreen으로 이동 (생성 모드로)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreateScreen(
            editingRecipe: recipe,
            isEditMode: false, // 새로운 레시피 생성 모드
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
        _loadingProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('레시피 생성 실패: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('퀵레시피 작성하기'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: _buildInputView(),
              ),
            ),
    );
  }

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 설명 카드
        Container(
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
                  Icons.auto_awesome,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  '만들고 싶은 요리명을 입력하면 Ai가 레시피를 자동으로 생성해드려요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // 키워드 입력 필드 라벨
        const LabelWithRequiredBadge(
          label: '요리명',
        ),
        const SizedBox(height: 8),

        // 키워드 입력 필드
        TextFormField(
          controller: _keywordController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '예: 클램 차우더',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flash_on, color: AppTheme.primaryColor),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '키워드를 입력해주세요';
            }
            return null;
          },
          onFieldSubmitted: (_) => _generateRecipeFromKeyword(),
        ),
        const SizedBox(height: AppTheme.spacing32),

        // 생성 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generateRecipeFromKeyword,
            icon: const Icon(Icons.flash_on, size: 20),
            label: const Text('퀵레시피 생성하기'),
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

      ],
    );
  }

  Widget _buildLoadingView() {
    return ProgressVintageLoading(
      message: _loadingMessage,
      progress: _loadingProgress,
    );
  }
}