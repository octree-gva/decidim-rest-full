import http from 'k6/http';
import { check } from 'k6';
import { apiUrl } from '../lib/config.js';
import { clientCredentialsToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 50),
  duration: __ENV.K6_DURATION || '2m',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
  },
};

export function setup() {
  const token = clientCredentialsToken('public');
  return { token };
}

export default function (data) {
  if (!data.token) {
    check(null, { skipped: () => true });
    return;
  }

  const res = http.get(
    `${apiUrl('/components/search')}?page=1&per_page=5`,
    { headers: authHeaders(data.token), tags: { name: 'searchComponents' } }
  );
  check(res, {
    'searchComponents status': (r) => r.status === 200 || r.status === 304,
  });
}
