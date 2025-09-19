import 'package:flutter/material.dart';
import 'dart:async';

import '../config/theme.dart';
import '../config/constants.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 전체 애니메이션 0.8초로 단축
    );

    // 배경 이미지 페이드인 (모든 요소 동시 로드)
    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    // 카드 스케일 애니메이션 (모든 요소 동시 로드)
    _cardScaleAnimation = Tween<double>(
      begin: 1.0, // 시작부터 정상 크기
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // 카드 페이드인 (모든 요소 동시 로드)
    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    // 콘텐츠 페이드인 (모든 요소 동시 로드)
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 시작 딜레이 단축
    
    _animationController.forward();

    Timer(const Duration(milliseconds: 2500), () { // 2.5초로 단축
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = screenHeight < 700 ? 80.0 : 120.0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand, // Stack이 부모 크기를 완전히 채우도록
              children: [
                // 1. 배경 이미지 레이어 (토끼 셰프 + sepia 필터)
                _buildBackgroundImage(),
                
                // 2. 반투명 오버레이 그라데이션
                _buildOverlayGradient(),
                
                // 3. 메인 콘텐츠
                _buildMainContent(topPadding, screenWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. 배경 이미지 레이어 (토끼 셰프 - 원본 선명도)
  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFD4C4A0), // 이미지와 더 비슷한 갈색 베이지 배경
        ),
        child: FadeTransition(
          opacity: _backgroundFadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash_rabbit.png'),
                fit: BoxFit.cover, // fill → cover 복원 (비율 유지하면서 화면 채움)
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. 반투명 오버레이 그라데이션 (가독성 확보)
  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // 3. 메인 콘텐츠
  Widget _buildMainContent(double topPadding, double screenWidth) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08, // 화면 너비의 8%
        ),
        child: Column(
          children: [
            SizedBox(height: topPadding), // 상단 여백 120px
            
            // 메인 타이틀 (카드 없이 텍스트만)
            _buildMainTitle(),
            
            const SizedBox(height: 16), // 타이틀-서브타이틀 간격
            
            // 서브타이틀
            _buildSubtitle(),
            
            const Spacer(), // 위쪽 남은 공간
            
            // 중앙 로딩 섹션
            _buildLoadingSection(),
            
            const Spacer(), // 아래쪽 남은 공간 (중앙 배치)
          ],
        ),
      ),
    );
  }

  // 메인 타이틀 (하얀 배경에 검정 테두리 사각형)
  Widget _buildMainTitle() {
    return AnimatedBuilder(
      animation: _cardFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0, // 항상 완전 불투명
          child: ScaleTransition(
            scale: _cardScaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white, // 하얀 배경
                border: Border.all(
                  color: Colors.black, // 검정 테두리
                  width: 2.0, // 테두리를 두껍게 (1.0 → 2.0)
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  // 그림자 추가로 더 선명하게
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 51),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'RubikDirt', // Rubik Dirt 폰트 적용
                  fontSize: 42, // 크기를 40에서 42로 증가
                  fontWeight: FontWeight.w500, // 더 가벼운 볼드 처리 (w600 → w500)
                  color: Colors.black, // 검정 색상
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // 서브타이틀
  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: Stack(
        children: [
          // 하얀색 스트로크 (아웃라인)
          Text(
            '감정을 담은 레시피 아카이빙',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'Orbit', // Orbit 폰트 적용
              fontSize: 22, // 기존 18에서 22로 증가
              fontWeight: FontWeight.bold, // w500에서 bold로 변경
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4.0 // 스트로크 두께
                ..color = Colors.white, // 하얀색 스트로크
            ),
            textAlign: TextAlign.center,
          ),
          // 검정색 텍스트 (메인)
          Text(
            '감정을 담은 레시피 아카이빙',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'Orbit', // Orbit 폰트 적용
              fontSize: 22, // 기존 18에서 22로 증가
              fontWeight: FontWeight.bold, // w500에서 bold로 변경
              color: Colors.black, // 검정색 메인 텍스트
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 로딩 섹션 (텍스트만)
  Widget _buildLoadingSection() {
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: Column(
        children: [
          // 로딩 텍스트
          Stack(
            children: [
              // 하얀색 스트로크 (아웃라인)
              Text(
                '당신의 이야기를 준비중...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Orbit', // Orbit 폰트 적용
                  fontSize: 16, // 기존 12에서 16으로 증가
                  fontWeight: FontWeight.bold, // 볼드 처리
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3.0 // 스트로크 두께 (서브타이틀보다 약간 얇게)
                    ..color = Colors.white, // 하얀색 스트로크
                ),
                textAlign: TextAlign.center,
              ),
              // 검정색 텍스트 (메인)
              Text(
                '당신의 이야기를 준비중...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Orbit', // Orbit 폰트 적용
                  fontSize: 16, // 기존 12에서 16으로 증가
                  fontWeight: FontWeight.bold, // 볼드 처리
                  color: Colors.black, // 검정색 메인 텍스트
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}