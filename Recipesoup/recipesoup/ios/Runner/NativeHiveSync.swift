import Foundation

/// 네이티브 Swift 코드로 Hive 파일을 직접 동기화하는 유틸리티
/// Flutter MethodChannel 실패 시 Fallback으로 사용
class NativeHiveSync {

    /// Hive 파일들을 찾아서 fsync() 호출로 강제 디스크 동기화
    static func syncHiveFiles() {
        let fileManager = FileManager.default

        // ✅ FIX: Hive.initFlutter()는 Documents 디렉토리를 사용함
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ NativeHiveSync: Could not find Documents directory")
            return
        }

        // Hive가 저장하는 디렉토리 경로 (Hive.initFlutter()에서 자동 생성)
        let hiveDir = documentsDir

        print("🔍 NativeHiveSync: Searching for Hive files in: \(hiveDir.path)")

        // 디렉토리가 존재하는지 확인
        guard fileManager.fileExists(atPath: hiveDir.path) else {
            print("⚠️ NativeHiveSync: Hive directory does not exist yet: \(hiveDir.path)")
            return
        }

        // 디렉토리 내 모든 파일 검색
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: hiveDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        ) else {
            print("❌ NativeHiveSync: Failed to list directory contents")
            return
        }

        var syncedCount = 0
        var failedCount = 0

        // Hive 관련 파일들 (.hive, .lock, .hive.compact) 찾아서 동기화
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent
            let ext = fileURL.pathExtension

            // Hive 파일 확인 (.hive, .lock 등)
            if ext == "hive" || ext == "lock" || filename.contains(".hive.") {
                let success = syncFile(at: fileURL)
                if success {
                    syncedCount += 1
                    print("✅ NativeHiveSync: Synced file: \(filename)")
                } else {
                    failedCount += 1
                    print("❌ NativeHiveSync: Failed to sync file: \(filename)")
                }
            }
        }

        // 최종 결과 출력
        if syncedCount > 0 {
            print("✅ NativeHiveSync: Successfully synced \(syncedCount) files (failed: \(failedCount))")
        } else {
            print("⚠️ NativeHiveSync: No Hive files found to sync")
        }

        // 3차: UserDefaults에 "마지막 네이티브 동기화 시간" 기록
        UserDefaults.standard.set(Date(), forKey: "lastNativeHiveSync")
        UserDefaults.standard.synchronize()
        print("📝 NativeHiveSync: Saved last sync timestamp to UserDefaults")
    }

    /// 개별 파일을 fsync()로 디스크에 강제 쓰기
    /// - Parameter fileURL: 동기화할 파일의 URL
    /// - Returns: 성공 여부
    private static func syncFile(at fileURL: URL) -> Bool {
        let filePath = fileURL.path

        // 파일을 읽기 전용으로 열기 (O_RDONLY)
        let fileDescriptor = open(filePath, O_RDONLY)

        guard fileDescriptor >= 0 else {
            print("❌ NativeHiveSync: Failed to open file: \(filePath) (errno: \(errno))")
            return false
        }

        // fsync() 호출: 커널 버퍼의 데이터를 물리적 디스크에 즉시 쓰기
        let syncResult = fsync(fileDescriptor)

        // 파일 닫기
        close(fileDescriptor)

        if syncResult == 0 {
            return true
        } else {
            print("❌ NativeHiveSync: fsync() failed for file: \(filePath) (errno: \(errno))")
            return false
        }
    }

    /// 마지막 네이티브 동기화 시간 확인 (디버깅용)
    static func getLastSyncTime() -> Date? {
        return UserDefaults.standard.object(forKey: "lastNativeHiveSync") as? Date
    }

    /// 전체 Hive 디렉토리 정보 출력 (디버깅용)
    static func debugPrintHiveDirectory() {
        let fileManager = FileManager.default

        // ✅ FIX: Documents 디렉토리 사용
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ NativeHiveSync DEBUG: Could not find Documents directory")
            return
        }

        let hiveDir = documentsDir

        print("🔍 NativeHiveSync DEBUG: Hive directory path: \(hiveDir.path)")

        guard fileManager.fileExists(atPath: hiveDir.path) else {
            print("⚠️ NativeHiveSync DEBUG: Hive directory does not exist")
            return
        }

        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: hiveDir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: []
        ) else {
            print("❌ NativeHiveSync DEBUG: Failed to list directory contents")
            return
        }

        print("📂 NativeHiveSync DEBUG: Found \(fileURLs.count) files:")
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent

            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64,
               let modDate = attributes[.modificationDate] as? Date {
                let sizeKB = Double(fileSize) / 1024.0
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let modDateStr = dateFormatter.string(from: modDate)

                print("  📄 \(filename): \(String(format: "%.2f", sizeKB)) KB, modified: \(modDateStr)")
            } else {
                print("  📄 \(filename)")
            }
        }

        if let lastSync = getLastSyncTime() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            print("⏰ Last native sync: \(dateFormatter.string(from: lastSync))")
        } else {
            print("⏰ No native sync recorded yet")
        }
    }
}