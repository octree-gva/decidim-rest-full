import http from 'k6/http';
import { check, sleep } from 'k6';
import { apiUrl, thinkTimeMin, thinkTimeMax } from '../lib/config.js';
import { clientCredentialsToken, passwordToken, authHeaders } from '../lib/auth.js';

// Suggested mix: 50% searchComponents, 25% reads, 15% async writes, 10% votes
export const options = {
  scenarios: {
    mixed: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: Number(__ENV.K6_TARGET_VUS || 100) },
        { duration: '5m', target: Number(__ENV.K6_TARGET_VUS || 100) },
        { duration: '2m', target: 0 },
      ],
    },
  },
};

export function setup() {
  return {
    readToken: clientCredentialsToken('public proposals blogs'),
    writeToken: passwordToken('proposals system'),
  };
}

function think() {
  sleep(thinkTimeMin + Math.random() * (thinkTimeMax - thinkTimeMin));
}

export default function (data) {
  const roll = Math.random();

  if (roll < 0.5 && data.readToken) {
    const res = http.get(`${apiUrl('/components/search')}?page=1&per_page=10`, {
      headers: authHeaders(data.readToken),
      tags: { name: 'searchComponents' },
    });
    check(res, { searchComponents: (r) => r.status === 200 || r.status === 304 });
  } else if (roll < 0.65 && data.readToken && __ENV.K6_PROPOSAL_ID) {
    const res = http.get(`${apiUrl(`/proposals/${__ENV.K6_PROPOSAL_ID}`)}`, {
      headers: authHeaders(data.readToken),
      tags: { name: 'getProposal' },
    });
    check(res, { getProposal: (r) => r.status === 200 || r.status === 304 });
  } else if (roll < 0.75 && data.readToken && __ENV.K6_BLOG_POST_ID) {
    const res = http.get(`${apiUrl(`/blogs/${__ENV.K6_BLOG_POST_ID}`)}`, {
      headers: authHeaders(data.readToken),
      tags: { name: 'getBlogPost' },
    });
    check(res, { getBlogPost: (r) => r.status === 200 || r.status === 304 });
  } else if (roll < 0.9 && data.writeToken && __ENV.K6_PROPOSAL_ID) {
    const res = http.post(
      `${apiUrl('/vote_proposals')}`,
      JSON.stringify({ proposal_id: Number(__ENV.K6_PROPOSAL_ID), data: { weight: 1 } }),
      { headers: authHeaders(data.writeToken), tags: { name: 'castProposalVoteAsync' } }
    );
    check(res, { castProposalVoteAsync: (r) => r.status === 202 || r.status === 400 });
  } else if (data.writeToken) {
    const res = http.post(`${apiUrl('/draft_proposals')}`, JSON.stringify({
      data: { type: 'draft_proposals', attributes: { title: { en: 'k6' }, body: { en: 'x' } } },
      component_id: Number(__ENV.K6_COMPONENT_ID || 1),
    }), { headers: authHeaders(data.writeToken), tags: { name: 'createDraftProposal' } });
    check(res, { createDraftProposal: (r) => r.status === 202 || r.status === 400 });
  }

  think();
}
