import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { passwordToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 2),
  duration: __ENV.K6_DURATION || '1m',
};

const draftId = __ENV.K6_DRAFT_PROPOSAL_ID;

export function setup() {
  const token = passwordToken('proposals');
  if (!token || !draftId) {
    throw new Error('Set K6_USER_* and K6_DRAFT_PROPOSAL_ID');
  }
  return { token };
}

export default function (data) {
  const res = http.post(
    `${apiUrl(`/draft_proposals/${draftId}/publish`)}`,
    null,
    { headers: authHeaders(data.token) }
  );
  check(res, { 'publishDraftProposalAsync 202': (r) => r.status === 202 });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
