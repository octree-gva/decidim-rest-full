import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { passwordToken, authHeaders } from '../lib/auth.js';

export const options = {
  vus: Number(__ENV.K6_VUS || 5),
  duration: __ENV.K6_DURATION || '1m',
};

const proposalId = __ENV.K6_PROPOSAL_ID;
const useAsync = (__ENV.K6_VOTE_ASYNC || 'true') === 'true';

export function setup() {
  const token = passwordToken('proposals');
  if (!token || !proposalId) {
    throw new Error('Set K6_USER_*, K6_PROPOSAL_ID');
  }
  return { token };
}

export default function (data) {
  const path = useAsync ? '/vote_proposals' : '/vote_proposals/sync';
  const res = http.post(
    `${apiUrl(path)}`,
    JSON.stringify({ proposal_id: Number(proposalId), data: { weight: 1 } }),
    { headers: authHeaders(data.token) }
  );
  const ok = useAsync ? res.status === 202 : res.status === 200;
  check(res, { 'castProposalVote accepted': () => ok });
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}
