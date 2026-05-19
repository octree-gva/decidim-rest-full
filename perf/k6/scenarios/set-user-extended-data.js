import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { passwordToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 2),
  duration: __ENV.K6_DURATION || '1m',
};

export function setup() {
  const token = passwordToken('oauth');
  if (!token) {
    throw new Error('Set K6_USER_* with oauth scope');
  }
  return { token };
}

export default function (data) {
  const body = {
    data: { k6_last_run: Date.now() },
    object_path: '.',
  };
  const res = http.put(
    `${apiUrl('/me/extended_data')}`,
    JSON.stringify(body),
    { headers: authHeaders(data.token) }
  );
  check(res, { 'setUserExtendedData 202': (r) => r.status === 202 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
