// Run: node --experimental-strip-types supabase/functions/push/handler.test.ts
//
// The handler decides who may send a notification, what is sent, and which
// device tokens are deleted. None of that was tested, because it lived in a
// file that calls Deno.serve at import time.

import assert from 'node:assert/strict';

import { handlePush } from './handler.ts';

const KEY = 'service-role-key-which-is-quite-long-abcdef';
let passed = 0;

async function test(name: string, body: () => Promise<void>) {
  try {
    await body();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (error) {
    console.error(`FAIL  ${name}\n      ${(error as Error).message}`);
    process.exitCode = 1;
  }
}

const env = (extra: Record<string, string> = {}) => {
  const values: Record<string, string> = {
    SUPABASE_SERVICE_ROLE_KEY: KEY,
    SUPABASE_URL: 'https://project.supabase.co',
    ...extra,
  };
  return (key: string) => values[key];
};

interface Call {
  url: string;
  method: string;
  headers: Record<string, string>;
  body?: unknown;
}

/// A fetch that answers from a table of url-substring → response, and records
/// everything it was asked for.
function recordingFetch(routes: [string, () => Response][]) {
  const calls: Call[] = [];
  const impl = (async (url: string | URL, init: RequestInit = {}) => {
    const href = String(url);
    calls.push({
      url: href,
      method: init.method ?? 'GET',
      headers: (init.headers ?? {}) as Record<string, string>,
      body: init.body,
    });
    for (const [needle, make] of routes) if (href.includes(needle)) return make();
    return new Response('no route', { status: 500 });
  }) as unknown as typeof fetch;
  return { impl, calls };
}

const post = (body: unknown, auth: string | null = `Bearer ${KEY}`) =>
  new Request('https://edge/push', {
    method: 'POST',
    headers: auth ? { authorization: auth } : {},
    body: JSON.stringify(body),
  });

const rows = (...r: unknown[]) => () =>
  new Response(JSON.stringify(r), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });

console.log('who may call it');

await test('no Authorization header is refused', async () => {
  const { impl, calls } = recordingFetch([]);
  const response = await handlePush(post({ user_id: 'u' }, null), env(), impl);
  assert.equal(response.status, 401);
  assert.equal(calls.length, 0, 'it read the database before checking the caller');
});

await test('a wrong key is refused', async () => {
  const { impl } = recordingFetch([]);
  const response = await handlePush(
    post({ user_id: 'u', title: 'T', body: 'B' }, `Bearer ${'x'.repeat(KEY.length)}`),
    env(),
    impl,
  );
  assert.equal(response.status, 401);
});

await test('a wrong key and a missing one are refused alike', async () => {
  // An endpoint that distinguishes them is an endpoint that helps you guess.
  const { impl } = recordingFetch([]);
  const a = await handlePush(post({ user_id: 'u' }, null), env(), impl);
  const b = await handlePush(post({ user_id: 'u' }, 'Bearer nope'), env(), impl);
  assert.equal(await a.text(), await b.text());
});

await test('an unset service role key does not open the door', async () => {
  const { impl } = recordingFetch([]);
  const blank = (key: string) =>
    key === 'SUPABASE_SERVICE_ROLE_KEY' ? '' : 'https://project.supabase.co';
  assert.equal((await handlePush(post({ user_id: 'u' }, null), blank, impl)).status, 401);
  assert.equal((await handlePush(post({ user_id: 'u' }, 'Bearer '), blank, impl)).status, 401);
});

await test('GET is not a way in', async () => {
  const { impl } = recordingFetch([]);
  const response = await handlePush(
    new Request('https://edge/push', { headers: { authorization: `Bearer ${KEY}` } }),
    env(),
    impl,
  );
  assert.equal(response.status, 405);
});

console.log('what it needs');

await test('user_id, title and body are required', async () => {
  const { impl } = recordingFetch([]);
  for (const body of [{}, { user_id: 'u' }, { user_id: 'u', title: 'T' }]) {
    assert.equal((await handlePush(post(body), env(), impl)).status, 400);
  }
});

console.log('sending');

await test('an iOS row goes to APNs with the topic and a bearer', async () => {
  const { impl, calls } = recordingFetch([
    ['/rest/v1/push_tokens', rows({ id: '1', platform: 'ios', token: 'devtok', p256dh: null, auth: null })],
    ['api.push.apple.com', () => new Response(null, { status: 200 })],
  ]);
  const response = await handlePush(
    post({ user_id: 'u', title: 'T', body: 'B' }),
    env({
      APNS_PRIVATE_KEY: await p8(),
      APNS_KEY_ID: 'KEYID12345',
      APNS_TEAM_ID: 'TEAM123456',
      APNS_TOPIC: 'my.get.teksi',
    }),
    impl,
  );
  assert.deepEqual(await response.json(), { devices: 1, sent: 1, removed: 0 });

  const send = calls.find((c) => c.url.includes('/3/device/'))!;
  assert.ok(send.url.endsWith('/3/device/devtok'));
  assert.equal(send.headers['apns-topic'], 'my.get.teksi');
});

await test('a dead token is deleted, a failing one is not', async () => {
  // The distinction worth having. An app deleted from a phone leaves a token
  // that fails for good; a push service having a bad minute does not.
  for (const [status, reason, removed] of [
    [410, 'Unregistered', 1],
    [429, 'TooManyRequests', 0],
  ] as const) {
    const { impl, calls } = recordingFetch([
      ['/rest/v1/push_tokens', rows({ id: 'row-1', platform: 'ios', token: 'devtok', p256dh: null, auth: null })],
      ['api.push.apple.com', () => new Response(JSON.stringify({ reason }), { status })],
    ]);
    const response = await handlePush(
      post({ user_id: 'u', title: 'T', body: 'B' }),
      env({
        APNS_PRIVATE_KEY: await p8(),
        APNS_KEY_ID: 'KEYID12345',
        APNS_TEAM_ID: 'TEAM123456',
        APNS_TOPIC: 'my.get.teksi',
      }),
      impl,
    );
    assert.equal((await response.json()).removed, removed, `status ${status}`);
    const deletes = calls.filter((c) => c.method === 'DELETE');
    assert.equal(deletes.length, removed, `status ${status} delete count`);
    if (removed) assert.ok(deletes[0].url.includes('row-1'), 'deleted the right row');
  }
});

await test('one device failing does not stop the others', async () => {
  const { impl } = recordingFetch([
    [
      '/rest/v1/push_tokens',
      rows(
        { id: '1', platform: 'ios', token: 'bad', p256dh: null, auth: null },
        { id: '2', platform: 'ios', token: 'good', p256dh: null, auth: null },
      ),
    ],
    ['/3/device/bad', () => { throw new Error('network'); }],
    ['/3/device/good', () => new Response(null, { status: 200 })],
  ]);
  const response = await handlePush(
    post({ user_id: 'u', title: 'T', body: 'B' }),
    env({
      APNS_PRIVATE_KEY: await p8(),
      APNS_KEY_ID: 'KEYID12345',
      APNS_TEAM_ID: 'TEAM123456',
      APNS_TOPIC: 'my.get.teksi',
    }),
    impl,
  );
  const result = await response.json();
  assert.equal(result.devices, 2);
  assert.equal(result.sent, 1, 'the good device still heard about it');
});

await test('no credentials means nothing is sent, not an error', async () => {
  // The state this ships in, before any key exists.
  const { impl, calls } = recordingFetch([
    ['/rest/v1/push_tokens', rows({ id: '1', platform: 'ios', token: 'devtok', p256dh: null, auth: null })],
  ]);
  const response = await handlePush(post({ user_id: 'u', title: 'T', body: 'B' }), env(), impl);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { devices: 1, sent: 0, removed: 0 });
  assert.equal(calls.filter((c) => c.url.includes('/3/device/')).length, 0);
});

/// A throwaway .p8, generated rather than written out.
async function p8(): Promise<string> {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
  ])) as CryptoKeyPair;
  const der = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
  let raw = '';
  for (const byte of der) raw += String.fromCharCode(byte);
  return `-----BEGIN PRIVATE KEY-----\n${btoa(raw).replace(/(.{64})/g, '$1\n')}\n-----END PRIVATE KEY-----\n`;
}

console.log(`\n${passed} passed`);
