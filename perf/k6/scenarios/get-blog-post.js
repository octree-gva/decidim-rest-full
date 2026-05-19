import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { clientCredentialsToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 10),
  duration: __ENV.K6_DURATION || '1m',
};

export function setup() {
  const token = clientCredentialsToken('public blogs');
  const id = __ENV.K6_BLOG_POST_ID;
  if (!token || !id) {
    throw new Error('Set K6_CLIENT_* and K6_BLOG_POST_ID');
  }
  return { token, id };
}

export default function (data) {
  const res = http.get(`${apiUrl(`/blogs/${data.id}`)}`, { headers: authHeaders(data.token) });
  check(res, { 'getBlogPost 200': (r) => r.status === 200 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
