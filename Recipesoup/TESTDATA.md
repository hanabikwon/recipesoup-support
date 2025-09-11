# Recipesoup 테스트 데이터

## 개요
감정 기반 레시피 아카이빙 앱 **Recipesoup**의 테스트에 사용되는 모든 샘플 데이터를 정의합니다. 
이 데이터는 감정과 요리를 연결하는 앱의 핵심 특성을 반영하여 작성되었습니다.

## 핵심 테스트 이미지 (OpenAI API 테스트용)

### 음식 사진 테스트 세트
```dart
const testImageSet = {
  'testimg1': {
    'filename': 'testimg1.jpg',
    'description': '김치찌개 완성 사진',
    'expectedIngredients': ['김치', '돼지고기', '두부', '양파', '대파'],
    'expectedKeywords': ['얼큰한', '국물', '찌개', '한식'],
    'difficulty': 'easy',
    'servings': '2-3인분'
  },
  'testimg2': {
    'filename': 'testimg2.jpg', 
    'description': '파스타 완성 사진',
    'expectedIngredients': ['파스타면', '토마토소스', '마늘', '올리브오일', '바질'],
    'expectedKeywords': ['이탈리안', '면', '토마토', '서양식'],
    'difficulty': 'medium',
    'servings': '1-2인분'
  },
  'testimg3': {
    'filename': 'testimg3.jpg',
    'description': '복잡한 한정식 상차림',
    'expectedIngredients': ['여러 반찬류', '밥', '국', '김치'],
    'expectedKeywords': ['한정식', '전통', '정성', '집밥'],
    'difficulty': 'hard',
    'servings': '4인분 이상'
  }
};
```

## 감정(Mood) 테스트 데이터

### 모든 감정 상태 샘플
```dart
const moodTestCases = {
  Mood.happy: {
    'emoji': '😊',
    'korean': '기쁨',
    'english': 'happy',
    'sampleStories': [
      '오늘 승진 소식을 듣고 너무 기뻐서 좋아하는 스테이크를 구워먹었어요',
      '친구들과 만나는 날이라 신나서 파티 음식을 준비했습니다',
      '시험 합격 기념으로 케이크를 직접 만들어봤어요'
    ]
  },
  Mood.peaceful: {
    'emoji': '😌',
    'korean': '평온',
    'english': 'peaceful', 
    'sampleStories': [
      '혼자만의 조용한 시간, 차 한잔과 함께 간단한 샌드위치를 만들었어요',
      '비 오는 날 창밖을 보며 따뜻한 죽을 끓였습니다',
      '요가 후 몸과 마음이 편안해져서 건강한 샐러드를 만들어 먹었어요'
    ]
  },
  Mood.sad: {
    'emoji': '😢',
    'korean': '슬픔',
    'english': 'sad',
    'sampleStories': [
      '힘든 하루를 보내고 집에 와서 엄마가 해주던 미역국이 그리워 끓여먹었어요',
      '이별 후 혼자 남은 저녁, 라면으로 간단히 때웠습니다',
      '펫과 이별한 슬픔에 울면서 그가 좋아했던 닭가슴살을 요리했어요'
    ]
  },
  Mood.tired: {
    'emoji': '😴',
    'korean': '피로',
    'english': 'tired',
    'sampleStories': [
      '야근으로 지쳐서 집에 와서 5분 만에 계란후라이 덮밥 완성',
      '아이 돌보느라 너무 피곤해서 간단한 토스트만 만들어 먹었어요',
      '출장에서 돌아와 피곤했지만 집밥이 그리워 된장찌개를 끓였습니다'
    ]
  },
  Mood.excited: {
    'emoji': '🤩',
    'korean': '설렘',
    'english': 'excited',
    'sampleStories': [
      '첫 데이트를 앞두고 설레서 특별한 도시락을 준비했어요',
      '새 집으로 이사 온 첫날, 설레는 마음으로 집들이 음식을 준비했습니다',
      '여행을 앞두고 설레서 평소 못 먹어본 이국적인 요리에 도전했어요'
    ]
  },
  Mood.nostalgic: {
    'emoji': '🥺',
    'korean': '그리움',
    'english': 'nostalgic',
    'sampleStories': [
      '고향이 그리워서 할머니가 만들어주던 손수제비를 끓였어요',
      '어릴 적 먹던 엄마표 김치볶음밥이 그리워서 똑같이 만들어봤습니다',
      '대학교 앞 추억의 떡볶이가 생각나서 집에서 재현해봤어요'
    ]
  },
  Mood.comfortable: {
    'emoji': '☺️',
    'korean': '편안함',
    'english': 'comfortable',
    'sampleStories': [
      '가족들과 함께하는 평범한 일요일, 편안한 마음으로 김치찌개를 끓였어요',
      '친한 친구와 집에서 영화보며 편안하게 팝콘을 만들어 먹었습니다',
      '휴가 첫날 여유로운 마음으로 브런치를 천천히 준비했어요'
    ]
  },
  Mood.grateful: {
    'emoji': '🙏',
    'korean': '감사',
    'english': 'grateful',
    'sampleStories': [
      '건강해서 감사한 마음으로 몸에 좋은 야채죽을 끓였어요',
      '가족의 사랑에 감사하며 온 가족이 좋아하는 갈비탕을 끓였습니다',
      '친구들의 도움에 감사해서 정성껏 집들이 음식을 준비했어요'
    ]
  }
};
```

## 레시피(Recipe) 테스트 데이터

### 완전한 레시피 샘플 데이터
```dart
final testRecipes = [
  // 레시피 1: 행복한 기념일 요리
  Recipe(
    id: 'recipe_001',
    title: '승진 기념 스테이크',
    emotionalStory: '드디어 승진이 확정되었어요! 너무 기뻐서 평소 아끼던 좋은 스테이크를 꺼내 구워먹었습니다. 앞으로도 더 열심히 일해야겠어요.',
    ingredients: [
      Ingredient(name: '안심 스테이크', amount: '200g', unit: 'g', category: IngredientCategory.meat),
      Ingredient(name: '로즈마리', amount: '2', unit: '줄기', category: IngredientCategory.seasoning),
      Ingredient(name: '마늘', amount: '3', unit: '쪽', category: IngredientCategory.seasoning),
      Ingredient(name: '버터', amount: '30g', unit: 'g', category: IngredientCategory.dairy),
      Ingredient(name: '소금', amount: '적당량', unit: null, category: IngredientCategory.seasoning),
      Ingredient(name: '후춧가루', amount: '적당량', unit: null, category: IngredientCategory.seasoning),
    ],
    instructions: [
      '스테이크를 실온에 30분간 둬서 온도를 맞춰주세요',
      '소금과 후춧가루로 간을 해주세요',
      '팬을 달궈서 올리브오일을 두르고 스테이크를 올려주세요',
      '한 면을 2-3분간 구워주세요',
      '뒤집어서 마늘과 로즈마리, 버터를 넣고 베이스팅해주세요',
      '원하는 굽기 정도가 될 때까지 구워주세요',
      '5분간 휴지시킨 후 썰어서 서빙해주세요'
    ],
    localImagePath: 'test_images/steak_001.jpg',
    tags: ['#기념일', '#스테이크', '#승진', '#특별한날'],
    createdAt: DateTime.now().subtract(Duration(days: 2)),
    mood: Mood.happy,
    rating: 5,
    reminderDate: null,
    isFavorite: true,
  ),
  
  // 레시피 2: 슬픈 날의 위로 음식
  Recipe(
    id: 'recipe_002', 
    title: '엄마 생각나는 미역국',
    emotionalStory: '힘든 일이 있어서 기분이 좋지 않았어요. 집에 와서 엄마가 생일때마다 끓여주던 미역국이 그리워서 만들어먹었습니다. 국물을 마시니 마음이 조금 따뜻해졌어요.',
    ingredients: [
      Ingredient(name: '미역', amount: '30g', unit: 'g', category: IngredientCategory.vegetable),
      Ingredient(name: '쇠고기', amount: '150g', unit: 'g', category: IngredientCategory.meat),
      Ingredient(name: '참기름', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
      Ingredient(name: '국간장', amount: '2', unit: '큰술', category: IngredientCategory.seasoning),
      Ingredient(name: '다진 마늘', amount: '1', unit: '작은술', category: IngredientCategory.seasoning),
      Ingredient(name: '물', amount: '1.5L', unit: 'L', category: IngredientCategory.other),
    ],
    instructions: [
      '미역을 찬물에 30분간 불려주세요',
      '불린 미역을 적당한 크기로 썰어주세요',
      '쇠고기를 작은 크기로 썰어주세요',
      '팬에 참기름을 두르고 쇠고기를 볶아주세요',
      '미역을 넣고 함께 볶아주세요',
      '물을 넣고 끓여주세요',
      '국간장과 다진 마늘로 간을 맞춰주세요',
      '15분 정도 더 끓여주세요'
    ],
    localImagePath: 'test_images/seaweed_soup_002.jpg',
    tags: ['#엄마음식', '#위로', '#미역국', '#집밥'],
    createdAt: DateTime.now().subtract(Duration(days: 5)),
    mood: Mood.sad,
    rating: 4,
    reminderDate: null,
    isFavorite: false,
  ),
  
  // 레시피 3: 평온한 혼밥
  Recipe(
    id: 'recipe_003',
    title: '조용한 저녁의 치킨 샐러드',
    emotionalStory: '오늘은 혼자만의 시간을 갖고 싶었어요. 조용한 음악을 틀어놓고 천천히 샐러드를 만들면서 하루를 정리했습니다. 마음이 차분해지는 시간이었어요.',
    ingredients: [
      Ingredient(name: '닭가슴살', amount: '150g', unit: 'g', category: IngredientCategory.meat),
      Ingredient(name: '로메인 상추', amount: '100g', unit: 'g', category: IngredientCategory.vegetable),
      Ingredient(name: '방울토마토', amount: '10', unit: '개', category: IngredientCategory.vegetable),
      Ingredient(name: '아보카도', amount: '1/2', unit: '개', category: IngredientCategory.vegetable),
      Ingredient(name: '올리브오일', amount: '2', unit: '큰술', category: IngredientCategory.seasoning),
      Ingredient(name: '레몬즙', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
      Ingredient(name: '발사믹 식초', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
    ],
    instructions: [
      '닭가슴살을 소금, 후추로 간하고 팬에 구워주세요',
      '구운 닭가슴살을 적당한 크기로 썰어주세요', 
      '로메인 상추를 깨끗이 씻고 적당한 크기로 뜯어주세요',
      '방울토마토를 반으로 썰고 아보카도를 슬라이스해주세요',
      '올리브오일, 레몬즙, 발사믹 식초를 섞어 드레싱을 만들어주세요',
      '모든 재료를 볼에 담고 드레싱을 뿌려 버무려주세요'
    ],
    localImagePath: 'test_images/chicken_salad_003.jpg',
    tags: ['#혼밥', '#건강식', '#샐러드', '#평온'],
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    mood: Mood.peaceful,
    rating: 4,
    reminderDate: DateTime.now().add(Duration(days: 7)),
    isFavorite: false,
  ),
  
  // 레시피 4: 피로한 날의 간편식
  Recipe(
    id: 'recipe_004',
    title: '야근 후 5분 계란볶음밥',
    emotionalStory: '야근으로 늦게 집에 왔는데 너무 피곤했어요. 냉장고에 있는 재료들로 간단하게 볶음밥을 만들었습니다. 간단하지만 든든했어요.',
    ingredients: [
      Ingredient(name: '밥', amount: '1', unit: '공기', category: IngredientCategory.grain),
      Ingredient(name: '계란', amount: '2', unit: '개', category: IngredientCategory.dairy),
      Ingredient(name: '대파', amount: '1/2', unit: '대', category: IngredientCategory.vegetable),
      Ingredient(name: '김치', amount: '50g', unit: 'g', category: IngredientCategory.vegetable),
      Ingredient(name: '참기름', amount: '1', unit: '작은술', category: IngredientCategory.seasoning),
      Ingredient(name: '간장', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
    ],
    instructions: [
      '계란을 풀어서 스크램블을 만들어주세요',
      '대파를 송송 썰어주세요',
      '팬에 기름을 두르고 김치를 볶아주세요',
      '밥을 넣고 함께 볶아주세요', 
      '계란과 대파를 넣고 볶아주세요',
      '간장과 참기름으로 간을 맞춰주세요'
    ],
    localImagePath: 'test_images/fried_rice_004.jpg',
    tags: ['#야근', '#간편식', '#볶음밥', '#피로'],
    createdAt: DateTime.now().subtract(Duration(days: 3)),
    mood: Mood.tired,
    rating: 3,
    reminderDate: null,
    isFavorite: false,
  ),
  
  // 레시피 5: 그리움이 담긴 음식
  Recipe(
    id: 'recipe_005',
    title: '할머니표 손수제비',
    emotionalStory: '고향에 계신 할머니가 그리워서 어릴 때 할머니가 만들어주시던 손수제비를 만들어봤어요. 맛은 비슷하게 나왔지만 할머니의 손맛은 따라할 수 없네요.',
    ingredients: [
      Ingredient(name: '밀가루', amount: '2', unit: '컵', category: IngredientCategory.grain),
      Ingredient(name: '물', amount: '2/3', unit: '컵', category: IngredientCategory.other),
      Ingredient(name: '멸치', amount: '10', unit: '마리', category: IngredientCategory.seafood),
      Ingredient(name: '다시마', amount: '1', unit: '조각', category: IngredientCategory.vegetable),
      Ingredient(name: '감자', amount: '1', unit: '개', category: IngredientCategory.vegetable),
      Ingredient(name: '애호박', amount: '1/2', unit: '개', category: IngredientCategory.vegetable),
      Ingredient(name: '양파', amount: '1/2', unit: '개', category: IngredientCategory.vegetable),
    ],
    instructions: [
      '밀가루에 물을 넣고 반죽을 만들어주세요',
      '반죽을 30분간 숙성시켜주세요',
      '멸치와 다시마로 육수를 내주세요',
      '감자, 애호박, 양파를 썰어주세요',
      '끓는 육수에 야채를 넣어주세요',
      '반죽을 손으로 뜯어서 넣어주세요',
      '10분 정도 끓여서 완성해주세요'
    ],
    localImagePath: 'test_images/handmade_soup_005.jpg',
    tags: ['#할머니음식', '#그리움', '#손수제비', '#고향'],
    createdAt: DateTime.now().subtract(Duration(days: 7)),
    mood: Mood.nostalgic,
    rating: 5,
    reminderDate: null,
    isFavorite: true,
  ),
];
```

## 재료(Ingredient) 테스트 데이터

### 카테고리별 재료 샘플
```dart
const ingredientsByCategory = {
  IngredientCategory.vegetable: [
    Ingredient(name: '양파', amount: '1', unit: '개', category: IngredientCategory.vegetable),
    Ingredient(name: '당근', amount: '1', unit: '개', category: IngredientCategory.vegetable),
    Ingredient(name: '감자', amount: '2', unit: '개', category: IngredientCategory.vegetable),
    Ingredient(name: '배추', amount: '1/4', unit: '포기', category: IngredientCategory.vegetable),
    Ingredient(name: '시금치', amount: '100g', unit: 'g', category: IngredientCategory.vegetable),
    Ingredient(name: '브로콜리', amount: '1', unit: '송이', category: IngredientCategory.vegetable),
    Ingredient(name: '토마토', amount: '2', unit: '개', category: IngredientCategory.vegetable),
    Ingredient(name: '오이', amount: '1', unit: '개', category: IngredientCategory.vegetable),
  ],
  IngredientCategory.meat: [
    Ingredient(name: '쇠고기', amount: '200g', unit: 'g', category: IngredientCategory.meat),
    Ingredient(name: '돼지고기', amount: '300g', unit: 'g', category: IngredientCategory.meat),
    Ingredient(name: '닭고기', amount: '1', unit: '마리', category: IngredientCategory.meat),
    Ingredient(name: '닭가슴살', amount: '150g', unit: 'g', category: IngredientCategory.meat),
    Ingredient(name: '삼겹살', amount: '200g', unit: 'g', category: IngredientCategory.meat),
    Ingredient(name: '갈비', amount: '500g', unit: 'g', category: IngredientCategory.meat),
  ],
  IngredientCategory.seafood: [
    Ingredient(name: '고등어', amount: '1', unit: '마리', category: IngredientCategory.seafood),
    Ingredient(name: '새우', amount: '200g', unit: 'g', category: IngredientCategory.seafood),
    Ingredient(name: '오징어', amount: '1', unit: '마리', category: IngredientCategory.seafood),
    Ingredient(name: '조개', amount: '300g', unit: 'g', category: IngredientCategory.seafood),
    Ingredient(name: '멸치', amount: '20', unit: '마리', category: IngredientCategory.seafood),
    Ingredient(name: '참치캔', amount: '1', unit: '캔', category: IngredientCategory.seafood),
  ],
  IngredientCategory.dairy: [
    Ingredient(name: '우유', amount: '200ml', unit: 'ml', category: IngredientCategory.dairy),
    Ingredient(name: '치즈', amount: '100g', unit: 'g', category: IngredientCategory.dairy),
    Ingredient(name: '계란', amount: '3', unit: '개', category: IngredientCategory.dairy),
    Ingredient(name: '버터', amount: '50g', unit: 'g', category: IngredientCategory.dairy),
    Ingredient(name: '생크림', amount: '100ml', unit: 'ml', category: IngredientCategory.dairy),
    Ingredient(name: '요구르트', amount: '1', unit: '개', category: IngredientCategory.dairy),
  ],
  IngredientCategory.grain: [
    Ingredient(name: '쌀', amount: '2', unit: '컵', category: IngredientCategory.grain),
    Ingredient(name: '밀가루', amount: '1', unit: '컵', category: IngredientCategory.grain),
    Ingredient(name: '파스타', amount: '200g', unit: 'g', category: IngredientCategory.grain),
    Ingredient(name: '식빵', amount: '4', unit: '장', category: IngredientCategory.grain),
    Ingredient(name: '현미', amount: '1', unit: '컵', category: IngredientCategory.grain),
    Ingredient(name: '메밀면', amount: '200g', unit: 'g', category: IngredientCategory.grain),
  ],
  IngredientCategory.seasoning: [
    Ingredient(name: '소금', amount: '적당량', unit: null, category: IngredientCategory.seasoning),
    Ingredient(name: '설탕', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
    Ingredient(name: '간장', amount: '2', unit: '큰술', category: IngredientCategory.seasoning),
    Ingredient(name: '고춧가루', amount: '1', unit: '작은술', category: IngredientCategory.seasoning),
    Ingredient(name: '마늘', amount: '3', unit: '쪽', category: IngredientCategory.seasoning),
    Ingredient(name: '생강', amount: '1', unit: '조각', category: IngredientCategory.seasoning),
    Ingredient(name: '참기름', amount: '1', unit: '큰술', category: IngredientCategory.seasoning),
    Ingredient(name: '올리브오일', amount: '2', unit: '큰술', category: IngredientCategory.seasoning),
  ],
};
```

## 태그 테스트 데이터

### 감정 기반 태그 시스템
```dart
const emotionBasedTags = {
  // 상황별 태그
  'occasions': [
    '#생일', '#기념일', '#파티', '#데이트', '#집들이',
    '#명절', '#졸업', '#승진', '#합격', '#결혼기념일'
  ],
  
  // 감정별 태그
  'emotions': [
    '#기쁨', '#행복', '#슬픔', '#그리움', '#위로',
    '#평온', '#편안함', '#감사', '#설렘', '#피로'
  ],
  
  // 관계별 태그  
  'relationships': [
    '#혼밥', '#가족', '#친구', '#연인', '#아이들',
    '#부모님', '#할머니', '#동료', '#손님', '#반려동물'
  ],
  
  // 요리 스타일 태그
  'cooking_style': [
    '#간편식', '#정성요리', '#건강식', '#다이어트', '#야식',
    '#브런치', '#디저트', '#술안주', '#도시락', '#국물요리'
  ],
  
  // 시간대별 태그
  'time_based': [
    '#아침', '#점심', '#저녁', '#새벽', '#야근후',
    '#주말', '#휴일', '#비오는날', '#더운날', '#추운날'
  ]
};

// 태그 조합 테스트 케이스
const tagCombinations = [
  ['#혼밥', '#평온', '#저녁', '#건강식'],
  ['#기념일', '#가족', '#정성요리', '#감사'],
  ['#야근후', '#피로', '#간편식', '#야식'],
  ['#그리움', '#할머니', '#국물요리', '#집밥'],
  ['#데이트', '#설렘', '#브런치', '#특별한날'],
];
```

## OpenAI API 모킹 데이터

### 사진 분석 응답 샘플
```json
{
  "testimg1_response": {
    "choices": [
      {
        "message": {
          "content": "{\"dish_name\": \"김치찌개\", \"ingredients\": [{\"name\": \"김치\", \"amount\": \"200g\"}, {\"name\": \"돼지고기\", \"amount\": \"150g\"}, {\"name\": \"두부\", \"amount\": \"1/2모\"}, {\"name\": \"양파\", \"amount\": \"1/2개\"}, {\"name\": \"대파\", \"amount\": \"1대\"}], \"instructions\": [\"김치를 기름에 볶는다\", \"돼지고기를 넣고 함께 볶는다\", \"물을 넣고 끓인다\", \"두부와 양파를 넣는다\", \"대파를 넣고 마무리한다\"], \"estimated_time\": \"30분\", \"difficulty\": \"쉬움\", \"servings\": \"2-3인분\"}"
        }
      }
    ]
  },
  "testimg2_response": {
    "choices": [
      {
        "message": {
          "content": "{\"dish_name\": \"토마토 파스타\", \"ingredients\": [{\"name\": \"파스타면\", \"amount\": \"200g\"}, {\"name\": \"토마토소스\", \"amount\": \"1캔\"}, {\"name\": \"마늘\", \"amount\": \"3쪽\"}, {\"name\": \"올리브오일\", \"amount\": \"2큰술\"}, {\"name\": \"바질\", \"amount\": \"적당량\"}], \"instructions\": [\"파스타면을 삶는다\", \"마늘을 올리브오일에 볶는다\", \"토마토소스를 넣고 끓인다\", \"삶은 면을 넣고 섞는다\", \"바질을 올려 완성한다\"], \"estimated_time\": \"20분\", \"difficulty\": \"보통\", \"servings\": \"1-2인분\"}"
        }
      }
    ]
  },
  "testimg3_response": {
    "choices": [
      {
        "message": {
          "content": "{\"dish_name\": \"한정식 상차림\", \"ingredients\": [{\"name\": \"밥\", \"amount\": \"4공기\"}, {\"name\": \"미역국\", \"amount\": \"1냄비\"}, {\"name\": \"김치\", \"amount\": \"적당량\"}, {\"name\": \"나물 반찬\", \"amount\": \"여러 종류\"}, {\"name\": \"구이\", \"amount\": \"1가지\"}], \"instructions\": [\"각각의 반찬을 정성스럽게 준비한다\", \"상에 조화롭게 배치한다\", \"국과 밥을 함께 차린다\"], \"estimated_time\": \"2시간 이상\", \"difficulty\": \"어려움\", \"servings\": \"4인분 이상\"}"
        }
      }
    ]
  }
}
```

### API 에러 응답 샘플
```json
{
  "error_responses": {
    "invalid_image": {
      "error": {
        "message": "Invalid image format",
        "type": "invalid_request_error",
        "code": "invalid_image"
      }
    },
    "api_key_invalid": {
      "error": {
        "message": "Incorrect API key provided",
        "type": "invalid_request_error",
        "code": "invalid_api_key"
      }
    },
    "rate_limit": {
      "error": {
        "message": "Rate limit reached",
        "type": "rate_limit_error",
        "code": "rate_limit_exceeded"
      }
    },
    "network_timeout": {
      "error": {
        "message": "Request timed out",
        "type": "timeout_error",
        "code": "timeout"
      }
    }
  }
}
```

## "과거 오늘" 기능 테스트 데이터

### 날짜 기반 회상 레시피
```dart
// 현재 날짜: 2024-12-15라고 가정
final pastTodayRecipes = [
  // 1년 전 오늘 (2023-12-15)
  Recipe(
    id: 'past_today_001',
    title: '작년 크리스마스 준비',
    emotionalStory: '작년 이맘때 크리스마스 파티를 준비하며 만들었던 치킨... 올해는 어떤 요리를 해볼까?',
    createdAt: DateTime(2023, 12, 15, 18, 30),
    mood: Mood.excited,
    tags: ['#크리스마스', '#파티', '#1년전오늘'],
    // ... 기타 필드들
  ),
  
  // 2년 전 오늘 (2022-12-15)
  Recipe(
    id: 'past_today_002', 
    title: '첫 원룸에서 만든 김치찌개',
    emotionalStory: '독립 후 첫 겨울, 추워서 뜨거운 국물이 그리워 만든 김치찌개. 그때가 벌써 2년 전이네요.',
    createdAt: DateTime(2022, 12, 15, 19, 45),
    mood: Mood.nostalgic,
    tags: ['#독립', '#첫원룸', '#2년전오늘', '#김치찌개'],
    // ... 기타 필드들
  ),
  
  // 3년 전 오늘 (2021-12-15) 
  Recipe(
    id: 'past_today_003',
    title: '재택근무 중 만든 간단 파스타',
    emotionalStory: '코로나 시기 재택근무 중이었는데, 점심으로 간단한 파스타를 만들어 먹었네요. 그때가 벌써 3년 전...',
    createdAt: DateTime(2021, 12, 15, 12, 20),
    mood: Mood.peaceful,
    tags: ['#재택근무', '#코로나시기', '#3년전오늘', '#파스타'],
    // ... 기타 필드들
  ),
];
```

## 통계 계산용 테스트 데이터

### 감정 분포 계산용 데이터
```dart
final statisticsTestData = {
  // 30일 간의 레시피 데이터 (감정 분포 계산용)
  'monthly_recipes': List.generate(30, (index) {
    return Recipe(
      id: 'stat_recipe_$index',
      title: '테스트 레시피 $index',
      emotionalStory: '테스트용 감정 이야기',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      mood: Mood.values[index % Mood.values.length], // 감정 순환
      ingredients: [
        Ingredient(name: '테스트 재료', amount: '100g', unit: 'g', category: IngredientCategory.other)
      ],
      instructions: ['테스트 조리법'],
      tags: ['#테스트'],
    );
  }),
  
  // 요리 패턴 분석용 (태그 빈도)
  'tag_frequency': {
    '#혼밥': 15,
    '#가족': 12,
    '#건강식': 10,
    '#간편식': 8,
    '#기념일': 5,
    '#야식': 7,
    '#국물요리': 9,
    '#디저트': 4,
    '#도시락': 6,
    '#브런치': 3,
  },
  
  // 연속 기록 계산용
  'continuous_days': [
    DateTime.now(),
    DateTime.now().subtract(Duration(days: 1)),
    DateTime.now().subtract(Duration(days: 2)),
    DateTime.now().subtract(Duration(days: 3)),
    // 4일 연속 기록
  ],
  
  // 시간대별 요리 패턴
  'time_patterns': {
    'morning': 3,   // 06:00-12:00
    'afternoon': 5, // 12:00-18:00  
    'evening': 22,  // 18:00-24:00
    'late_night': 2, // 00:00-06:00
  }
};
```

## 검색 테스트 데이터

### 검색 쿼리별 예상 결과
```dart
final searchTestCases = [
  // 요리명 검색
  {
    'query': '김치찌개',
    'expectedCount': 3,
    'expectedRecipeIds': ['recipe_002', 'recipe_search_001', 'recipe_search_002'],
    'searchType': 'title'
  },
  
  // 감정 검색
  {
    'query': '슬픔',
    'mood': Mood.sad,
    'expectedCount': 2,
    'expectedRecipeIds': ['recipe_002', 'recipe_sad_001'],
    'searchType': 'emotion'
  },
  
  // 태그 검색
  {
    'query': '#혼밥',
    'expectedCount': 5,
    'expectedRecipeIds': ['recipe_003', 'recipe_search_003', 'recipe_search_004'],
    'searchType': 'tag'
  },
  
  // 복합 검색 (감정 + 요리명)
  {
    'query': '스테이크',
    'mood': Mood.happy,
    'expectedCount': 1,
    'expectedRecipeIds': ['recipe_001'],
    'searchType': 'combined'
  },
  
  // 빈 검색 결과
  {
    'query': '존재하지않는요리',
    'expectedCount': 0,
    'expectedRecipeIds': [],
    'searchType': 'empty'
  },
];
```

## 입력 검증 테스트 데이터

### 유효한 입력값
```dart
final validInputs = {
  'recipe_titles': [
    '엄마표 김치찌개',
    '간단한 계란후라이',
    '특별한 날의 스테이크', 
    '혼자 먹는 라면',
    'a', // 최소 1글자
    'A' * 100, // 최대 100글자
  ],
  
  'emotional_stories': [
    '오늘 기분이 좋아서 만들어봤어요.',
    '힘든 하루였지만 요리하면서 마음이 편해졌습니다.',
    'A', // 최소 1글자
    'A' * 1000, // 최대 1000글자
  ],
  
  'tags': [
    '#혼밥',
    '#가족시간',
    '#a', // 최소 2글자 (#포함)
    '#' + 'A' * 19, // 최대 20글자
  ],
  
  'ratings': [1, 2, 3, 4, 5], // 1-5 점수
};
```

### 무효한 입력값 (검증 실패 케이스)
```dart
final invalidInputs = {
  'recipe_titles': [
    '', // 빈 문자열
    'A' * 101, // 길이 초과
    null, // null
  ],
  
  'emotional_stories': [
    '', // 빈 문자열
    'A' * 1001, // 길이 초과  
    null, // null
  ],
  
  'tags': [
    'hashtag', // # 없음
    '#', // # 만 있음
    '#' + 'A' * 20, // 길이 초과
  ],
  
  'ratings': [0, 6, -1, null], // 범위 벗어남
};
```

## 경계값 테스트 데이터

### 극한값 테스트
```dart
final boundaryTestCases = {
  // 최대 레시피 수 (성능 테스트용)
  'max_recipes': 10000,
  
  // 최대 재료 수
  'max_ingredients': 50,
  
  // 최대 조리 단계
  'max_instructions': 30,
  
  // 최대 태그 수
  'max_tags': 20,
  
  // 이미지 크기 제한
  'max_image_size': 10 * 1024 * 1024, // 10MB
  
  // API 호출 제한
  'api_rate_limit': 60, // per minute
  
  // 검색 결과 페이지 크기
  'search_page_size': 20,
  
  // 최대 검색 키워드 길이
  'max_search_query_length': 100,
};
```

## 날짜/시간 테스트 데이터

### 다양한 날짜 시나리오
```dart
final dateTimeTestCases = {
  'current': DateTime.now(),
  'yesterday': DateTime.now().subtract(Duration(days: 1)),
  'last_week': DateTime.now().subtract(Duration(days: 7)),
  'last_month': DateTime.now().subtract(Duration(days: 30)),
  'last_year': DateTime.now().subtract(Duration(days: 365)),
  
  // 특수한 날짜들
  'leap_year': DateTime(2024, 2, 29), // 윤년
  'new_year': DateTime(2024, 1, 1),
  'christmas': DateTime(2024, 12, 25),
  
  // 시간대 테스트
  'early_morning': DateTime(2024, 12, 15, 6, 0),
  'lunch_time': DateTime(2024, 12, 15, 12, 30),
  'dinner_time': DateTime(2024, 12, 15, 19, 0),
  'late_night': DateTime(2024, 12, 15, 23, 30),
};
```

## Puppeteer MCP 테스트용 시나리오 데이터

### 브라우저 자동화 테스트 스크립트
```javascript
// JavaScript 테스트 시나리오 (Puppeteer MCP용)
const puppeteerTestScenarios = {
  // 음식 사진 업로드 및 분석 테스트
  photoAnalysisTest: {
    testImg1: {
      path: './testimg1.jpg',
      expectedText: ['김치찌개', '재료', '조리법'],
      timeout: 15000
    },
    testImg2: {
      path: './testimg2.jpg', 
      expectedText: ['파스타', '토마토', '올리브오일'],
      timeout: 15000
    },
    testImg3: {
      path: './testimg3.jpg',
      expectedText: ['한정식', '반찬', '상차림'],
      timeout: 15000
    }
  },
  
  // UI 인터랙션 테스트
  uiInteractionTest: {
    fabClick: '#fab_main',
    bottomNavTabs: ['#nav_home', '#nav_search', '#nav_stats', '#nav_archive', '#nav_settings'],
    searchInput: '#search_input',
    recipeForm: {
      title: '#recipe_title_input',
      emotionalStory: '#emotional_story_textarea',
      photoUpload: '#photo_upload_input',
      saveButton: '#save_recipe_button'
    }
  },
  
  // 폼 데이터 입력 테스트
  formDataTest: {
    validRecipe: {
      title: '테스트 레시피',
      emotionalStory: '테스트용 감정 이야기입니다.',
      tags: '#테스트 #자동화',
      rating: 4
    },
    invalidRecipe: {
      title: '', // 빈 제목
      emotionalStory: 'A'.repeat(1001), // 길이 초과
      tags: 'no_hashtag', // # 없는 태그
      rating: 6 // 범위 벗어남
    }
  }
};
```

## 성능 테스트 데이터

### 대량 데이터 세트
```dart
// 성능 테스트용 대량 레시피 생성
final performanceTestData = List.generate(1000, (index) {
  final moods = Mood.values;
  final categories = IngredientCategory.values;
  
  return Recipe(
    id: 'perf_recipe_$index',
    title: '성능 테스트 레시피 $index',
    emotionalStory: '이것은 성능 테스트를 위한 샘플 감정 이야기입니다. ' * 5, // 긴 텍스트
    ingredients: List.generate(10, (i) => Ingredient(
      name: '재료 $i',
      amount: '${i * 100}g',
      unit: 'g',
      category: categories[i % categories.length],
    )),
    instructions: List.generate(8, (i) => '조리 단계 ${i + 1}'),
    tags: ['#성능테스트', '#대량데이터', '#테스트$index'],
    createdAt: DateTime.now().subtract(Duration(days: index % 365)),
    mood: moods[index % moods.length],
    rating: (index % 5) + 1,
    localImagePath: 'test_images/perf_image_${index % 10}.jpg',
    isFavorite: index % 10 == 0,
  );
});

// 검색 성능 테스트용 키워드
final searchPerformanceTests = {
  'short_query': '김치',
  'medium_query': '엄마가 만든 김치찌개',
  'long_query': '오늘 힘든 하루를 보내고 집에 와서 엄마가 해주던 그 맛있는 김치찌개가 그리워서',
  'common_tag': '#혼밥',
  'rare_tag': '#특별한기념일',
  'emoji_query': '😊 기쁨',
};
```

## 사용 방법

### 테스트 데이터 로딩
```dart
// 테스트 레시피 데이터 로드
final recipes = testRecipes;

// 특정 감정 레시피만 필터링
final sadRecipes = recipes.where((r) => r.mood == Mood.sad).toList();

// OpenAI 모킹 응답 사용
when(mockOpenAiService.analyzeImage(any))
  .thenAnswer((_) async => testImg1Response);

// "과거 오늘" 기능 테스트
final pastRecipes = getPastTodayRecipes(DateTime.now());
```

### Puppeteer MCP 테스트 실행
```bash
# Flutter 웹 빌드
flutter build web

# 로컬 서버 실행 (포트 8080)
python -m http.server 8080 -d build/web

# Puppeteer MCP 테스트 실행
# (testimg1.jpg, testimg2.jpg, testimg3.jpg 파일이 준비되어야 함)
```

---
*이 테스트 데이터는 Recipesoup 앱의 감정 기반 레시피 아카이빙 특성을 완전히 반영하여 작성되었으며, 모든 테스트 시나리오를 커버합니다.*