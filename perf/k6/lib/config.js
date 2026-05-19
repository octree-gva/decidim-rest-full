export const baseUrl = __ENV.K6_BASE_URL || 'http://localhost:3000';
export const apiPrefix = __ENV.K6_API_PREFIX || '/api/rest_full/v0.3';

export function apiUrl(path) {
  return `${baseUrl}${apiPrefix}${path}`;
}

export const thinkTimeMin = Number(__ENV.K6_THINK_MIN || 5);
export const thinkTimeMax = Number(__ENV.K6_THINK_MAX || 30);
