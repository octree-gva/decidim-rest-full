import http from 'k6/http';
import { check } from 'k6';
import { baseUrl } from './config.js';

export function clientCredentialsToken(scopes) {
  const clientId = __ENV.K6_CLIENT_ID;
  const clientSecret = __ENV.K6_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    return null;
  }

  const res = http.post(
    `${baseUrl}/oauth/token`,
    {
      grant_type: 'client_credentials',
      client_id: clientId,
      client_secret: clientSecret,
      scope: scopes || __ENV.K6_CLIENT_SCOPES || 'public',
    },
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );

  check(res, { 'token status 200': (r) => r.status === 200 });
  const body = res.json();
  return body && body.access_token;
}

export function passwordToken(scopes) {
  const email = __ENV.K6_USER_EMAIL;
  const password = __ENV.K6_USER_PASSWORD;
  if (!email || !password) {
    return null;
  }

  const res = http.post(
    `${baseUrl}/oauth/token`,
    {
      grant_type: 'password',
      username: email,
      password: password,
      scope: scopes || __ENV.K6_IMPERSONATION_SCOPES || 'proposals',
    },
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );

  check(res, { 'ropc token 200': (r) => r.status === 200 });
  const body = res.json();
  return body && body.access_token;
}

export function authHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}
