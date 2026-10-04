// Run: node --experimental-strip-types supabase/functions/_shared/apns.test.ts

import assert from 'node:assert/strict';

import { apnsPayload, apnsToken, sendApns, type ApnsKey } from './apns.ts';
import { b64urlToBytes } from './webpush.ts';

const encoder = new TextEncoder();
let passed = 0;

async function test(name: string, body: () => Promise<void> | void) {
  try {
    await body();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (error) {
    console.error(`FAIL  ${name}\n      ${(error as Error).message}`);
    process.exitCode = 1;
  }
}

/// A throwaway .p8, in the shape Apple hands one over: PKCS#8, PEM-wrapped,
/// wrapped at 64 columns.
async function makeKey(): Promise<{ key: ApnsKey; publicKey: CryptoKey }> {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
  let base64 = '';
  for (const byte of pkcs8) base64 += String.fromCharCode(byte);
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(base64).replace(/(.{64})/g, '$1\n')}\n-----END PRIVATE KEY-----\n`;
  return {
    key: { privateKeyPem: pem, keyId: 'ABC123DEFG', teamId: 'TEAM123456' },
    publicKey: pair.publicKey,
  };
}

console.log('apns token');

await test('is a JWT Apple can verify, with the key id in the header', async () => {
  const { key, publicKey } = await makeKey();
  const token = await apnsToken(key, Date.parse('2026-10-04T00:00:00Z'));
  const [h, c, s] = token.split('.');

  const header = JSON.parse(new TextDecoder().decode(b64urlToBytes(h)));
  const claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(c)));
  assert.equal(header.alg, 'ES256');
  assert.equal(header.kid, 'ABC123DEFG', 'the key id goes in the header, not the claims');
  assert.equal(claims.iss, 'TEAM123456', 'and the team id in the claims, not the header');
  assert.equal(claims.iat, Date.parse('2026-10-04T00:00:00Z') / 1000);

  assert.ok(
    await crypto.subtle.verify(
      { name: 'ECDSA', hash: 'SHA-256' },
      publicKey,
      b64urlToBytes(s),
      encoder.encode(`${h}.${c}`),
    ),
    'signature does not verify against the key that signed it',
  );
});

await test('reads a PEM whatever its line endings', async () => {
  const { key } = await makeKey();
  const windows = { ...key, privateKeyPem: key.privateKeyPem.replace(/\n/g, '\r\n') };
  assert.ok((await apnsToken(windows)).split('.').length === 3);
});

console.log('payload');

await test('puts Apple keys under aps and ours beside it', () => {
  const payload = JSON.parse(apnsPayload({ title: 'T', body: 'B', path: '/ride/1' }));
  assert.deepEqual(payload.aps.alert, { title: 'T', body: 'B' });
  assert.equal(payload.aps.sound, 'default');
  assert.equal(payload.path, '/ride/1', 'custom keys sit outside aps or Apple drops them');
});

console.log('send');

const realFetch = globalThis.fetch;
function stubFetch(status: number, body: unknown, capture?: (r: Request) => void) {
  globalThis.fetch = (async (url: string, init: RequestInit) => {
    capture?.({ url, init } as unknown as Request);
    return new Response(body === undefined ? null : JSON.stringify(body), { status });
  }) as typeof fetch;
}

await test('a 200 is a delivery', async () => {
  const { key } = await makeKey();
  let seen: { url: string; init: RequestInit } | undefined;
  stubFetch(200, undefined, (r) => {
    seen = r as unknown as { url: string; init: RequestInit };
  });
  const result = await sendApns('devtoken', { title: 'T', body: 'B' }, key, {
    topic: 'my.get.teksi',
  });
  assert.deepEqual(result, { ok: true, status: 200, gone: false });
  assert.ok(seen!.url.endsWith('/3/device/devtoken'));
  const headers = seen!.init.headers as Record<string, string>;
  assert.equal(headers['apns-topic'], 'my.get.teksi', 'the topic is the bundle id');
  assert.equal(headers['apns-priority'], '10');
  assert.ok(headers.authorization.startsWith('bearer '));
});

// The classification that matters. A token that will never work again has to
// be distinguishable from one that failed this time, or a deleted app leaves
// a row that fails on every send for good.
for (const [label, status, body, gone] of [
  ['410 Gone', 410, { reason: 'Unregistered' }, true],
  ['400 BadDeviceToken', 400, { reason: 'BadDeviceToken' }, true],
  ['429 TooManyRequests', 429, { reason: 'TooManyRequests' }, false],
  ['503 ServiceUnavailable', 503, { reason: 'ServiceUnavailable' }, false],
] as const) {
  await test(`${label} is ${gone ? 'permanent' : 'worth retrying'}`, async () => {
    const { key } = await makeKey();
    stubFetch(status, body);
    const result = await sendApns('devtoken', { title: 'T', body: 'B' }, key, {
      topic: 'my.get.teksi',
    });
    assert.equal(result.ok, false);
    assert.equal(result.gone, gone);
    assert.equal(result.reason, body.reason);
  });
}

globalThis.fetch = realFetch;
console.log(`\n${passed} passed`);
