import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeApp();
  
  runApp(const RecipesoupApp());
}

Future<void> initializeApp() async {
  try {
    // 환경변수 로드 (.env 파일) - 파일이 없으면 무시
    try {
      await ApiConfig.initialize();
      debugPrint('✅ 환경변수 로드 완료');
      
      // API 키 검증
      if (ApiConfig.validateApiKey()) {
        debugPrint('✅ OpenAI API 키 검증 완료');
      } else {
        debugPrint('⚠️ OpenAI API 키가 설정되지 않았습니다. 이미지 분석 기능이 제한될 수 있습니다.');
      }
    } catch (e) {
      debugPrint('⚠️ .env 파일을 찾을 수 없습니다. API 기능이 제한될 수 있습니다: $e');
    }
    
    // JSON 기반 Hive 초기화 (TypeAdapter 없이 동작)
    await Hive.initFlutter();
    debugPrint('✅ Hive 초기화 완료');
    
    // JSON Box 열기 (HiveService에서 Box<Map<String, dynamic>> 사용)
    await Hive.openBox<Map<String, dynamic>>(AppConstants.recipeBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.statsBoxName);
    
    // 토끼굴 시스템 Box 열기
    await Hive.openBox<Map<String, dynamic>>(AppConstants.burrowMilestonesBoxName);
    await Hive.openBox<Map<String, dynamic>>(AppConstants.burrowProgressBoxName);
    debugPrint('✅ Hive Box 열기 완료 (토끼굴 시스템 포함)');
    
  } catch (e) {
    debugPrint('❌ 앱 초기화 중 오류 발생: $e');
    // 초기화 실패해도 앱은 계속 실행되도록 함
  }
}

class RecipesoupApp extends StatefulWidget {
  const RecipesoupApp({super.key});

  @override
  State<RecipesoupApp> createState() => _RecipesoupAppState();
}

class _RecipesoupAppState extends State<RecipesoupApp> {

  @override
  void initState() {
    super.initState();
    _waitForInitialization();
  }

  void _waitForInitialization() async {
    // 백그라운드에서 초기화 (SplashScreen이 이미 표시된 상태)
    await Future.delayed(Duration(milliseconds: 100)); // 최소 delay
    
    // Hive 박스 확인 (에러가 있어도 계속 진행)
    try {
      final box = Hive.box<Map<String, dynamic>>(AppConstants.recipeBoxName);
      debugPrint('✅ Hive 박스 확인 완료: ${box.isOpen}');
    } catch (e) {
      debugPrint('⚠️ Hive 박스 확인 실패: $e');
    }
    
    if (mounted) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 상태와 관계없이 바로 SplashScreen 표시

    // 🔥 CRITICAL FIX: HiveService 싱글톤 인스턴스 생성
    final hiveServiceSingleton = HiveService();
    debugPrint('🔥 MAIN DEBUG: Created HiveService singleton with hashCode: ${hiveServiceSingleton.hashCode}');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = RecipeProvider(hiveService: hiveServiceSingleton); // 🔥 CRITICAL: 동일 인스턴스 전달
          debugPrint('🔥 MAIN DEBUG: RecipeProvider using HiveService: ${hiveServiceSingleton.hashCode}');
          // 앱 시작시 레시피 로드 (Hive 초기화 완료 후)
          Future.microtask(() => provider.loadRecipes());
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final service = BurrowUnlockService(hiveService: hiveServiceSingleton);
          final provider = BurrowProvider(unlockCoordinator: service);
          debugPrint('🔥 MAIN DEBUG: BurrowProvider using BurrowUnlockService');
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = ChallengeProvider();
          debugPrint('🔥 MAIN DEBUG: ChallengeProvider 초기화 완료');
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = MessageProvider();
          debugPrint('🔥 MAIN DEBUG: MessageProvider 초기화 완료');
          // 앱 시작시 메시지 로드
          Future.microtask(() => provider.initialize());
          return provider;
        }),
        // 🔥 ULTRA FIX: OpenAiService Provider 추가 (냉장고 재료 추천 에러 해결)
        Provider(create: (_) {
          final service = OpenAiService();
          debugPrint('🔥 MAIN DEBUG: OpenAiService Provider 등록 완료');
          return service;
        }),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.vintageIvoryTheme,
        home: Builder(
          builder: (context) {
            // MaterialApp이 생성된 후에 BurrowProvider 초기화
            final burrowProvider = Provider.of<BurrowProvider>(context, listen: false);
            Future.microtask(() async {
              await _initializeBurrowProvider(burrowProvider, context);
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

/// BurrowProvider 초기화 (포괄적 에러 처리)
Future<void> _initializeBurrowProvider(BurrowProvider provider, BuildContext context) async {
  try {
    await provider.initialize();
    debugPrint('✅ BurrowProvider 초기화 완료');
    
    // 초기화 완료 후 즉시 콜백 연결 (타이밍 이슈 해결)
    _connectProviderCallbacks(context);
  } catch (e) {
    debugPrint('❌ BurrowProvider 초기화 실패: $e');
    
    // 초기화 실패시 에러 핸들러를 통한 복구 시도
    final recovered = await BurrowErrorHandler.handleProviderInitializationFailure(
      e, 
      () => provider.initialize()
    );
    
    if (recovered) {
      debugPrint('✅ BurrowProvider 복구 완료');
      // 복구 성공시 콜백 연결
      _connectProviderCallbacks(context);
    } else {
      debugPrint('❌ BurrowProvider 복구 실패 - 제한된 기능으로 동작');
    }
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
    
    debugPrint('✅ Provider 간 양방향 콜백 연결 완료: RecipeProvider ↔ BurrowProvider');
    
  } catch (e) {
    debugPrint('❌ Provider 콜백 연결 실패: $e');
    
    // 콜백 연결 실패시 에러 핸들러를 통한 복구 시도
    BurrowErrorHandler.handleCallbackConnectionFailure(context).then((recovered) {
      if (recovered) {
        debugPrint('✅ Provider 콜백 연결 복구 완료');
      } else {
        debugPrint('❌ Provider 콜백 연결 복구 실패 - 토끼굴은 수동 업데이트 모드로 동작');
      }
    });
  }
}