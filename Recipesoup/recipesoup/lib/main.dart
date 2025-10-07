import 'dart:io'; // 🔥 Platform.isIOS 체크용
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // 🔥 Force-close 처리를 위한 MethodChannel
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; // 🔥 Platform Channel 상태 확인용

import 'config/theme.dart';
import 'config/constants.dart';
import 'config/api_config.dart';
import 'providers/recipe_provider.dart';
import 'providers/burrow_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/message_provider.dart';
import 'services/hive_service.dart'; // 🔥 CRITICAL FIX: HiveService import 추가
import 'services/openai_service.dart'; // 🔥 ULTRA FIX: OpenAiService import 추가
import 'services/burrow_unlock_service.dart';
import 'utils/burrow_error_handler.dart';
import 'screens/splash_screen.dart';

// 🚨 CRITICAL: Hive 초기화 상태 플래그 (중복 초기화 방지)
bool _hiveInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 정상 초기화 복원 (Test 7 완료)
  print('🔧 Recipesoup: 앱 초기화 시작...');

  await initializeApp();

  // ✅ ULTRA THINK: Force-close 핸들러 제거 - 불필요함
  // Hive는 저장 시 이미 flush()를 수행하므로 앱 종료 시 추가 작업 불필요
  // _setupForceCloseHandler() 제거

  runApp(const RecipesoupApp());
}

/// ✅ ULTRA THINK FIX: 올바른 초기화 순서 (20년차 시니어 개발자 로직)
Future<void> initializeApp() async {
  print('🔧 Recipesoup: 앱 초기화 시작...');

  // ✅ STEP 1: 전역 플래그로 Hive 초기화 여부 확인
  if (_hiveInitialized) {
    print('⚠️ 전역 플래그: Hive 이미 초기화됨');

    // ✅ STEP 2: 실제로 Box가 열려있는지 재확인 (안전장치)
    try {
      if (Hive.isBoxOpen(AppConstants.recipeBoxName)) {
        print('✅ Box도 열려있음 - 완전히 안전, 초기화 생략');
        return;
      } else {
        // Box는 닫혔지만 Hive는 초기화됨 → Box만 다시 열기
        print('⚠️ Hive는 초기화됐지만 Box는 닫힘 - Box만 열기');
        await _openAllBoxes();
        return;
      }
    } catch (e) {
      // 예외 발생 → 완전 재초기화 필요
      print('❌ Box 체크 실패 - 완전 재초기화 필요: $e');
      _hiveInitialized = false; // ✅ 플래그 리셋!
    }
  }

  // 환경변수 로드 (.env 파일) - 파일이 없으면 무시
  try {
    await ApiConfig.initialize();
    print('✅ 환경변수 로드 완료');

    // API 키 검증
    if (ApiConfig.validateApiKey()) {
      print('✅ OpenAI API 키 검증 완료');
    } else {
      print('⚠️ OpenAI API 키가 설정되지 않았습니다. 이미지 분석 기능이 제한될 수 있습니다.');
    }
  } catch (e) {
    print('⚠️ .env 파일을 찾을 수 없습니다. API 기능이 제한될 수 있습니다: $e');
  }

  // ✅ STEP 3: 완전 초기화 진행 (플래그가 false이거나 에러 발생)
  // 🔥 Test 7 해결책: Hive.initFlutter() 단순화 (path_provider가 자동으로 경로 찾음)
  print('🔍 Hive 초기화 시작');

  int retryCount = 0;
  const maxRetries = 3;

  while (!_hiveInitialized && retryCount < maxRetries) {
    try {
      print('🔧 Hive 초기화 시도 ${retryCount + 1}/$maxRetries');

      // ✅ CRITICAL FIX: path_provider 2.0.15가 자동으로 올바른 경로 찾음
      await Hive.initFlutter();
      print('✅ Hive.initFlutter() 완료');

      // ✅ 모든 Box 열기 (헬퍼 함수 사용)
      await _openAllBoxes();

      print('✅✅✅ 모든 Hive Box 열기 완료 (토끼굴 시스템 포함)');
      _hiveInitialized = true; // ✅ 성공 플래그 설정 (Hot Reload 대응)
      break; // 성공 시 즉시 종료
    } catch (e, stackTrace) {
      retryCount++;
      print('⚠️ Hive 초기화 실패 (시도 $retryCount/$maxRetries)');
      print('Error: $e');

      if (retryCount < maxRetries) {
        print('🔄 ${200 * retryCount}ms 후 재시도...');
        await Future.delayed(Duration(milliseconds: 200 * retryCount));
      } else {
        // 최종 실패 - 에러 로그만 출력하고 계속 진행
        print('❌❌❌ 치명적 오류: Hive 초기화 최종 실패!');
        print('StackTrace: $stackTrace');
        print('⚠️ 앱이 제한된 기능으로 실행됩니다.');
      }
    }
  }

  print('🎉 Recipesoup: 앱 초기화 완료! (플래그: $_hiveInitialized)');
}

/// ✅ ULTRA THINK FIX: Box 열기 헬퍼 함수 (각 Box를 안전하게 열기)
Future<void> _openAllBoxes() async {
  print('🔧 Hive Box 열기 시작...');

  // 🔥 TEST 17: Box 타입을 dynamic으로 변경
  try {
    if (!Hive.isBoxOpen(AppConstants.recipeBoxName)) {
      print('📦 Opening ${AppConstants.recipeBoxName}...');
      await Hive.openBox<dynamic>(AppConstants.recipeBoxName);
      final isOpen = Hive.isBoxOpen(AppConstants.recipeBoxName);
      print('✅ ${AppConstants.recipeBoxName} Box 열림 (확인: $isOpen)');
    } else {
      print('⚠️ ${AppConstants.recipeBoxName} Box 이미 열려있음 - 스킵');
    }
  } catch (e, stackTrace) {
    print('❌ ${AppConstants.recipeBoxName} 열기 실패: $e');
    print('Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    rethrow;
  }

  if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) {
    await Hive.openBox(AppConstants.settingsBoxName);
    print('✅ ${AppConstants.settingsBoxName} Box 열림');
  } else {
    print('⚠️ ${AppConstants.settingsBoxName} Box 이미 열려있음 - 스킵');
  }

  if (!Hive.isBoxOpen(AppConstants.statsBoxName)) {
    await Hive.openBox(AppConstants.statsBoxName);
    print('✅ ${AppConstants.statsBoxName} Box 열림');
  } else {
    print('⚠️ ${AppConstants.statsBoxName} Box 이미 열려있음 - 스킵');
  }

  // 🔥 TEST 17: 토끼굴 시스템 Box도 dynamic으로 변경
  if (!Hive.isBoxOpen(AppConstants.burrowMilestonesBoxName)) {
    await Hive.openBox<dynamic>(AppConstants.burrowMilestonesBoxName);
    print('✅ ${AppConstants.burrowMilestonesBoxName} Box 열림');
  } else {
    print('⚠️ ${AppConstants.burrowMilestonesBoxName} Box 이미 열려있음 - 스킵');
  }

  if (!Hive.isBoxOpen(AppConstants.burrowProgressBoxName)) {
    await Hive.openBox<dynamic>(AppConstants.burrowProgressBoxName);
    print('✅ ${AppConstants.burrowProgressBoxName} Box 열림');
  } else {
    print('⚠️ ${AppConstants.burrowProgressBoxName} Box 이미 열려있음 - 스킵');
  }
}

class RecipesoupApp extends StatefulWidget {
  const RecipesoupApp({super.key});

  @override
  State<RecipesoupApp> createState() => _RecipesoupAppState();
}

class _RecipesoupAppState extends State<RecipesoupApp> {
  // 🔥 ARCHITECTURAL FIX: Providers를 initState에서 한 번만 생성
  HiveService? _hiveService;
  RecipeProvider? _recipeProvider;
  BurrowProvider? _burrowProvider;
  ChallengeProvider? _challengeProvider;
  MessageProvider? _messageProvider;
  OpenAiService? _openAiService;
  bool _isProvidersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    if (kDebugMode) {
      debugPrint('🎯 _RecipesoupAppState: Providers 초기화 시작...');
    }

    try {
      // ✅ CRITICAL FIX: Hive 박스 상태를 안전하게 확인하고 열기
      bool boxesReady = false;

      try {
        // 박스가 이미 열려있는지 확인
        boxesReady = Hive.isBoxOpen(AppConstants.recipeBoxName);
        if (kDebugMode) {
          debugPrint('📦 Hive 박스 상태 체크: ${boxesReady ? "이미 열려있음" : "닫혀있음"}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Hive 박스 상태 체크 실패, 초기화 필요: $e');
        }
        boxesReady = false;
      }

      // ✅ CRITICAL FIX: main()의 initializeApp()에서 이미 초기화했으므로
      // 여기서는 단순히 Box가 열려있는지만 확인
      if (!boxesReady) {
        // Box가 안 열렸다면 앱 초기화 문제 → 에러 처리
        throw Exception('Hive 박스가 열리지 않았습니다. main() 초기화를 확인하세요.');
      }

      if (kDebugMode) {
        debugPrint('✅ Hive 박스 사용 준비 완료 (main()에서 이미 초기화됨)');
      }

      // 🔥 TEST 18: Hive 박스 최종 확인 (타입 파라미터 없이 가져오기!)
      if (Hive.isBoxOpen(AppConstants.recipeBoxName)) {
        final box = Hive.box(AppConstants.recipeBoxName); // 타입 파라미터 제거!
        if (kDebugMode) {
          debugPrint('✅ Hive 박스 최종 확인: isOpen=${box.isOpen}, 레시피 수=${box.length}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Hive 박스가 열려있지 않음 - 예상치 못한 상태');
        }
      }

      // ✅ 서비스 인스턴스 생성
      _hiveService = HiveService();
      _openAiService = OpenAiService();

      if (kDebugMode) {
        debugPrint('🔥 서비스 생성 완료: HiveService(${_hiveService.hashCode})');
      }

      // ✅ Provider 인스턴스 생성
      _recipeProvider = RecipeProvider(hiveService: _hiveService!);

      final burrowUnlockService = BurrowUnlockService(hiveService: _hiveService!);
      _burrowProvider = BurrowProvider(unlockCoordinator: burrowUnlockService);

      _challengeProvider = ChallengeProvider();
      _messageProvider = MessageProvider();

      // 🔥 CRITICAL FIX: 콜백 연결을 동기적으로 수행 (race condition 방지)
      // RecipeProvider ↔ BurrowProvider 양방향 연결
      _recipeProvider!.setBurrowCallbacks(
        onRecipeAdded: _burrowProvider!.onRecipeAdded,
        onRecipeUpdated: _burrowProvider!.onRecipeUpdated,
        onRecipeDeleted: _burrowProvider!.onRecipeDeleted,
      );
      _burrowProvider!.setRecipeListCallback(() => _recipeProvider!.recipes);

      if (kDebugMode) {
        debugPrint('🔥 모든 Provider 인스턴스 생성 완료');
        debugPrint('✅ Provider 간 콜백 연결 완료 (동기적)');
      }

      // ✅ 상태 업데이트 (UI 재렌더링)
      if (mounted) {
        setState(() {
          _isProvidersInitialized = true;
        });
        if (kDebugMode) {
          debugPrint('✅ UI 상태 업데이트 완료 (_isProvidersInitialized = true)');
        }
      }

      // ✅ BurrowProvider 초기화 (Provider tree에 등록된 후)
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        try {
          await _burrowProvider!.initialize();
          if (kDebugMode) {
            debugPrint('✅ BurrowProvider 초기화 완료');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ BurrowProvider 초기화 실패 (계속 진행): $e');
          }
        }

        // RecipeProvider 데이터 로드
        _recipeProvider!.loadRecipes();
        _messageProvider!.initialize();

        if (kDebugMode) {
          debugPrint('✅ 모든 Provider 데이터 로드 시작');
        }
      }

      if (kDebugMode) {
        debugPrint('🎉 _initializeProviders() 완료!');
      }

      // ✅ 성공 시 플래그 설정
      if (mounted) {
        setState(() {
          _isProvidersInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Provider 초기화 실패: $e');
      debugPrint('Stack trace: $stackTrace');

      // ✅ CRITICAL FIX: 재귀 호출 제거 (main()에서 이미 Hive 초기화 완료)
      // Hive가 정상적으로 초기화되지 않았다면 앱을 실행할 수 없음
      debugPrint('❌ 앱 초기화 실패 - 제한된 모드로 앱 실행');

      // 제한된 기능으로 앱 실행 (에러 화면 표시)
      if (mounted) {
        setState(() {
          _isProvidersInitialized = true; // 무한 루프 방지
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Providers가 준비될 때까지 SplashScreen 표시
    if (!_isProvidersInitialized) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.vintageIvoryTheme,
        home: const SplashScreen(),
      );
    }

    // ✅ Providers 준비 완료 - 메인 앱 렌더링
    // Null 체크: Provider가 null이면 다시 SplashScreen으로
    if (_recipeProvider == null || _burrowProvider == null ||
        _challengeProvider == null || _messageProvider == null ||
        _openAiService == null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.vintageIvoryTheme,
        home: const SplashScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _recipeProvider!),
        ChangeNotifierProvider.value(value: _burrowProvider!),
        ChangeNotifierProvider.value(value: _challengeProvider!),
        ChangeNotifierProvider.value(value: _messageProvider!),
        Provider.value(value: _openAiService!),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.vintageIvoryTheme,
        home: Builder(
          builder: (context) {
            // ✅ BurrowProvider 초기화 (Provider가 이미 등록된 후)
            Future.microtask(() async {
              try {
                await _burrowProvider?.initialize();
                if (kDebugMode) {
                  debugPrint('✅ BurrowProvider 초기화 완료');
                }

                // 초기화 완료 후 콜백 연결
                if (mounted) {
                  _connectProviderCallbacks(context);
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ BurrowProvider 초기화 실패: $e');
                }
              }
            });

            return const SplashScreen();
          },
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

/// Provider 간 콜백 연결 함수 (포괄적 에러 처리)
void _connectProviderCallbacks(BuildContext context) {
  try {
    // Provider 접근 (listen: false로 리빌드 방지)
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final burrowProvider = Provider.of<BurrowProvider>(context, listen: false);
    
    // 🔥 CRITICAL FIX: 양방향 콜백 연결
    
    // 1. BurrowProvider의 콜백 메서드를 RecipeProvider에 등록
    recipeProvider.setBurrowCallbacks(
      onRecipeAdded: burrowProvider.onRecipeAdded,
      onRecipeUpdated: burrowProvider.onRecipeUpdated,
      onRecipeDeleted: burrowProvider.onRecipeDeleted,
    );
    
    // 🔥 ULTRA FIX: 2. RecipeProvider의 레시피 리스트를 BurrowProvider에 제공
    burrowProvider.setRecipeListCallback(() => recipeProvider.recipes);
    
    if (kDebugMode) {
      debugPrint('✅ Provider 간 양방향 콜백 연결 완료: RecipeProvider ↔ BurrowProvider');
    }
    
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Provider 콜백 연결 실패: $e');
    }
    
    // 콜백 연결 실패시 에러 핸들러를 통한 복구 시도
    BurrowErrorHandler.handleCallbackConnectionFailure(context).then((recovered) {
      if (recovered) {
        if (kDebugMode) {
          debugPrint('✅ Provider 콜백 연결 복구 완료');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Provider 콜백 연결 복구 실패 - 토끼굴은 수동 업데이트 모드로 동작');
        }
      }
    });
  }
}