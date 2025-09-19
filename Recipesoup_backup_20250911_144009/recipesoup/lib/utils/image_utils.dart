import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// 이미지 처리 유틸리티 클래스
class RecipeImageUtils {
  /// 이미지 리사이징 (최대 크기 제한)
  static Future<Uint8List> resizeImage(
    Uint8List imageData, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      // 이미지 디코딩
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      // 이미 크기가 작으면 원본 반환
      if (image.width <= maxWidth && image.height <= maxHeight) {
        return imageData;
      }

      // 비율 유지하며 리사이징
      final resized = img.copyResize(
        image,
        width: image.width > image.height ? maxWidth : null,
        height: image.height > image.width ? maxHeight : null,
      );

      // JPEG로 인코딩 (압축)
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      throw Exception('Image resizing failed: $e');
    }
  }

  /// 이미지를 Base64로 인코딩 (OpenAI API용)
  static String encodeToBase64(Uint8List imageData) {
    return base64Encode(imageData);
  }

  /// Base64에서 이미지 데이터로 디코딩
  static Uint8List decodeFromBase64(String base64String) {
    return base64Decode(base64String);
  }

  /// 이미지 파일 압축
  static Future<Uint8List> compressImage(
    File imageFile, {
    int quality = 85,
    int maxSizeKB = 1024, // 1MB
  }) async {
    try {
      Uint8List imageData = await imageFile.readAsBytes();
      
      // 이미 크기가 작으면 원본 반환
      if (imageData.length <= maxSizeKB * 1024) {
        return imageData;
      }

      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      // 품질을 점진적으로 낮춰가며 압축
      int currentQuality = quality;
      Uint8List compressedData;

      do {
        compressedData = Uint8List.fromList(
          img.encodeJpg(image, quality: currentQuality)
        );
        currentQuality -= 5;
      } while (compressedData.length > maxSizeKB * 1024 && currentQuality > 20);

      return compressedData;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// 이미지 형식 감지
  static String? detectImageFormat(Uint8List imageData) {
    if (imageData.length < 8) return null;

    // PNG 시그니처 확인
    if (imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      return 'png';
    }

    // JPEG 시그니처 확인
    if (imageData[0] == 0xFF && imageData[1] == 0xD8) {
      return 'jpeg';
    }

    // GIF 시그니처 확인
    if (imageData[0] == 0x47 &&
        imageData[1] == 0x49 &&
        imageData[2] == 0x46) {
      return 'gif';
    }

    return null;
  }

  /// 이미지 메타데이터 추출
  static Map<String, dynamic> getImageMetadata(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      final format = detectImageFormat(imageData);
      final sizeKB = (imageData.length / 1024).round();

      return {
        'width': image.width,
        'height': image.height,
        'format': format ?? 'unknown',
        'sizeKB': sizeKB,
        'aspectRatio': image.width / image.height,
      };
    } catch (e) {
      throw Exception('Failed to extract image metadata: $e');
    }
  }

  /// 썸네일 생성
  static Future<Uint8List> generateThumbnail(
    Uint8List imageData, {
    int size = 150,
    int quality = 80,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      // 정사각형 썸네일 생성 (중앙 크롭)
      final minSize = image.width < image.height ? image.width : image.height;
      final cropX = (image.width - minSize) ~/ 2;
      final cropY = (image.height - minSize) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: minSize,
        height: minSize,
      );

      final resized = img.copyResize(cropped, width: size, height: size);

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      throw Exception('Thumbnail generation failed: $e');
    }
  }

  /// 이미지 회전
  static Future<Uint8List> rotateImage(
    Uint8List imageData,
    int degrees, // 90, 180, 270도만 지원
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      late img.Image rotated;
      switch (degrees) {
        case 90:
          rotated = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotated = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotated = img.copyRotate(image, angle: 270);
          break;
        default:
          throw Exception('Only 90, 180, 270 degrees rotation supported');
      }

      return Uint8List.fromList(img.encodePng(rotated));
    } catch (e) {
      throw Exception('Image rotation failed: $e');
    }
  }

  /// 이미지 유효성 검사
  static bool isValidImage(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// 파일 확장자에 따른 MIME 타입 반환
  static String getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// OpenAI API용 Data URL 생성
  static String createDataUrl(Uint8List imageData, {String? mimeType}) {
    final detectedFormat = detectImageFormat(imageData);
    final mime = mimeType ?? 'image/${detectedFormat ?? 'jpeg'}';
    final base64Data = encodeToBase64(imageData);
    
    return 'data:$mime;base64,$base64Data';
  }

  /// 이미지 크기 유효성 검사
  static bool isValidImageSize(
    Uint8List imageData, {
    int maxSizeMB = 10,
    int minWidth = 100,
    int minHeight = 100,
    int maxWidth = 4000,
    int maxHeight = 4000,
  }) {
    try {
      // 파일 크기 체크
      final sizeBytes = imageData.length;
      if (sizeBytes > maxSizeMB * 1024 * 1024) {
        return false;
      }

      // 이미지 해상도 체크
      final image = img.decodeImage(imageData);
      if (image == null) return false;

      return image.width >= minWidth &&
          image.height >= minHeight &&
          image.width <= maxWidth &&
          image.height <= maxHeight;
    } catch (e) {
      return false;
    }
  }
}