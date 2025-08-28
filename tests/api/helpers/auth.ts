import { request, APIRequestContext } from '@playwright/test';

export async function newApiContext(baseURL?: string): Promise<APIRequestContext> {
  return await request.newContext({ baseURL });
}

export async function register(api: APIRequestContext, email: string, password: string) {
  const res = await api.post('/auth/register', { data: { email, password } });
  return { res, json: res.ok() ? await res.json() : null };
}

export async function login(api: APIRequestContext, email: string, password: string) {
  const res = await api.post('/auth/login', { data: { email, password } });
  return { res, json: res.ok() ? await res.json() : null };
}

export async function me(api: APIRequestContext, token: string) {
  const res = await api.get('/auth/me', { headers: { Authorization: `Bearer ${token}` } });
  return { res, json: res.ok() ? await res.json() : null };
}
