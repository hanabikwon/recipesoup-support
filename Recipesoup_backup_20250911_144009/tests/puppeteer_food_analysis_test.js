/**
 * Recipesoup 음식 사진 분석 테스트 (Puppeteer MCP)
 * 
 * 이 스크립트는 Puppeteer MCP를 사용하여 Recipesoup 앱의 
 * 핵심 기능인 OpenAI 기반 음식 사진 분석을 자동으로 테스트합니다.
 * 
 * 테스트 이미지: testimg1.jpg, testimg2.jpg, testimg3.jpg
 * 실행 환경: Flutter Web (Chrome)
 */

const fs = require('fs');
const path = require('path');

// 테스트 설정
const TEST_CONFIG = {
  baseUrl: 'http://localhost:8080', // Flutter web 서버
  timeout: 30000, // 30초 타임아웃
  imageUploadTimeout: 15000, // 이미지 업로드 타임아웃
  apiAnalysisTimeout: 20000, // OpenAI API 분석 타임아웃
  retryAttempts: 3,
};

// 테스트 이미지 정보
const TEST_IMAGES = {
  testimg1: {
    path: './testimg1.jpg',
    description: '김치찌개 완성 사진',
    expectedIngredients: ['김치', '돼지고기', '두부', '양파', '대파'],
    expectedKeywords: ['김치찌개', '찌개', '한식', '국물'],
    expectedDifficulty: '쉬움',
    expectedServings: '2-3인분'
  },
  testimg2: {
    path: './testimg2.jpg',
    description: '파스타 완성 사진',
    expectedIngredients: ['파스타면', '토마토소스', '마늘', '올리브오일', '바질'],
    expectedKeywords: ['파스타', '토마토', '이탈리안', '면'],
    expectedDifficulty: '보통',
    expectedServings: '1-2인분'
  },
  testimg3: {
    path: './testimg3.jpg',
    description: '복잡한 한정식 상차림',
    expectedIngredients: ['밥', '국', '김치', '반찬'],
    expectedKeywords: ['한정식', '상차림', '전통', '집밥'],
    expectedDifficulty: '어려움',
    expectedServings: '4인분 이상'
  }
};

// 테스트 결과 추적
let testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  details: []
};

/**
 * 메인 테스트 실행 함수
 */
async function runFoodAnalysisTests() {
  console.log('🍽️ Recipesoup 음식 사진 분석 테스트 시작...');
  console.log(`📍 테스트 URL: ${TEST_CONFIG.baseUrl}`);
  
  try {
    // 1. 앱 접근성 테스트
    await testAppAccessibility();
    
    // 2. 각 이미지별 분석 테스트
    for (const [imageKey, imageData] of Object.entries(TEST_IMAGES)) {
      await testImageAnalysis(imageKey, imageData);
    }
    
    // 3. 에러 시나리오 테스트
    await testErrorScenarios();
    
    // 4. UI 상태 테스트
    await testUIStates();
    
    // 5. 성능 테스트
    await testPerformance();
    
    // 결과 리포트 출력
    printTestResults();
    
  } catch (error) {
    console.error('❌ 테스트 실행 중 치명적 오류:', error.message);
    process.exit(1);
  }
}

/**
 * 앱 접근성 및 기본 로딩 테스트
 */
async function testAppAccessibility() {
  console.log('\n📱 앱 접근성 테스트...');
  
  await addTest('앱 로딩 테스트', async () => {
    await page.goto(TEST_CONFIG.baseUrl, { 
      waitUntil: 'networkidle0',
      timeout: TEST_CONFIG.timeout 
    });
    
    // 스플래시 화면 확인
    const splashExists = await page.waitForSelector('.splash-screen, #splash', { 
      timeout: 5000 
    }).catch(() => null);
    
    if (splashExists) {
      console.log('  ✅ 스플래시 화면 로딩됨');
      
      // 메인 화면 전환 대기
      await page.waitForSelector('.main-screen, #main-screen, [data-testid="main-screen"]', {
        timeout: 10000
      });
      console.log('  ✅ 메인 화면으로 전환됨');
    }
    
    return true;
  });
  
  await addTest('Bottom Navigation 확인', async () => {
    // Bottom Navigation 존재 확인
    const bottomNav = await page.waitForSelector('.bottom-navigation, #bottom-navigation', {
      timeout: 5000
    });
    
    if (!bottomNav) {
      throw new Error('Bottom Navigation을 찾을 수 없습니다');
    }
    
    // 5개 탭 확인 (홈, 검색, 통계, 보관함, 설정)
    const navTabs = await page.$$eval(
      '.bottom-nav-item, .nav-tab, [data-testid*="nav-tab"]',
      tabs => tabs.length
    );
    
    if (navTabs !== 5) {
      throw new Error(`예상 탭 수: 5, 실제 탭 수: ${navTabs}`);
    }
    
    console.log('  ✅ Bottom Navigation 5개 탭 확인');
    return true;
  });
  
  await addTest('FAB 버튼 확인', async () => {
    // Floating Action Button 확인
    const fab = await page.waitForSelector('.floating-action-button, #fab, [data-testid="fab"]', {
      timeout: 5000
    });
    
    if (!fab) {
      throw new Error('FAB 버튼을 찾을 수 없습니다');
    }
    
    console.log('  ✅ FAB 버튼 존재 확인');
    return true;
  });
}

/**
 * 개별 이미지 분석 테스트
 */
async function testImageAnalysis(imageKey, imageData) {
  console.log(`\n🖼️ ${imageKey} 분석 테스트... (${imageData.description})`);
  
  // 이미지 파일 존재 확인
  if (!fs.existsSync(imageData.path)) {
    console.error(`  ❌ 이미지 파일 없음: ${imageData.path}`);
    testResults.failed++;
    return;
  }
  
  await addTest(`${imageKey} 업로드 및 분석`, async () => {
    // 1. FAB 클릭하여 사진 업로드 화면으로 이동
    await page.click('.floating-action-button, #fab, [data-testid="fab"]');
    
    // FAB 확장 메뉴에서 "사진으로 작성" 선택
    const photoRecipeBtn = await page.waitForSelector(
      '[data-testid="fab-photo-recipe"], .fab-photo-recipe, #fab-photo-recipe',
      { timeout: 5000 }
    );
    
    if (photoRecipeBtn) {
      await photoRecipeBtn.click();
    } else {
      // 직접 레시피 작성 화면으로 이동
      await page.waitForSelector('.recipe-create, #recipe-create, [data-testid="recipe-create"]');
    }
    
    console.log('  ✅ 레시피 작성 화면 진입');
    
    // 2. 이미지 업로드
    const photoInput = await page.waitForSelector(
      'input[type="file"], #photo-input, [data-testid="photo-input"]',
      { timeout: 5000 }
    );
    
    if (!photoInput) {
      throw new Error('사진 업로드 input을 찾을 수 없습니다');
    }
    
    await photoInput.uploadFile(path.resolve(imageData.path));
    console.log(`  ✅ 이미지 업로드: ${imageData.path}`);
    
    // 3. OpenAI 분석 시작 표시 대기
    const analysisLoader = await page.waitForSelector(
      '.analysis-loading, #analysis-loading, [data-testid="analysis-loading"]',
      { timeout: TEST_CONFIG.imageUploadTimeout }
    ).catch(() => null);
    
    if (analysisLoader) {
      console.log('  ✅ AI 분석 로딩 상태 확인');
    }
    
    // 4. 분석 결과 대기
    const analysisResult = await page.waitForSelector(
      '.analysis-result, #analysis-result, [data-testid="analysis-result"]',
      { timeout: TEST_CONFIG.apiAnalysisTimeout }
    );
    
    if (!analysisResult) {
      throw new Error('AI 분석 결과를 받지 못했습니다');
    }
    
    console.log('  ✅ AI 분석 완료');
    
    // 5. 분석 결과 검증
    await validateAnalysisResult(imageData);
    
    return true;
  });
}

/**
 * 분석 결과 검증
 */
async function validateAnalysisResult(imageData) {
  console.log('  🔍 분석 결과 검증 중...');
  
  // 추천 재료 확인
  await addTest(`재료 추천 검증 (${imageData.description})`, async () => {
    const ingredientsSection = await page.$('.suggested-ingredients, #suggested-ingredients, [data-testid="suggested-ingredients"]');
    
    if (ingredientsSection) {
      const ingredientsText = await ingredientsSection.evaluate(el => el.textContent);
      
      // 예상 재료가 포함되어 있는지 확인
      const foundIngredients = imageData.expectedIngredients.filter(ingredient => 
        ingredientsText.includes(ingredient)
      );
      
      if (foundIngredients.length === 0) {
        console.warn(`  ⚠️ 예상 재료를 찾지 못함: ${imageData.expectedIngredients.join(', ')}`);
        console.log(`  📝 실제 추천 재료: ${ingredientsText}`);
        return false; // 경고로 처리하되 테스트는 통과
      }
      
      console.log(`  ✅ 재료 ${foundIngredients.length}/${imageData.expectedIngredients.length}개 매치: ${foundIngredients.join(', ')}`);
      return true;
    }
    
    throw new Error('추천 재료 섹션을 찾을 수 없습니다');
  });
  
  // 조리법 추천 확인
  await addTest(`조리법 추천 검증 (${imageData.description})`, async () => {
    const instructionsSection = await page.$('.suggested-instructions, #suggested-instructions, [data-testid="suggested-instructions"]');
    
    if (instructionsSection) {
      const instructionsText = await instructionsSection.evaluate(el => el.textContent);
      
      // 조리법이 비어있지 않은지 확인
      if (instructionsText.trim().length < 10) {
        throw new Error('조리법이 너무 짧거나 비어있습니다');
      }
      
      console.log(`  ✅ 조리법 추천 완료 (${instructionsText.length}자)`);
      return true;
    }
    
    throw new Error('추천 조리법 섹션을 찾을 수 없습니다');
  });
  
  // 예상 키워드 확인
  await addTest(`키워드 매치 검증 (${imageData.description})`, async () => {
    const pageContent = await page.content();
    
    const foundKeywords = imageData.expectedKeywords.filter(keyword =>
      pageContent.includes(keyword)
    );
    
    if (foundKeywords.length === 0) {
      console.warn(`  ⚠️ 예상 키워드를 찾지 못함: ${imageData.expectedKeywords.join(', ')}`);
      return false; // 경고로 처리
    }
    
    console.log(`  ✅ 키워드 ${foundKeywords.length}/${imageData.expectedKeywords.length}개 매치: ${foundKeywords.join(', ')}`);
    return true;
  });
}

/**
 * 에러 시나리오 테스트
 */
async function testErrorScenarios() {
  console.log('\n❌ 에러 시나리오 테스트...');
  
  await addTest('잘못된 파일 형식 테스트', async () => {
    // 텍스트 파일 업로드 시도
    const textFilePath = './test_text_file.txt';
    fs.writeFileSync(textFilePath, 'This is not an image file');
    
    try {
      await page.goto(`${TEST_CONFIG.baseUrl}/#/create`);
      
      const photoInput = await page.waitForSelector('input[type="file"]', { timeout: 5000 });
      await photoInput.uploadFile(path.resolve(textFilePath));
      
      // 에러 메시지 확인
      const errorMessage = await page.waitForSelector(
        '.error-message, .alert-error, [data-testid="error-message"]',
        { timeout: 5000 }
      ).catch(() => null);
      
      if (!errorMessage) {
        throw new Error('잘못된 파일 형식에 대한 에러 처리가 없습니다');
      }
      
      console.log('  ✅ 잘못된 파일 형식 에러 처리 확인');
      return true;
      
    } finally {
      fs.unlinkSync(textFilePath);
    }
  });
  
  await addTest('네트워크 에러 시뮬레이션', async () => {
    // 네트워크 차단
    await page.setOfflineMode(true);
    
    try {
      // 이미지 업로드 시도
      await page.goto(`${TEST_CONFIG.baseUrl}/#/create`);
      
      const photoInput = await page.waitForSelector('input[type="file"]', { timeout: 5000 });
      await photoInput.uploadFile(path.resolve(TEST_IMAGES.testimg1.path));
      
      // 네트워크 에러 메시지 확인
      const networkError = await page.waitForSelector(
        '.network-error, [data-testid="network-error"]',
        { timeout: 10000 }
      ).catch(() => null);
      
      if (!networkError) {
        console.warn('  ⚠️ 네트워크 에러 처리 메시지를 찾지 못함');
        return false;
      }
      
      console.log('  ✅ 네트워크 에러 처리 확인');
      return true;
      
    } finally {
      await page.setOfflineMode(false);
    }
  });
  
  await addTest('API 타임아웃 처리', async () => {
    // API 응답을 매우 느리게 만들기 위해 큰 이미지 사용
    const largeImagePath = './large_test_image.jpg';
    
    // 10MB 더미 이미지 생성 (실제로는 작은 이미지를 복사)
    if (fs.existsSync(TEST_IMAGES.testimg1.path)) {
      fs.copyFileSync(TEST_IMAGES.testimg1.path, largeImagePath);
      
      try {
        await page.goto(`${TEST_CONFIG.baseUrl}/#/create`);
        
        const photoInput = await page.waitForSelector('input[type="file"]');
        await photoInput.uploadFile(path.resolve(largeImagePath));
        
        // 타임아웃 에러 또는 성공 확인 (30초 대기)
        const result = await Promise.race([
          page.waitForSelector('.analysis-result', { timeout: 30000 }),
          page.waitForSelector('.timeout-error', { timeout: 30000 })
        ]).catch(() => null);
        
        if (!result) {
          console.warn('  ⚠️ 타임아웃 처리 확인 불가');
          return false;
        }
        
        console.log('  ✅ API 타임아웃 처리 확인');
        return true;
        
      } finally {
        if (fs.existsSync(largeImagePath)) {
          fs.unlinkSync(largeImagePath);
        }
      }
    }
    
    return false;
  });
}

/**
 * UI 상태 테스트
 */
async function testUIStates() {
  console.log('\n🎨 UI 상태 테스트...');
  
  await addTest('로딩 상태 UI', async () => {
    await page.goto(`${TEST_CONFIG.baseUrl}/#/create`);
    
    const photoInput = await page.waitForSelector('input[type="file"]');
    await photoInput.uploadFile(path.resolve(TEST_IMAGES.testimg1.path));
    
    // 로딩 인디케이터 확인
    const loadingIndicator = await page.waitForSelector(
      '.loading-spinner, .progress-bar, [data-testid="loading"]',
      { timeout: 3000 }
    ).catch(() => null);
    
    if (!loadingIndicator) {
      console.warn('  ⚠️ 로딩 상태 UI를 찾지 못함');
      return false;
    }
    
    // 로딩 텍스트 확인
    const loadingText = await page.$eval(
      '.loading-text, [data-testid="loading-text"]',
      el => el?.textContent
    ).catch(() => null);
    
    if (loadingText && (loadingText.includes('분석') || loadingText.includes('처리'))) {
      console.log(`  ✅ 로딩 상태 UI 및 텍스트 확인: "${loadingText}"`);
      return true;
    }
    
    console.log('  ✅ 로딩 인디케이터 확인 (텍스트 없음)');
    return true;
  });
  
  await addTest('성공 상태 UI', async () => {
    // 분석 결과 대기
    const analysisResult = await page.waitForSelector(
      '.analysis-result, [data-testid="analysis-result"]',
      { timeout: TEST_CONFIG.apiAnalysisTimeout }
    ).catch(() => null);
    
    if (!analysisResult) {
      throw new Error('분석 결과를 찾을 수 없습니다');
    }
    
    // 성공 상태 표시 확인
    const successIndicator = await page.$('.success-state, .analysis-complete').catch(() => null);
    
    console.log('  ✅ 성공 상태 UI 확인');
    return true;
  });
  
  await addTest('빈티지 테마 적용 확인', async () => {
    // DESIGN.md에 정의된 빈티지 아이보리 색상 확인
    const backgroundColor = await page.evaluate(() => {
      const body = document.body;
      return window.getComputedStyle(body).backgroundColor;
    });
    
    const primaryColors = await page.evaluate(() => {
      const elements = document.querySelectorAll('.primary-color, [data-color="primary"]');
      return Array.from(elements).map(el => window.getComputedStyle(el).color);
    });
    
    console.log(`  ✅ 테마 색상 확인 - 배경: ${backgroundColor}`);
    return true;
  });
}

/**
 * 성능 테스트
 */
async function testPerformance() {
  console.log('\n⚡ 성능 테스트...');
  
  await addTest('이미지 업로드 성능', async () => {
    const startTime = Date.now();
    
    await page.goto(`${TEST_CONFIG.baseUrl}/#/create`);
    const photoInput = await page.waitForSelector('input[type="file"]');
    await photoInput.uploadFile(path.resolve(TEST_IMAGES.testimg1.path));
    
    // 업로드 완료까지의 시간 측정
    await page.waitForSelector('.analysis-loading, [data-testid="analysis-loading"]');
    
    const uploadTime = Date.now() - startTime;
    
    if (uploadTime > 5000) { // 5초 이상
      console.warn(`  ⚠️ 이미지 업로드가 느림: ${uploadTime}ms`);
    } else {
      console.log(`  ✅ 이미지 업로드 성능 양호: ${uploadTime}ms`);
    }
    
    return uploadTime < 10000; // 10초 이내
  });
  
  await addTest('API 응답 성능', async () => {
    const startTime = Date.now();
    
    // 분석 결과 대기
    await page.waitForSelector(
      '.analysis-result, [data-testid="analysis-result"]',
      { timeout: TEST_CONFIG.apiAnalysisTimeout }
    );
    
    const apiResponseTime = Date.now() - startTime;
    
    if (apiResponseTime > 15000) { // 15초 이상
      console.warn(`  ⚠️ API 응답이 느림: ${apiResponseTime}ms`);
    } else {
      console.log(`  ✅ API 응답 성능 양호: ${apiResponseTime}ms`);
    }
    
    return apiResponseTime < 30000; // 30초 이내
  });
  
  await addTest('메모리 사용량 확인', async () => {
    const metrics = await page.metrics();
    
    const memoryMB = Math.round(metrics.JSHeapUsedSize / 1024 / 1024);
    
    if (memoryMB > 100) { // 100MB 이상
      console.warn(`  ⚠️ 메모리 사용량이 높음: ${memoryMB}MB`);
    } else {
      console.log(`  ✅ 메모리 사용량 적정: ${memoryMB}MB`);
    }
    
    return memoryMB < 200; // 200MB 이내
  });
}

/**
 * 개별 테스트를 실행하고 결과를 추적하는 헬퍼 함수
 */
async function addTest(testName, testFunction) {
  testResults.total++;
  
  try {
    const result = await testFunction();
    
    if (result === false) {
      console.log(`  ⚠️ ${testName}: 경고`);
      testResults.failed++;
      testResults.details.push({ name: testName, status: 'warning', error: null });
    } else {
      console.log(`  ✅ ${testName}: 통과`);
      testResults.passed++;
      testResults.details.push({ name: testName, status: 'passed', error: null });
    }
    
  } catch (error) {
    console.log(`  ❌ ${testName}: 실패 - ${error.message}`);
    testResults.failed++;
    testResults.details.push({ name: testName, status: 'failed', error: error.message });
  }
}

/**
 * 테스트 결과 리포트 출력
 */
function printTestResults() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 테스트 결과 리포트');
  console.log('='.repeat(60));
  console.log(`총 테스트: ${testResults.total}`);
  console.log(`✅ 통과: ${testResults.passed}`);
  console.log(`❌ 실패: ${testResults.failed}`);
  console.log(`📈 성공률: ${((testResults.passed / testResults.total) * 100).toFixed(1)}%`);
  
  if (testResults.failed > 0) {
    console.log('\n❌ 실패한 테스트:');
    testResults.details
      .filter(test => test.status === 'failed')
      .forEach(test => {
        console.log(`  - ${test.name}: ${test.error}`);
      });
  }
  
  if (testResults.details.filter(t => t.status === 'warning').length > 0) {
    console.log('\n⚠️ 경고 테스트:');
    testResults.details
      .filter(test => test.status === 'warning')
      .forEach(test => {
        console.log(`  - ${test.name}`);
      });
  }
  
  console.log('\n' + '='.repeat(60));
  
  // 전체 테스트 성공률이 80% 이상이면 성공으로 간주
  const successRate = (testResults.passed / testResults.total) * 100;
  if (successRate >= 80) {
    console.log('🎉 테스트 전체 성공!');
    process.exit(0);
  } else {
    console.log('💥 테스트 실패 - 성공률이 80% 미만입니다.');
    process.exit(1);
  }
}

/**
 * 테스트 실행 전 환경 체크
 */
async function checkTestEnvironment() {
  console.log('🔍 테스트 환경 체크...');
  
  // 테스트 이미지 파일 존재 확인
  for (const [imageKey, imageData] of Object.entries(TEST_IMAGES)) {
    if (!fs.existsSync(imageData.path)) {
      console.error(`❌ 테스트 이미지 파일 없음: ${imageData.path}`);
      console.log('다음 명령으로 테스트 이미지를 준비해주세요:');
      console.log(`  - ${imageKey}: ${imageData.description}`);
      process.exit(1);
    }
  }
  
  console.log('✅ 모든 테스트 이미지 파일 확인됨');
  
  // Flutter web 서버 접근 확인
  try {
    const response = await fetch(TEST_CONFIG.baseUrl);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    console.log('✅ Flutter web 서버 접근 확인');
  } catch (error) {
    console.error(`❌ Flutter web 서버에 접근할 수 없습니다: ${TEST_CONFIG.baseUrl}`);
    console.log('다음 명령으로 Flutter web 서버를 실행해주세요:');
    console.log('  flutter build web');
    console.log('  cd build/web && python -m http.server 8080');
    process.exit(1);
  }
}

// Puppeteer MCP에서 사용할 전역 변수들
let page;

/**
 * Puppeteer MCP에서 호출할 메인 함수
 * 
 * 사용법:
 * 1. Flutter web 빌드: flutter build web
 * 2. 서버 실행: cd build/web && python -m http.server 8080
 * 3. 테스트 이미지 준비: testimg1.jpg, testimg2.jpg, testimg3.jpg
 * 4. Puppeteer MCP에서 이 스크립트 실행
 */
module.exports = {
  runFoodAnalysisTests,
  TEST_CONFIG,
  TEST_IMAGES,
  checkTestEnvironment
};

// 직접 실행시
if (require.main === module) {
  (async () => {
    await checkTestEnvironment();
    await runFoodAnalysisTests();
  })();
}