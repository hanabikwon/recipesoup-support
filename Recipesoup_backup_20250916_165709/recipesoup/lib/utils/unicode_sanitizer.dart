import 'dart:convert';

/// Unicode 문자열 정리 유틸리티 클래스
/// JSON 인코딩 시 발생할 수 있는 Unicode surrogate pair 문제를 해결
class UnicodeSanitizer {
  
  /// 잘못된 Unicode surrogate pair를 정리하는 메인 함수
  /// 
  /// [text]: 정리할 텍스트
  /// Returns: 정리된 안전한 텍스트
  static String sanitize(String text) {
    if (text.isEmpty) return text;
    
    try {
      // 1단계: surrogate pair 문제 해결
      String cleaned = _fixSurrogatePairs(text);
      
      // 2단계: 제어 문자 제거
      cleaned = _removeControlCharacters(cleaned);
      
      // 3단계: JSON 안전성 검증
      cleaned = _ensureJsonSafe(cleaned);
      
      return cleaned;
    } catch (e) {
      // 문제 발생 시 안전한 기본값 반환
      return _createSafeString(text);
    }
  }
  
  /// JSON 데이터의 모든 문자열 필드를 안전하게 정리
  /// 
  /// [data]: 정리할 JSON 데이터 (Map 또는 List)
  /// Returns: 정리된 JSON 데이터
  static dynamic sanitizeJsonData(dynamic data) {
    if (data is String) {
      return sanitize(data);
    } else if (data is Map) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        final safeKey = key is String ? sanitize(key) : key;
        result[safeKey.toString()] = sanitizeJsonData(value);
      });
      return result;
    } else if (data is List) {
      return data.map((item) => sanitizeJsonData(item)).toList();
    } else {
      return data;
    }
  }
  
  /// Base64 인코딩된 데이터의 안전성 검증
  /// 
  /// [base64Data]: Base64 문자열
  /// Returns: 안전한 Base64 문자열 또는 null (잘못된 경우)
  static String? validateBase64(String base64Data) {
    if (base64Data.isEmpty) return base64Data;
    
    try {
      // Base64 패턴 검증
      final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      if (!base64Regex.hasMatch(base64Data)) {
        return null;
      }
      
      // 실제 디코딩 가능한지 검증
      base64Decode(base64Data);
      
      return base64Data;
    } catch (e) {
      return null;
    }
  }
  
  /// surrogate pair 문제를 수정하는 내부 함수
  static String _fixSurrogatePairs(String text) {
    final List<int> codeUnits = text.codeUnits.toList();
    final List<int> fixed = [];
    
    for (int i = 0; i < codeUnits.length; i++) {
      final codeUnit = codeUnits[i];
      
      // High surrogate 범위 (U+D800-U+DBFF)
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        // 다음 문자가 Low surrogate인지 확인
        if (i + 1 < codeUnits.length) {
          final nextCodeUnit = codeUnits[i + 1];
          // Low surrogate 범위 (U+DC00-U+DFFF)
          if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
            // 올바른 surrogate pair이므로 그대로 추가
            fixed.add(codeUnit);
            fixed.add(nextCodeUnit);
            i++; // 다음 문자는 이미 처리했으므로 스킵
          } else {
            // High surrogate 뒤에 Low surrogate가 없음
            // 대체 문자(U+FFFD)로 교체
            fixed.add(0xFFFD);
          }
        } else {
          // High surrogate가 문자열 끝에 있음
          // 대체 문자(U+FFFD)로 교체
          fixed.add(0xFFFD);
        }
      }
      // Low surrogate 범위 (U+DC00-U+DFFF)
      else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        // Low surrogate가 단독으로 나타남 (High surrogate 없이)
        // 대체 문자(U+FFFD)로 교체
        fixed.add(0xFFFD);
      }
      // 일반 문자는 그대로 추가
      else {
        fixed.add(codeUnit);
      }
    }
    
    return String.fromCharCodes(fixed);
  }
  
  /// 제어 문자 제거 (출력 가능한 문자만 유지)
  static String _removeControlCharacters(String text) {
    return text.runes.where((rune) {
      // 허용할 제어 문자들
      if (rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        return true; // Tab, LF, CR
      }
      
      // 일반적인 출력 가능한 문자 범위
      if (rune >= 0x20 && rune <= 0x7E) {
        return true; // ASCII 출력 가능 문자
      }
      
      // Unicode 출력 가능한 문자
      if (rune >= 0xA0) {
        return true; // Non-ASCII 출력 가능 문자
      }
      
      return false; // 제어 문자 제거
    }).map((rune) => String.fromCharCode(rune)).join();
  }
  
  /// JSON 안전성 보장
  static String _ensureJsonSafe(String text) {
    try {
      // JSON 인코딩/디코딩으로 안전성 검증
      final encoded = jsonEncode(text);
      final decoded = jsonDecode(encoded) as String;
      return decoded;
    } catch (e) {
      // JSON 인코딩/디코딩 실패 시 안전한 문자만 추출
      return text.runes
          .where((rune) => rune < 0xD800 || rune > 0xDFFF) // surrogate 제외
          .map((rune) => String.fromCharCode(rune))
          .join();
    }
  }
  
  /// 문제 발생 시 안전한 문자열 생성
  static String _createSafeString(String originalText) {
    try {
      // 기본 ASCII 문자와 한글만 유지
      return originalText.runes.where((rune) {
        // ASCII 출력 가능 문자
        if (rune >= 0x20 && rune <= 0x7E) return true;
        
        // 한글 범위
        if (rune >= 0xAC00 && rune <= 0xD7AF) return true; // 한글 완성형
        if (rune >= 0x3131 && rune <= 0x318E) return true; // 한글 자모
        
        // 기본 공백 문자들
        if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) return true;
        
        return false;
      }).map((rune) => String.fromCharCode(rune)).join();
    } catch (e) {
      // 모든 방법이 실패하면 빈 문자열 반환
      return '';
    }
  }
  
  /// API 요청 데이터 전체 정리
  /// 
  /// [requestData]: API 요청 데이터
  /// Returns: 정리된 안전한 요청 데이터
  static Map<String, dynamic> sanitizeApiRequest(Map<String, dynamic> requestData) {
    try {
      final sanitized = sanitizeJsonData(requestData) as Map<String, dynamic>;
      
      // JSON 인코딩 가능성 검증
      jsonEncode(sanitized);
      
      return sanitized;
    } catch (e) {
      // 문제 발생 시 기본 구조 반환
      return {
        'model': requestData['model']?.toString() ?? 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': 'Error occurred during text processing. Please try again.'
          }
        ],
        'max_tokens': 100,
        'temperature': 0.5,
      };
    }
  }
  
  /// 디버깅용: 문자열의 Unicode 정보 출력
  static String debugUnicodeInfo(String text) {
    if (text.isEmpty) return 'Empty string';
    
    final buffer = StringBuffer();
    buffer.writeln('String length: ${text.length}');
    buffer.writeln('Code units length: ${text.codeUnits.length}');
    buffer.writeln('Runes length: ${text.runes.length}');
    
    // 처음 10개 문자의 Unicode 정보
    final codeUnits = text.codeUnits.take(10).toList();
    buffer.writeln('First ${codeUnits.length} code units:');
    
    for (int i = 0; i < codeUnits.length; i++) {
      final codeUnit = codeUnits[i];
      final hex = codeUnit.toRadixString(16).toUpperCase().padLeft(4, '0');
      final char = String.fromCharCode(codeUnit);
      final isSurrogate = (codeUnit >= 0xD800 && codeUnit <= 0xDFFF);
      
      buffer.writeln('  [$i] U+$hex "$char" ${isSurrogate ? "(surrogate)" : ""}');
    }
    
    return buffer.toString();
  }
}