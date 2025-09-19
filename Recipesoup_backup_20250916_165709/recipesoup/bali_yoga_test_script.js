// 🧪 발리 요가 특별공간 Unlock 자동화 테스트 스크립트
// Chrome 개발자 도구 콘솔에서 실행하세요

console.log("🧪 발리 요가 unlock 테스트 시작!");

// 테스트 데이터
const testRecipes = [
  {
    title: "아침 명상 후 건강한 스무디",
    emotionalStory: "아침 요가와 명상을 마치고 몸과 마음이 편안해져서 건강한 스무디를 만들었습니다.",
    mood: "peaceful",
    keywords: ["요가", "명상", "몸", "마음", "건강"]
  },
  {
    title: "마음이 편안해지는 허브티",
    emotionalStory: "스트레스가 많았던 하루, 웰빙을 위해 허브티를 우려 마음의 평온을 찾았어요.",
    mood: "peaceful",
    keywords: ["웰빙", "마음"]
  },
  {
    title: "균형잡힌 샐러드",
    emotionalStory: "몸의 균형을 맞추기 위해 영양가 있는 샐러드로 건강을 챙겼습니다.",
    mood: "peaceful",
    keywords: ["균형", "몸", "건강"]
  }
];

// Flutter 앱이 로드될 때까지 대기
function waitForFlutterApp() {
  return new Promise((resolve) => {
    const checkInterval = setInterval(() => {
      // Flutter 앱 확인 (예: flt-renderer 요소 존재)
      if (document.querySelector('flt-renderer') ||
          document.querySelector('flutter-view')) {
        clearInterval(checkInterval);
        console.log("✅ Flutter 앱 로드 완료");
        resolve();
      }
    }, 1000);
  });
}

// FAB 클릭 시뮬레이션
function clickFAB() {
  // FAB 버튼 찾기 시도
  const fabSelectors = [
    'button[aria-label*="add"]',
    'button[aria-label*="추가"]',
    '.floating-action-button',
    '[data-testid="fab"]',
    'button[title*="추가"]'
  ];

  for (const selector of fabSelectors) {
    const fab = document.querySelector(selector);
    if (fab) {
      console.log("🔘 FAB 버튼 클릭:", selector);
      fab.click();
      return true;
    }
  }

  console.log("❌ FAB 버튼을 찾을 수 없습니다");
  return false;
}

// 레시피 작성 폼 채우기
function fillRecipeForm(recipe, index) {
  console.log(`📝 레시피 ${index + 1} 작성 중:`, recipe.title);

  // 제목 입력
  const titleInput = document.querySelector('input[placeholder*="제목"]') ||
                     document.querySelector('input[aria-label*="제목"]');
  if (titleInput) {
    titleInput.value = recipe.title;
    titleInput.dispatchEvent(new Event('input', { bubbles: true }));
    console.log("✅ 제목 입력 완료");
  }

  // 감정 이야기 입력
  const storyInput = document.querySelector('textarea[placeholder*="감정"]') ||
                     document.querySelector('textarea[aria-label*="감정"]');
  if (storyInput) {
    storyInput.value = recipe.emotionalStory;
    storyInput.dispatchEvent(new Event('input', { bubbles: true }));
    console.log("✅ 감정 이야기 입력 완료");
  }

  // 감정 선택 (평온)
  const moodButtons = document.querySelectorAll('button[aria-label*="평온"]');
  if (moodButtons.length > 0) {
    moodButtons[0].click();
    console.log("✅ 감정 '평온' 선택 완료");
  }

  // 저장 버튼 클릭
  setTimeout(() => {
    const saveButton = document.querySelector('button[aria-label*="저장"]') ||
                       document.querySelector('button[title*="저장"]') ||
                       document.querySelector('button:contains("저장")');
    if (saveButton) {
      saveButton.click();
      console.log("💾 레시피 저장 완료");
    }
  }, 1000);
}

// 토끼굴 탭으로 이동
function navigateToBurrow() {
  const burrowTab = document.querySelector('button[aria-label*="토끼굴"]') ||
                    document.querySelector('[data-testid="burrow-tab"]');
  if (burrowTab) {
    burrowTab.click();
    console.log("🐰 토끼굴 탭으로 이동");
    return true;
  }
  console.log("❌ 토끼굴 탭을 찾을 수 없습니다");
  return false;
}

// 발리 요가 센터 unlock 확인
function checkBaliYogaUnlock() {
  setTimeout(() => {
    // 발리 요가 센터 요소 찾기
    const baliYogaElement = document.querySelector('[aria-label*="발리"]') ||
                           document.querySelector('[title*="발리"]') ||
                           document.querySelector(':contains("발리 요가")');

    if (baliYogaElement) {
      const isUnlocked = !baliYogaElement.classList.contains('locked') &&
                         !baliYogaElement.hasAttribute('disabled');

      if (isUnlocked) {
        console.log("🎉 SUCCESS: 발리 요가 센터 unlock 완료!");
        console.log("✅ Ultra Think HiveService 수정이 성공적으로 작동했습니다!");
      } else {
        console.log("❌ 발리 요가 센터가 아직 잠겨있습니다");
      }
    } else {
      console.log("❓ 발리 요가 센터 요소를 찾을 수 없습니다");
    }
  }, 2000);
}

// 메인 테스트 실행
async function runBaliYogaTest() {
  console.log("⏳ Flutter 앱 로드 대기 중...");
  await waitForFlutterApp();

  console.log("🚀 발리 요가 unlock 테스트 시작!");

  // 3개 레시피를 순차적으로 작성
  for (let i = 0; i < testRecipes.length; i++) {
    console.log(`\n--- 레시피 ${i + 1}/3 작성 ---`);

    // FAB 클릭
    if (!clickFAB()) {
      console.log("❌ FAB 클릭 실패, 수동으로 + 버튼을 눌러주세요");
      break;
    }

    // 잠시 대기 (화면 전환)
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 레시피 폼 작성
    fillRecipeForm(testRecipes[i], i);

    // 저장 후 대기
    await new Promise(resolve => setTimeout(resolve, 3000));
  }

  console.log("\n🔍 토끼굴에서 unlock 상태 확인...");

  // 토끼굴 탭으로 이동
  if (navigateToBurrow()) {
    checkBaliYogaUnlock();
  } else {
    console.log("❌ 토끼굴 탭 이동 실패, 수동으로 토끼굴 탭을 눌러주세요");
  }
}

// 테스트 실행
console.log("🎯 발리 요가 unlock 테스트를 시작하려면 다음을 실행하세요:");
console.log("runBaliYogaTest()");

// 수동 테스트 가이드도 제공
console.log("\n📋 수동 테스트 가이드:");
console.log("1. + 버튼 클릭");
console.log("2. 제목: '아침 명상 후 건강한 스무디'");
console.log("3. 감정: '평온' 선택");
console.log("4. 감정 이야기: '아침 요가와 명상을 마치고 몸과 마음이 편안해져서 건강한 스무디를 만들었습니다.'");
console.log("5. 저장 후 2회 더 반복");
console.log("6. 토끼굴 탭에서 발리 요가 센터 unlock 확인");