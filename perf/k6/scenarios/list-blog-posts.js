import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { clientCredentialsToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 10),
  duration: __ENV.K6_DURATION || '1m',
};

const spaceManifest = __ENV.K6_SPACE_MANIFEST || 'participatory_processes';
const spaceId = __ENV.K6_SPACE_ID;
const componentId = __ENV.K6_COMPONENT_ID;

export function setup() {
  const token = clientCredentialsToken('public blogs');
  if (!token || !spaceId || !componentId) {
    throw new Error('Set K6_CLIENT_*, K6_SPACE_ID, K6_COMPONENT_ID');
  }
  return { token };
}

export default function (data) {
  const q = `space_manifest=${spaceManifest}&space_id=${spaceId}&component_id=${componentId}&page=1&per_page=10`;
  const res = http.get(`${apiUrl('/blogs')}?${q}`, { headers: authHeaders(data.token) });
  check(res, { 'listBlogPosts 200': (r) => r.status === 200 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
