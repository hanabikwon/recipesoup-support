import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var flutterEngine: FlutterEngine?
    private var flutterViewController: FlutterViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Scene이 처음 연결될 때 호출
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // FlutterEngine이 AppDelegate에서 이미 생성되었으므로 가져오기
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.flutterEngine = appDelegate.flutterEngine
        }

        // Flutter ViewController 생성
        if let engine = flutterEngine {
            flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)

            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = flutterViewController
            window?.makeKeyAndVisible()
        }

        print("🎬 SceneDelegate: Scene connected")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // ✅ iOS 13+에서 앱이 스와이프로 종료될 때 실제로 호출되는 메서드
        print("🚨 SceneDelegate: Scene disconnecting (User swiped to close app)")

        // ✅ ULTRA THINK: Hive는 저장 시 이미 flush()를 수행하므로 여기서 아무것도 할 필요 없음
        // forceFlushHiveData() 제거 - 불필요하고 오히려 해로움
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 앱이 활성화될 때
        print("✅ SceneDelegate: Scene became active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 앱이 비활성화될 때 (전화 받기, 제어 센터 등)
        print("⚠️ SceneDelegate: Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 백그라운드에서 포어그라운드로 전환될 때
        print("🔆 SceneDelegate: Scene entering foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // ✅ 홈 버튼 눌렀을 때 호출
        print("🌙 SceneDelegate: Scene entered background (Home button pressed)")

        // ✅ ULTRA THINK: Hive는 저장 시 이미 flush()를 수행하므로 여기서 아무것도 할 필요 없음
        // forceFlushHiveData() 제거 - 불필요하고 오히려 해로움
    }

    // MARK: - Hive Data Flush (3-Level Fallback System)

    private func forceFlushHiveData() {
        let startTime = Date()
        print("🔥 NATIVE FLUSH START: \(startTime.timeIntervalSince1970)")

        // 1차: Flutter MethodChannel 시도 (2초 타임아웃)
        var flutterSucceeded = false
        let semaphore = DispatchSemaphore(value: 0)

        if let engine = flutterEngine {
            let channel = FlutterMethodChannel(
                name: "com.recipesoup.app/lifecycle",
                binaryMessenger: engine.binaryMessenger
            )

            channel.invokeMethod("forceFlushHiveBoxes", arguments: nil) { result in
                if let response = result as? String {
                    flutterSucceeded = (response == "success")
                    print("✅ Flutter flush response: \(response)")
                } else {
                    print("❌ Flutter flush failed: \(String(describing: result))")
                }
                semaphore.signal()
            }

            let timeout = semaphore.wait(timeout: .now() + 5.0)

            if timeout == .timedOut {
                print("⏱️ Flutter flush TIMEOUT (5 seconds)")
            } else if flutterSucceeded {
                let duration = Date().timeIntervalSince(startTime)
                print("✅ Flutter flush SUCCESS (duration: \(String(format: "%.2f", duration))s)")
                return // Flutter가 성공했으므로 네이티브 처리 생략
            }
        } else {
            print("❌ FlutterEngine not available")
        }

        // 2차: Flutter 실패 시 네이티브 Swift가 직접 파일 동기화
        print("🔧 NATIVE FALLBACK: Starting direct file sync")
        NativeHiveSync.syncHiveFiles()

        let duration = Date().timeIntervalSince(startTime)
        print("✅ NATIVE FLUSH COMPLETE (total duration: \(String(format: "%.2f", duration))s)")
    }
}