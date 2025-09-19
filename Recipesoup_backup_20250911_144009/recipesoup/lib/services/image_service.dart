import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// 로컬 이미지 관리 서비스
/// Recipesoup 앱의 요리 사진 저장, 로드, 삭제, 최적화를 담당
class ImageService {
  static const String _imageDirectory = 'recipe_images';
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int _apiMaxSize = 2 * 1024 * 1024; // 2MB (OpenAI API용)
  static const int _defaultQuality = 85;
  
  final String? _customDirectory;
  String? _cachedStoragePath;

  ImageService({String? customDirectory}) : _customDirectory = customDirectory;

  /// 이미지 저장소 경로 획득
  Future<String> get _storagePath async {
    if (_cachedStoragePath != null) {
      return _cachedStoragePath!;
    }

    if (_customDirectory != null) {
      _cachedStoragePath = _customDirectory;
      return _cachedStoragePath!;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${documentsDir.path}/$_imageDirectory');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      _cachedStoragePath = imageDir.path;
      return _cachedStoragePath!;
    } catch (e) {
      developer.log('Failed to get storage path: $e', name: 'ImageService');
      throw Exception('Failed to initialize image storage: $e');
    }
  }

  /// 이미지 저장
  Future<String> saveImage(Uint8List imageData, String recipeId) async {
    try {
      // 입력 검증
      if (imageData.isEmpty) {
        throw ArgumentError('Image data cannot be empty');
      }
      
      if (imageData.length > _maxImageSize) {
        throw ImageSizeException('Image size exceeds maximum limit of ${_maxImageSize / (1024 * 1024)}MB');
      }

      // 이미지 포맷 감지
      final format = detectImageFormat(imageData);
      if (format == ImageFormat.unknown) {
        throw ImageFormatException('Unsupported image format');
      }

      // 저장소 경로 확인
      final storagePath = await _storagePath;
      
      // 파일 경로 생성
      final filePath = _generateImagePath(storagePath, recipeId, format);
      
      // 파일 저장
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      
      developer.log('Image saved: $filePath', name: 'ImageService');
      return filePath;
    } catch (e) {
      developer.log('Failed to save image: $e', name: 'ImageService');
      rethrow;
    }
  }

  /// 이미지 로드
  Future<Uint8List?> loadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (!await file.exists()) {
        return null;
      }
      
      final imageData = await file.readAsBytes();
      return Uint8List.fromList(imageData);
    } catch (e) {
      developer.log('Failed to load image: $e', name: 'ImageService');
      return null;
    }
  }

  /// 이미지 삭제
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (!await file.exists()) {
        return false;
      }
      
      await file.delete();
      developer.log('Image deleted: $imagePath', name: 'ImageService');
      return true;
    } catch (e) {
      developer.log('Failed to delete image: $e', name: 'ImageService');
      return false;
    }
  }

  /// OpenAI API용 이미지 최적화
  Future<Uint8List> optimizeForApi(Uint8List imageData) async {
    try {
      // 이미지 디코딩
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw ImageProcessingException('Failed to decode image');
      }

      // 크기 조정 (최대 1024x1024)
      final resized = _resizeImage(image, maxWidth: 1024, maxHeight: 1024);
      
      // JPEG로 압축 (품질 85)
      final compressedData = img.encodeJpg(resized, quality: _defaultQuality);
      final result = Uint8List.fromList(compressedData);
      
      // API 크기 제한 확인
      if (result.length > _apiMaxSize) {
        // 품질을 낮춰서 재압축
        final recompressed = img.encodeJpg(resized, quality: 70);
        return Uint8List.fromList(recompressed);
      }
      
      return result;
    } catch (e) {
      developer.log('Failed to optimize image for API: $e', name: 'ImageService');
      rethrow;
    }
  }

  /// 이미지 압축
  Future<Uint8List> compressImage(Uint8List imageData, {int quality = 85}) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw ImageProcessingException('Failed to decode image for compression');
      }
      
      final compressedData = img.encodeJpg(image, quality: quality);
      return Uint8List.fromList(compressedData);
    } catch (e) {
      developer.log('Failed to compress image: $e', name: 'ImageService');
      rethrow;
    }
  }

  /// Base64 인코딩 (OpenAI API 요청용)
  Future<String> toBase64(Uint8List imageData) async {
    try {
      return base64Encode(imageData);
    } catch (e) {
      developer.log('Failed to encode image to Base64: $e', name: 'ImageService');
      rethrow;
    }
  }

  /// 이미지 포맷 감지
  ImageFormat detectImageFormat(Uint8List imageData) {
    if (imageData.length < 8) {
      return ImageFormat.unknown;
    }
    
    // PNG 시그니처: 89 50 4E 47 0D 0A 1A 0A
    if (imageData[0] == 0x89 && 
        imageData[1] == 0x50 && 
        imageData[2] == 0x4E && 
        imageData[3] == 0x47) {
      return ImageFormat.png;
    }
    
    // JPEG 시그니처: FF D8 FF
    if (imageData[0] == 0xFF && 
        imageData[1] == 0xD8 && 
        imageData[2] == 0xFF) {
      return ImageFormat.jpeg;
    }
    
    return ImageFormat.unknown;
  }

  /// 이미지 파일 경로 생성 (Public 버전)
  String generateImagePath(String recipeId, ImageFormat format) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final extension = format == ImageFormat.png ? 'png' : 'jpg';
    final fileName = '${recipeId}_$timestamp.$extension';
    return '${_cachedStoragePath ?? ''}/$fileName';
  }

  /// 이미지 파일 경로 생성 (Private 버전)
  String _generateImagePath(String storagePath, String recipeId, ImageFormat format) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final extension = format == ImageFormat.png ? 'png' : 'jpg';
    final fileName = '${recipeId}_$timestamp.$extension';
    return '$storagePath/$fileName';
  }

  /// 파일 경로 유효성 검사
  bool isValidImagePath(String imagePath) {
    if (imagePath.isEmpty) {
      return false;
    }
    
    try {
      final file = File(imagePath);
      final extension = file.path.toLowerCase().split('.').last;
      
      // 확장자가 유효하고 파일이 존재하는 경우에만 true
      return ['png', 'jpg', 'jpeg'].contains(extension) && file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// 파일 경로에서 레시피 ID 추출
  String extractRecipeId(String imagePath) {
    final fileName = imagePath.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    
    // 파일명 형식: recipeId_timestamp
    final parts = nameWithoutExtension.split('_');
    if (parts.length >= 2) {
      // 마지막 부분(타임스탬프) 제거하고 나머지를 조합
      return parts.take(parts.length - 1).join('_');
    }
    
    return nameWithoutExtension;
  }

  /// 특정 레시피의 모든 이미지 경로 조회
  Future<List<String>> getImagesForRecipe(String recipeId) async {
    try {
      final storagePath = await _storagePath;
      final directory = Directory(storagePath);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final imagePaths = <String>[];
      
      await for (var entity in directory.list()) {
        if (entity is File && isValidImagePath(entity.path)) {
          final extractedId = extractRecipeId(entity.path);
          if (extractedId == recipeId) {
            imagePaths.add(entity.path);
          }
        }
      }
      
      return imagePaths;
    } catch (e) {
      developer.log('Failed to get images for recipe: $e', name: 'ImageService');
      return [];
    }
  }

  /// 이미지 리사이징 (내부 헬퍼 함수)
  img.Image _resizeImage(img.Image image, {int maxWidth = 1024, int maxHeight = 1024}) {
    int newWidth = image.width;
    int newHeight = image.height;
    
    // 비율 유지하면서 최대 크기에 맞게 조정
    if (newWidth > maxWidth || newHeight > maxHeight) {
      double widthRatio = newWidth / maxWidth;
      double heightRatio = newHeight / maxHeight;
      double ratio = widthRatio > heightRatio ? widthRatio : heightRatio;
      
      newWidth = (newWidth / ratio).round();
      newHeight = (newHeight / ratio).round();
    }
    
    if (newWidth != image.width || newHeight != image.height) {
      return img.copyResize(image, width: newWidth, height: newHeight);
    }
    
    return image;
  }

  /// 서비스 정리 (선택적)
  void dispose() {
    _cachedStoragePath = null;
    developer.log('ImageService disposed', name: 'ImageService');
  }
}

/// 이미지 포맷 enum
enum ImageFormat {
  png,
  jpeg,
  unknown,
}

/// 이미지 포맷 예외
class ImageFormatException implements Exception {
  final String message;
  ImageFormatException(this.message);
  
  @override
  String toString() => 'ImageFormatException: $message';
}

/// 이미지 크기 예외
class ImageSizeException implements Exception {
  final String message;
  ImageSizeException(this.message);
  
  @override
  String toString() => 'ImageSizeException: $message';
}

/// 이미지 처리 예외
class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  
  @override
  String toString() => 'ImageProcessingException: $message';
}