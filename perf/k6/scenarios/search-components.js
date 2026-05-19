import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { clientCredentialsToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 10),
  duration: __ENV.K6_DURATION || '1m',
};

export function setup() {
  const token = clientCredentialsToken('public');
  if (!token) {
    throw new Error('Set K6_CLIENT_ID and K6_CLIENT_SECRET');
  }
  return { token };
}

export default function (data) {
  const res = http.get(
    `${apiUrl('/components/search')}?page=1&per_page=10&filter[manifest_name]=proposals`,
    { headers: authHeaders(data.token) }
  );
  check(res, { 'searchComponents 200': (r) => r.status === 200 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
