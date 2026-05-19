import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { passwordToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 2),
  duration: __ENV.K6_DURATION || '1m',
};

export function setup() {
  const token = passwordToken('system');
  if (!token) {
    throw new Error('Set K6_USER_* with system scope');
  }
  return { token };
}

export default function (data) {
  const body = {
    data: {
      attributes: {
        resource_type: 'Decidim::ParticipatoryProcess',
        resource_id: Number(__ENV.K6_SPACE_ID || 1),
        user_id: Number(__ENV.K6_USER_ID || 1),
        type: 'space_administrator',
      },
    },
  };
  const res = http.post(`${apiUrl('/roles')}`, JSON.stringify(body), { headers: authHeaders(data.token) });
  check(res, { 'createRole 202': (r) => r.status === 202 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
