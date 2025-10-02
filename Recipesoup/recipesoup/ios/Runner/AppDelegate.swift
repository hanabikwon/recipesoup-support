import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // ✅ FlutterEngine을 SceneDelegate와 공유하기 위해 전역 변수로 선언
  var flutterEngine: FlutterEngine?
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 🔥 CRITICAL FIX: FlutterEngine 초기화 및 플러그인 강제 재등록
    flutterEngine = FlutterEngine(name: "recipesoup_engine")
    flutterEngine?.run()

    // 🚨 path_provider Platform Channel 준비를 위한 강제 등록
    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
      print("✅ iOS: Plugins registered with FlutterEngine")
    }

    // Legacy 호환성 (FlutterAppDelegate 기본 등록)
    GeneratedPluginRegistrant.register(with: self)

    print("✅ iOS: AppDelegate initialized with FlutterEngine")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ iOS 13+ Scene 지원 활성화
  @available(iOS 13.0, *)
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    print("🎬 iOS: Creating scene configuration")
    let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = SceneDelegate.self
    return sceneConfig
  }

  // LEGACY: iOS 12 이하에서만 호출됨 (iOS 13+는 SceneDelegate 사용)
  override func applicationWillTerminate(_ application: UIApplication) {
    print("🚨 iOS: applicationWillTerminate CALLED (Legacy - iOS 12 or below)")

    // iOS 12 이하에서도 네이티브 동기화 시도
    NativeHiveSync.syncHiveFiles()

    super.applicationWillTerminate(application)
  }

  // LEGACY: iOS 12 이하 백그라운드 처리
  override func applicationDidEnterBackground(_ application: UIApplication) {
    print("📱 iOS: App entered background (Legacy)")

    // iOS 12 이하에서도 네이티브 동기화
    NativeHiveSync.syncHiveFiles()

    super.applicationDidEnterBackground(application)
  }

  // Background Task 종료 헬퍼 메서드
  private func endBackgroundTask() {
    if backgroundTask != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
  }
}
