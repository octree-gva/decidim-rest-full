import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { passwordToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 2),
  duration: __ENV.K6_DURATION || '1m',
};

const componentId = __ENV.K6_COMPONENT_ID;

export function setup() {
  const token = passwordToken('proposals');
  if (!token || !componentId) {
    throw new Error('Set K6_USER_*, K6_COMPONENT_ID');
  }
  return { token };
}

export default function (data) {
  const body = {
    data: {
      type: 'draft_proposals',
      attributes: {
        title: { en: `k6 draft ${__VU}-${Date.now()}` },
        body: { en: 'load test draft' }
      }
    },
    component_id: Number(componentId)
  };
  const res = http.post(`${apiUrl('/draft_proposals')}`, JSON.stringify(body), { headers: authHeaders(data.token) });
  check(res, { 'createDraftProposal 202': (r) => r.status === 202 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
