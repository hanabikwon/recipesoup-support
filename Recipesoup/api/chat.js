// Vercel 서버리스 함수 - OpenAI API 프록시 with Rate Limiting
import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  const startTime = Date.now();
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  const timestamp = new Date().toISOString();

  try {
    // CORS 헤더 설정
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-app-token');

    // OPTIONS 요청 처리 (CORS preflight)
    if (req.method === 'OPTIONS') {
      return res.status(200).end();
    }

    // POST 요청만 허용
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method Not Allowed' });
    }

    // 1. x-app-token 검증
    const appToken = req.headers['x-app-token'];
    if (!appToken || appToken !== process.env.PROXY_APP_TOKEN) {
      console.warn(`[${timestamp}] [UNAUTHORIZED] IP: ${clientIp} - Invalid token`);
      return res.status(401).json({ error: 'Unauthorized' });
    }

    console.log(`[${timestamp}] [REQUEST] IP: ${clientIp}, Method: ${req.method}`);

    // 2. Rate Limiting - 시간당 50회
    const rateLimitKey = `rate:${clientIp}`;
    const count = await kv.incr(rateLimitKey);

    // 첫 요청일 경우 TTL 설정 (1시간)
    if (count === 1) {
      await kv.expire(rateLimitKey, 3600); // 3600초 = 1시간
    }

    console.log(`[${timestamp}] [RATE_LIMIT] IP: ${clientIp}, Count: ${count}/50`);

    // Rate limit 초과 체크
    if (count > 50) {
      console.warn(`[${timestamp}] [BLOCKED] IP: ${clientIp} exceeded rate limit (${count}/50)`);

      // 통계 업데이트 - 차단된 요청
      const today = new Date().toISOString().split('T')[0];
      await kv.incr(`stats:daily:${today}:blocked`);

      return res.status(429).json({
        error: '요리 분석을 너무 많이 하셨어요! 🐰\n잠시 휴식 후 다시 시도해주세요.',
        retryAfter: 3600,
        remaining: 0
      });
    }

    // 3. 통계 업데이트 - 성공 요청
    const today = new Date().toISOString().split('T')[0];
    const hour = new Date().getHours();
    await kv.incr(`stats:daily:${today}:requests`);
    await kv.incr(`stats:daily:${today}:hour:${hour}`);

    // 4. OpenAI API 호출
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(req.body)
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error(`[${timestamp}] [OPENAI_ERROR] IP: ${clientIp}, Status: ${response.status}`, errorData);

      // OpenAI API 에러를 통계에 기록
      await kv.incr(`stats:daily:${today}:errors`);

      return res.status(response.status).json({
        error: 'OpenAI API 오류가 발생했습니다.',
        details: errorData
      });
    }

    const data = await response.json();

    // 5. 성공 로그 및 통계
    const duration = Date.now() - startTime;
    console.log(`[${timestamp}] [SUCCESS] IP: ${clientIp}, Duration: ${duration}ms, Cost: ~$0.0001`);

    // 통계 업데이트 - 성공
    await kv.incr(`stats:daily:${today}:success`);

    // 6. 응답 헤더에 Rate Limit 정보 추가
    res.setHeader('X-RateLimit-Limit', '50');
    res.setHeader('X-RateLimit-Remaining', Math.max(0, 50 - count));
    res.setHeader('X-RateLimit-Reset', Math.floor(Date.now() / 1000) + 3600);

    return res.status(200).json(data);

  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[${timestamp}] [ERROR] IP: ${clientIp}, Duration: ${duration}ms`, {
      error: error.message,
      stack: error.stack
    });

    // 에러 통계 업데이트
    try {
      const today = new Date().toISOString().split('T')[0];
      await kv.incr(`stats:daily:${today}:errors`);
    } catch (statError) {
      console.error('Failed to update error stats:', statError);
    }

    return res.status(500).json({
      error: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'
    });
  }
}
