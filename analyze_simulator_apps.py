#!/usr/bin/env python3
"""
iPhone 16 시뮬레이터 앱 컨테이너 분석 스크립트
모든 앱 컨테이너를 분석하여 앱 식별자와 종류를 분류합니다.
"""

import os
import subprocess
import json
from pathlib import Path

# 시뮬레이터 경로
SIMULATOR_PATH = "/Users/hanabi/Library/Developer/CoreSimulator/Devices/F8E334E7-475A-4717-AD70-EF257F20F25C/data/Containers/Data/Application"

def get_app_identifier(container_path):
    """앱 컨테이너에서 앱 식별자를 추출합니다."""
    metadata_file = os.path.join(container_path, ".com.apple.mobile_container_manager.metadata.plist")

    if not os.path.exists(metadata_file):
        return None

    try:
        # plutil 명령어로 plist 파일 파싱
        result = subprocess.run(
            ["plutil", "-p", metadata_file],
            capture_output=True,
            text=True,
            check=True
        )

        # MCMMetadataIdentifier 추출
        for line in result.stdout.split('\n'):
            if 'MCMMetadataIdentifier' in line:
                # "MCMMetadataIdentifier" => "com.apple.example" 형태에서 식별자 추출
                parts = line.split('"')
                if len(parts) >= 4:
                    return parts[3]

        return None

    except subprocess.CalledProcessError:
        return None

def classify_app(identifier):
    """앱 식별자를 기반으로 앱 종류를 분류합니다."""
    if not identifier:
        return "Unknown"

    if identifier.startswith("com.apple."):
        return "Apple System"
    elif "recipesoup" in identifier.lower():
        return "Recipesoup (Development)"
    elif identifier.startswith("com.") and not identifier.startswith("com.apple."):
        return "Third Party"
    else:
        return "Other"

def get_directory_size(path):
    """디렉토리 크기를 계산합니다 (MB 단위)."""
    try:
        result = subprocess.run(
            ["du", "-sm", path],
            capture_output=True,
            text=True,
            check=True
        )
        size_mb = int(result.stdout.split()[0])
        return size_mb
    except (subprocess.CalledProcessError, ValueError):
        return 0

def analyze_containers():
    """모든 앱 컨테이너를 분석합니다."""
    print("🔍 iPhone 16 시뮬레이터 앱 컨테이너 분석 시작...")
    print(f"📁 분석 경로: {SIMULATOR_PATH}")
    print()

    containers = []
    categories = {}

    # 모든 컨테이너 디렉토리 확인
    if not os.path.exists(SIMULATOR_PATH):
        print(f"❌ 경로를 찾을 수 없습니다: {SIMULATOR_PATH}")
        return

    container_dirs = [d for d in os.listdir(SIMULATOR_PATH)
                     if os.path.isdir(os.path.join(SIMULATOR_PATH, d))]

    print(f"📊 총 {len(container_dirs)}개의 앱 컨테이너 발견")
    print()

    for i, container_uuid in enumerate(container_dirs, 1):
        container_path = os.path.join(SIMULATOR_PATH, container_uuid)

        # 앱 식별자 추출
        identifier = get_app_identifier(container_path)
        category = classify_app(identifier)
        size_mb = get_directory_size(container_path)

        container_info = {
            'uuid': container_uuid,
            'identifier': identifier or 'Unknown',
            'category': category,
            'size_mb': size_mb,
            'path': container_path
        }

        containers.append(container_info)

        # 카테고리별 집계
        if category not in categories:
            categories[category] = {'count': 0, 'total_size': 0, 'apps': []}
        categories[category]['count'] += 1
        categories[category]['total_size'] += size_mb
        categories[category]['apps'].append(container_info)

        # 진행 상황 표시
        if i % 20 == 0 or i == len(container_dirs):
            print(f"⏳ 진행 상황: {i}/{len(container_dirs)} ({i/len(container_dirs)*100:.1f}%)")

    return containers, categories

def print_analysis_results(containers, categories):
    """분석 결과를 출력합니다."""
    print("\n" + "="*80)
    print("📋 분석 결과 요약")
    print("="*80)

    total_size = sum(cat['total_size'] for cat in categories.values())

    print(f"📱 총 앱 개수: {len(containers)}개")
    print(f"💾 총 사용 공간: {total_size:,} MB ({total_size/1024:.1f} GB)")
    print()

    # 카테고리별 요약
    print("📊 카테고리별 분류:")
    print("-" * 60)
    for category, info in sorted(categories.items()):
        percentage = (info['count'] / len(containers)) * 100
        print(f"  {category:<25} {info['count']:>3}개 ({percentage:>5.1f}%) | {info['total_size']:>4} MB")
    print()

    # 주요 앱들 상세 정보
    print("🔍 주요 앱 상세 정보:")
    print("-" * 80)

    # Recipesoup 앱
    recipesoup_apps = [c for c in containers if 'recipesoup' in c['identifier'].lower()]
    if recipesoup_apps:
        print("🥘 Recipesoup 앱:")
        for app in recipesoup_apps:
            print(f"  UUID: {app['uuid']}")
            print(f"  식별자: {app['identifier']}")
            print(f"  크기: {app['size_mb']} MB")
            print()

    # 크기가 큰 앱들 (10MB 이상)
    large_apps = [c for c in containers if c['size_mb'] >= 10]
    large_apps.sort(key=lambda x: x['size_mb'], reverse=True)

    if large_apps:
        print("📦 크기가 큰 앱들 (10MB 이상):")
        for app in large_apps[:10]:  # 상위 10개만 표시
            print(f"  {app['identifier']:<40} {app['size_mb']:>4} MB | {app['uuid']}")
        if len(large_apps) > 10:
            print(f"  ... 및 {len(large_apps) - 10}개 더")
        print()

    # Apple 시스템 앱 중 불필요할 수 있는 것들
    apple_apps = categories.get('Apple System', {}).get('apps', [])
    if apple_apps:
        print("🍎 Apple 시스템 앱 샘플 (상위 20개):")
        for app in apple_apps[:20]:
            print(f"  {app['identifier']:<50} {app['size_mb']:>3} MB")
        if len(apple_apps) > 20:
            print(f"  ... 및 {len(apple_apps) - 20}개 더")

def main():
    """메인 함수"""
    containers, categories = analyze_containers()
    if containers:
        print_analysis_results(containers, categories)

        # 결과를 JSON 파일로 저장
        output_file = "/Users/hanabi/Downloads/practice/simulator_apps_analysis.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump({
                'containers': containers,
                'categories': categories,
                'summary': {
                    'total_apps': len(containers),
                    'total_size_mb': sum(cat['total_size'] for cat in categories.values())
                }
            }, f, indent=2, ensure_ascii=False)

        print(f"\n💾 상세 분석 결과가 저장되었습니다: {output_file}")

if __name__ == "__main__":
    main()