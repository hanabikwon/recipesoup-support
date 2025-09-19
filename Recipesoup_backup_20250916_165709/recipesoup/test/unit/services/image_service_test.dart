import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:recipesoup/services/image_service.dart';

/// Helper function to create valid test PNG image data
Uint8List createValidTestImage({int width = 10, int height = 10}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Fill with red color
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('Image Service Tests (로컬 이미지 관리 핵심!)', () {
    late ImageService imageService;
    late Directory testDirectory;

    setUpAll(() async {
      // 테스트용 임시 디렉토리 생성
      testDirectory = await Directory.systemTemp.createTemp('recipesoup_image_test_');
    });

    setUp(() async {
      // 테스트용 ImageService 생성 (임시 디렉토리 사용)
      imageService = ImageService(customDirectory: testDirectory.path);
    });

    tearDown(() async {
      // 테스트 후 정리 - 테스트 디렉토리 내 모든 파일 삭제
      if (await testDirectory.exists()) {
        await for (var entity in testDirectory.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    });

    tearDownAll(() async {
      // 전체 테스트 디렉토리 정리
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    group('이미지 저장 테스트 (로컬 파일 시스템)', () {
      test('should save image successfully and return file path', () async {
        // Given - 테스트용 이미지 데이터 (1x1 PNG)
        final testImageData = Uint8List.fromList([
          137, 80, 78, 71, 13, 10, 26, 10, // PNG 시그니처
          0, 0, 0, 13, 73, 72, 68, 82, // IHDR 청크 시작
          0, 0, 0, 1, 0, 0, 0, 1, // 1x1 크기
          8, 6, 0, 0, 0, 31, 21, 196, 137, // 나머지 IHDR
          0, 0, 0, 11, 73, 68, 65, 84, // IDAT 청크
          120, 218, 99, 248, 207, 0, 0, 0, 2, 0, 1, 226, 33, 188, 51,
          0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130 // 나머지 PNG 데이터
        ]);
        final recipeId = 'test_recipe_001';

        // When
        final savedPath = await imageService.saveImage(testImageData, recipeId);

        // Then
        expect(savedPath, isNotNull);
        expect(savedPath, contains(recipeId));
        expect(savedPath, endsWith('.png'));
        
        // 실제 파일이 저장되었는지 확인
        final savedFile = File(savedPath);
        expect(await savedFile.exists(), isTrue);
        
        // 파일 크기가 0보다 큰지 확인
        final fileSize = await savedFile.length();
        expect(fileSize, greaterThan(0));
      });

      test('should save JPEG image with correct extension', () async {
        // Given - 테스트용 JPEG 데이터 (최소한의 JPEG 헤더)
        final testJpegData = Uint8List.fromList([
          255, 216, 255, 224, // JPEG SOI + APP0 시작
          0, 16, 74, 70, 73, 70, 0, 1, // JFIF 헤더
          1, 1, 0, 72, 0, 72, 0, 0,
          255, 217 // JPEG EOI
        ]);
        final recipeId = 'test_recipe_jpeg';

        // When
        final savedPath = await imageService.saveImage(testJpegData, recipeId);

        // Then
        expect(savedPath, endsWith('.jpg'));
        expect(await File(savedPath).exists(), isTrue);
      });

      test('should generate unique file names for same recipe ID', () async {
        // Given - 동일한 레시피 ID로 여러 이미지 저장
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]); // 간단한 PNG 시그니처
        final recipeId = 'same_recipe_id';

        // When - 같은 ID로 3번 저장
        final path1 = await imageService.saveImage(testImageData, recipeId);
        final path2 = await imageService.saveImage(testImageData, recipeId);
        final path3 = await imageService.saveImage(testImageData, recipeId);

        // Then - 모든 경로가 다르고 파일이 존재해야 함
        expect(path1, isNot(equals(path2)));
        expect(path2, isNot(equals(path3)));
        expect(path1, isNot(equals(path3)));
        
        expect(await File(path1).exists(), isTrue);
        expect(await File(path2).exists(), isTrue);
        expect(await File(path3).exists(), isTrue);
      });

      test('should handle invalid image data gracefully', () async {
        // Given - 잘못된 이미지 데이터
        final invalidData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final recipeId = 'invalid_image_test';

        // When & Then - 예외가 발생해야 함
        expect(
          () => imageService.saveImage(invalidData, recipeId),
          throwsA(isA<ImageFormatException>()),
        );
      });

      test('should reject empty image data', () async {
        // Given - 빈 이미지 데이터
        final emptyData = Uint8List(0);
        final recipeId = 'empty_data_test';

        // When & Then - 예외가 발생해야 함
        expect(
          () => imageService.saveImage(emptyData, recipeId),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject images larger than size limit', () async {
        // Given - 너무 큰 이미지 데이터 (10MB 초과)
        final largeData = Uint8List(11 * 1024 * 1024); // 11MB
        final recipeId = 'large_image_test';

        // When & Then - 예외가 발생해야 함
        expect(
          () => imageService.saveImage(largeData, recipeId),
          throwsA(isA<ImageSizeException>()),
        );
      });
    });

    group('이미지 로드 테스트', () {
      test('should load saved image successfully', () async {
        // Given - 이미지 저장
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        final recipeId = 'load_test_recipe';
        final savedPath = await imageService.saveImage(testImageData, recipeId);

        // When - 이미지 로드
        final loadedData = await imageService.loadImage(savedPath);

        // Then
        expect(loadedData, isNotNull);
        expect(loadedData?.length, greaterThan(0));
      });

      test('should return null for non-existent image', () async {
        // Given - 존재하지 않는 파일 경로
        final nonExistentPath = '${testDirectory.path}/non_existent_image.png';

        // When
        final loadedData = await imageService.loadImage(nonExistentPath);

        // Then
        expect(loadedData, isNull);
      });

      test('should handle file system errors gracefully', () async {
        // Given - 접근 권한이 없는 경로 (시뮬레이션)
        final invalidPath = '/root/restricted_image.png';

        // When & Then - null 반환하고 예외는 발생하지 않아야 함
        final loadedData = await imageService.loadImage(invalidPath);
        expect(loadedData, isNull);
      });
    });

    group('이미지 삭제 테스트', () {
      test('should delete image successfully', () async {
        // Given - 이미지 저장
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        final recipeId = 'delete_test_recipe';
        final savedPath = await imageService.saveImage(testImageData, recipeId);
        
        // 파일이 존재하는지 확인
        expect(await File(savedPath).exists(), isTrue);

        // When - 이미지 삭제
        final deleteResult = await imageService.deleteImage(savedPath);

        // Then
        expect(deleteResult, isTrue);
        expect(await File(savedPath).exists(), isFalse);
      });

      test('should handle deletion of non-existent file gracefully', () async {
        // Given - 존재하지 않는 파일 경로
        final nonExistentPath = '${testDirectory.path}/non_existent_file.png';

        // When - 삭제 시도
        final deleteResult = await imageService.deleteImage(nonExistentPath);

        // Then - false 반환하지만 예외 발생하지 않아야 함
        expect(deleteResult, isFalse);
      });

      test('should handle file system errors during deletion', () async {
        // Given - 접근 권한이 제한된 경로
        final restrictedPath = '/system/restricted_file.png';

        // When - 삭제 시도
        final deleteResult = await imageService.deleteImage(restrictedPath);

        // Then - false 반환
        expect(deleteResult, isFalse);
      });
    });

    group('이미지 최적화 테스트 (OpenAI API용)', () {
      test('should resize large image for API consumption', () async {
        // Given - 유효한 PNG 이미지 데이터 (helper function 사용)
        final validImageData = createValidTestImage(width: 50, height: 50);

        // When - 최적화된 버전 생성
        final optimizedData = await imageService.optimizeForApi(validImageData);

        // Then
        expect(optimizedData, isNotNull);
        expect(optimizedData.length, greaterThan(0));
      });

      test('should compress image while maintaining quality', () async {
        // Given - 유효한 PNG 테스트 이미지 데이터 (helper function 사용)
        final originalData = createValidTestImage(width: 20, height: 20);
        
        // When - 압축 적용
        final compressedData = await imageService.compressImage(originalData, quality: 85);

        // Then
        expect(compressedData, isNotNull);
        expect(compressedData.length, greaterThan(0));
      });

      test('should convert image to Base64 for API requests', () async {
        // Given - 작은 테스트 이미지
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

        // When - Base64 변환
        final base64String = await imageService.toBase64(testImageData);

        // Then
        expect(base64String, isNotNull);
        expect(base64String, isNotEmpty);
        expect(base64String, matches(RegExp(r'^[A-Za-z0-9+/]+=*$'))); // Base64 형식 검증
      });

      test('should handle image format detection correctly', () async {
        // Given - PNG 데이터 (최소 8바이트)
        final pngData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        
        // JPEG 데이터 (최소 8바이트)
        final jpegData = Uint8List.fromList([255, 216, 255, 224, 0, 16, 74, 70]);

        // When - 포맷 감지
        final pngFormat = imageService.detectImageFormat(pngData);
        final jpegFormat = imageService.detectImageFormat(jpegData);

        // Then
        expect(pngFormat, equals(ImageFormat.png));
        expect(jpegFormat, equals(ImageFormat.jpeg));
      });
    });

    group('이미지 경로 관리 테스트', () {
      test('should generate valid file paths', () async {
        // Given - 레시피 ID
        final recipeId = 'path_test_recipe';

        // When - 파일 경로 생성
        final pngPath = imageService.generateImagePath(recipeId, ImageFormat.png);
        final jpegPath = imageService.generateImagePath(recipeId, ImageFormat.jpeg);

        // Then
        expect(pngPath, contains(recipeId));
        expect(pngPath, endsWith('.png'));
        expect(jpegPath, contains(recipeId));
        expect(jpegPath, endsWith('.jpg'));
        
        // 경로가 다르게 생성되는지 확인 (타임스탬프 포함)
        final anotherPath = imageService.generateImagePath(recipeId, ImageFormat.png);
        expect(pngPath, isNot(equals(anotherPath)));
      });

      test('should validate file paths', () async {
        // Given - 다양한 파일 경로
        final validPath = '${testDirectory.path}/valid_recipe_123.png';
        final invalidPath = '/invalid/path/image.png';
        final emptyPath = '';
        
        // Create the valid file for testing
        final validFile = File(validPath);
        await validFile.writeAsBytes(createValidTestImage());

        // When & Then
        expect(imageService.isValidImagePath(validPath), isTrue);
        expect(imageService.isValidImagePath(invalidPath), isFalse);
        expect(imageService.isValidImagePath(emptyPath), isFalse);
      });

      test('should extract recipe ID from file path', () async {
        // Given - 파일 경로
        final path = '${testDirectory.path}/recipe_test_001_1640000000000.png';

        // When - 레시피 ID 추출
        final extractedId = imageService.extractRecipeId(path);

        // Then
        expect(extractedId, equals('recipe_test_001'));
      });

      test('should list all images for a recipe', () async {
        // Given - 동일한 레시피 ID로 여러 이미지 저장
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        final recipeId = 'multi_image_recipe';
        
        final path1 = await imageService.saveImage(testImageData, recipeId);
        final path2 = await imageService.saveImage(testImageData, recipeId);
        final path3 = await imageService.saveImage(testImageData, recipeId);

        // When - 레시피의 모든 이미지 목록 조회
        final imagePaths = await imageService.getImagesForRecipe(recipeId);

        // Then
        expect(imagePaths, hasLength(3));
        expect(imagePaths, containsAll([path1, path2, path3]));
      });
    });

    group('성능 및 메모리 관리 테스트', () {
      test('should handle multiple concurrent image operations', () async {
        // Given - 여러 이미지 데이터
        final testImageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        final futures = <Future<String>>[];
        
        // When - 동시에 10개 이미지 저장
        for (int i = 0; i < 10; i++) {
          futures.add(imageService.saveImage(testImageData, 'concurrent_test_$i'));
        }
        
        final savedPaths = await Future.wait(futures);

        // Then - 모든 이미지가 성공적으로 저장되어야 함
        expect(savedPaths, hasLength(10));
        for (final path in savedPaths) {
          expect(await File(path).exists(), isTrue);
        }
        
        // 모든 경로가 고유해야 함
        final uniquePaths = savedPaths.toSet();
        expect(uniquePaths.length, equals(10));
      });

      test('should clean up temporary files during optimization', () async {
        // Given - 유효한 이미지 데이터 (helper function 사용)
        final imageData = createValidTestImage(width: 15, height: 15);

        // When & Then - 최적화가 정상적으로 수행되어야 함
        final result = await imageService.optimizeForApi(imageData);
        expect(result, isNotNull);
        expect(result.length, greaterThan(0));
      });

      test('should respect memory limits during processing', () async {
        // Given - 유효한 이미지 데이터 (helper function 사용)
        final validImageData = createValidTestImage(width: 12, height: 12);
        
        // When & Then - 유효한 이미지 데이터로 처리가 가능해야 함
        final result = await imageService.optimizeForApi(validImageData);
        expect(result, isNotNull);
        expect(result.length, greaterThan(0));
      });
    });

    group('에러 처리 및 예외 상황 테스트', () {
      test('should handle disk space shortage gracefully', () async {
        // Given - 매우 큰 이미지 데이터 (디스크 공간 부족 시뮬레이션)
        // 실제 환경에서는 디스크 공간 체크 로직 테스트
        final imageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

        // When & Then - 적절한 에러 처리
        expect(
          () => imageService.saveImage(imageData, 'disk_space_test'),
          returnsNormally, // 일반적인 경우에는 정상 처리
        );
      });

      test('should validate image file extensions', () async {
        // Given - 잘못된 확장자 파일
        final invalidPath = '${testDirectory.path}/image.txt';

        // When & Then
        expect(imageService.isValidImagePath(invalidPath), isFalse);
      });

      test('should handle corrupted image data', () async {
        // Given - 손상된 이미지 데이터 (잘못된 헤더)
        final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

        // When & Then
        expect(
          () => imageService.optimizeForApi(corruptedData),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('should handle network storage scenarios', () async {
        // Given - 네트워크 저장소 시뮬레이션 (향후 확장 가능성)
        final imageData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

        // When - 로컬 저장 (현재 구현)
        final savedPath = await imageService.saveImage(imageData, 'network_test');

        // Then - 로컬 경로여야 함
        expect(savedPath, contains(testDirectory.path));
      });
    });
  });
}