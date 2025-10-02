#!/bin/bash

# WebP 변환 스크립트
ASSET_DIR="assets/images"
QUALITY=85

# 변환 통계
total=0
success=0
failed=0

echo "🔄 Starting WebP conversion..."
echo "Quality: ${QUALITY}"
echo ""

# PNG/JPG/JPEG 파일 찾아서 변환
find "$ASSET_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | while read -r file; do
    total=$((total + 1))
    
    # 파일 경로에서 확장자 제거
    base="${file%.*}"
    webp_file="${base}.webp"
    
    echo "Converting: $file"
    
    # WebP로 변환 (기존 파일 유지)
    if cwebp -q $QUALITY "$file" -o "$webp_file" > /dev/null 2>&1; then
        echo "  ✅ Created: $webp_file"
        
        # 파일 크기 비교
        original_size=$(stat -f%z "$file")
        webp_size=$(stat -f%z "$webp_file")
        reduction=$((100 - (webp_size * 100 / original_size)))
        
        echo "  📊 Size reduction: ${reduction}% (${original_size} -> ${webp_size} bytes)"
        success=$((success + 1))
    else
        echo "  ❌ Failed to convert: $file"
        failed=$((failed + 1))
    fi
    echo ""
done

echo "========================================="
echo "✨ Conversion complete!"
echo "Total files processed: $total"
echo "Success: $success"
echo "Failed: $failed"
echo "========================================="
