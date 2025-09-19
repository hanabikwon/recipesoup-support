#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Burrow 시스템 이미지 에셋 검증 스크립트
BurrowAssets.dart에 정의된 경로와 실제 파일 존재 여부 확인
"""

import os
import sys

def check_milestone_images():
    """마일스톤 이미지 파일들 검증"""
    base_path = 'assets/images/burrow'
    milestone_paths = {
        1: f'{base_path}/milestones/burrow_tiny.png',
        2: f'{base_path}/milestones/burrow_small.png', 
        3: f'{base_path}/milestones/burrow_homecook.png',        
        4: f'{base_path}/milestones/burrow_apprentice.png',       
        5: f'{base_path}/milestones/burrow_garden.png',           
        6: f'{base_path}/milestones/burrow_harvest.png',          
        7: f'{base_path}/milestones/burrow_market.png',           
        8: f'{base_path}/milestones/burrow_kitchen.png',          
        9: f'{base_path}/milestones/burrow_medium.png',           
        10: f'{base_path}/milestones/burrow_experiment.png',      
        11: f'{base_path}/milestones/burrow_cookbook.png',        
        12: f'{base_path}/milestones/burrow_ceramist.png',        
        13: f'{base_path}/milestones/burrow_familydinner.png',    
        14: f'{base_path}/milestones/burrow_study.png',           
        15: f'{base_path}/milestones/burrow_competition.png',     
        16: f'{base_path}/milestones/burrow_festival.png',        
        17: f'{base_path}/milestones/burrow_signaturedish.png',   
        18: f'{base_path}/milestones/burrow_teacher.png',         
        19: f'{base_path}/milestones/burrow_tasting.png',         
        20: f'{base_path}/milestones/burrow_gourmet_trip.png',    
        21: f'{base_path}/milestones/burrow_large.png',           
        22: f'{base_path}/milestones/burrow_international.png',   
        23: f'{base_path}/milestones/burrow_own_restaurant.png',  
        24: f'{base_path}/milestones/burrow_thanksgiving.png',    
        25: f'{base_path}/milestones/burrow_winecellar.png',      
        26: f'{base_path}/milestones/burrow_japan_trip.png',      
        27: f'{base_path}/milestones/burrow_cheeze_tour.png',     
        28: f'{base_path}/milestones/burrow_recipe_lab.png',      
        29: f'{base_path}/milestones/burrow_sketch.png',          
        30: f'{base_path}/milestones/burrow_sick.png',            
        31: f'{base_path}/milestones/burrow_forest_mushroom.png', 
        32: f'{base_path}/milestones/burrow_fishing.png',         
    }
    
    print("🏠 마일스톤 이미지 검증 (레벨 1-32):")
    missing_count = 0
    existing_count = 0
    
    for level, path in milestone_paths.items():
        if os.path.exists(path):
            print(f"✅ 레벨 {level:2d}: {path}")
            existing_count += 1
        else:
            print(f"❌ 레벨 {level:2d}: {path} (누락)")
            missing_count += 1
    
    print(f"\n📊 마일스톤 요약: 존재 {existing_count}개, 누락 {missing_count}개")
    return missing_count == 0

def check_special_room_images():
    """특별 공간 이미지 파일들 검증"""
    base_path = 'assets/images/burrow'
    special_room_paths = {
        # 기존 특별 공간들
        'ballroom': f'{base_path}/special_rooms/burrow_ballroom.png',
        'hotSpring': f'{base_path}/special_rooms/burrow_hotspring.png',
        'orchestra': f'{base_path}/special_rooms/burrow_concert.png',
        'alchemyLab': f'{base_path}/special_rooms/burrow_lab.png',
        'fineDining': f'{base_path}/special_rooms/burrow_fineding.png',
        
        # 새로 추가된 특별 공간들 (11개)
        'alps': f'{base_path}/special_rooms/burrow_alps.png',
        'camping': f'{base_path}/special_rooms/burrow_camping.png',
        'autumn': f'{base_path}/special_rooms/burrow_autumn.png',
        'springPicnic': f'{base_path}/special_rooms/burrow_spring_picnic.png',
        'surfing': f'{base_path}/special_rooms/burrow_surfing.png',
        'snorkel': f'{base_path}/special_rooms/burrow_snorkel.png',
        'summerbeach': f'{base_path}/special_rooms/burrow_summerbeach.png',
        'baliYoga': f'{base_path}/special_rooms/burrow_bali_yoga.png',
        'orientExpress': f'{base_path}/special_rooms/burrow_orient_express.png',
        'canvas': f'{base_path}/special_rooms/burrow_canvas.png',
        'vacance': f'{base_path}/special_rooms/burrow_vacance.png',
    }
    
    print("\n🏛️ 특별 공간 이미지 검증 (총 16개):")
    missing_count = 0
    existing_count = 0
    
    for room_type, path in special_room_paths.items():
        if os.path.exists(path):
            print(f"✅ {room_type:15s}: {path}")
            existing_count += 1
        else:
            print(f"❌ {room_type:15s}: {path} (누락)")
            missing_count += 1
    
    print(f"\n📊 특별 공간 요약: 존재 {existing_count}개, 누락 {missing_count}개")
    return missing_count == 0

def check_default_images():
    """기본 이미지들 검증"""
    base_path = 'assets/images/burrow'
    default_paths = [
        f'{base_path}/milestones/burrow_locked.png',
    ]
    
    print("\n🔒 기본 이미지 검증:")
    missing_count = 0
    existing_count = 0
    
    for path in default_paths:
        if os.path.exists(path):
            print(f"✅ {path}")
            existing_count += 1
        else:
            print(f"❌ {path} (누락)")
            missing_count += 1
    
    print(f"\n📊 기본 이미지 요약: 존재 {existing_count}개, 누락 {missing_count}개")
    return missing_count == 0

def main():
    """메인 검증 함수"""
    print("🔍 Burrow 시스템 이미지 에셋 검증 시작\n")
    print("=" * 80)
    
    # 현재 디렉토리 확인
    current_dir = os.getcwd()
    print(f"📁 현재 작업 디렉토리: {current_dir}")
    
    # 각 카테고리별 검증 실행
    milestone_ok = check_milestone_images()
    special_room_ok = check_special_room_images()
    default_ok = check_default_images()
    
    # 최종 결과
    print("\n" + "=" * 80)
    print("📋 최종 검증 결과:")
    
    if milestone_ok and special_room_ok and default_ok:
        print("🎉 모든 이미지 파일이 정상적으로 존재합니다!")
        print("✅ BurrowAssets.dart와 실제 파일 경로가 모두 일치합니다.")
        return 0
    else:
        print("⚠️ 일부 이미지 파일이 누락되었습니다.")
        print("🔧 누락된 파일들을 확인하고 올바른 위치에 배치해주세요.")
        return 1

if __name__ == "__main__":
    sys.exit(main())