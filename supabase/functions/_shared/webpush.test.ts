// Run: node --experimental-strip-types supabase/functions/_shared/webpush.test.ts
//
// Node 22's Web Crypto is the same API Deno gives the Edge runtime, so this
// exercises the real code rather than a port of it.

import assert from 'node:assert/strict';

import {
  b64urlToBytes,
  bytesToB64url,
  encryptPayload,
  vapidHeader,
  type Subscription,
} from './webpush.ts';

const encoder = new TextEncoder();
const decoder = new TextDecoder();
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

function concat(...parts: Uint8Array[]) {
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let at = 0;
  for (const p of parts) {
    out.set(p, at);
    at += p.length;
  }
  return out;
}

async function hmac(key: Uint8Array, data: Uint8Array) {
  const k = await crypto.subtle.importKey('raw', key, { name: 'HMAC', hash: 'SHA-256' }, false, [
    'sign',
  ]);
  return new Uint8Array(await crypto.subtle.sign('HMAC', k, data));
}

async function expand(prk: Uint8Array, info: Uint8Array, length: number) {
  return (await hmac(prk, concat(info, Uint8Array.of(1)))).subarray(0, length);
}

/// The receiving half, written independently of the sender above so the
/// round trip is a round trip rather than one function agreeing with itself
/// about its own field order.
async function decrypt(body: Uint8Array, uaPrivate: CryptoKey, auth: Uint8Array, uaPublic: Uint8Array) {
  const salt = body.subarray(0, 16);
  const idLength = body[20];
  const asPublic = body.subarray(21, 21 + idLength);
  const ciphertext = body.subarray(21 + idLength);

  const asKey = await crypto.subtle.importKey(
    'raw',
    asPublic,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  );
  const shared = new Uint8Array(
    await crypto.subtle.deriveBits({ name: 'ECDH', public: asKey }, uaPrivate, 256),
  );
  const authInfo = concat(encoder.encode('WebPush: info\0'), uaPublic, asPublic);
  const ikm = await expand(await hmac(auth, shared), authInfo, 32);
  const prk = await hmac(salt, ikm);
  const cek = await expand(prk, encoder.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await expand(prk, encoder.encode('Content-Encoding: nonce\0'), 12);

  const key = await crypto.subtle.importKey('raw', cek, 'AES-GCM', false, ['decrypt']);
  const plain = new Uint8Array(
    await crypto.subtle.decrypt({ name: 'AES-GCM', iv: nonce, tagLength: 128 }, key, ciphertext),
  );
  // Strip the 0x02 last-record delimiter.
  return decoder.decode(plain.subarray(0, plain.length - 1));
}

async function makeSubscription(): Promise<{
  subscription: Subscription;
  uaPrivate: CryptoKey;
  uaPublic: Uint8Array;
  auth: Uint8Array;
}> {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, [
    'deriveBits',
  ])) as CryptoKeyPair;
  const uaPublic = new Uint8Array(await crypto.subtle.exportKey('raw', pair.publicKey));
  const auth = crypto.getRandomValues(new Uint8Array(16));
  return {
    subscription: {
      endpoint: 'https://push.example.org/send/abc',
      p256dh: bytesToB64url(uaPublic),
      auth: bytesToB64url(auth),
    },
    uaPrivate: pair.privateKey,
    uaPublic,
    auth,
  };
}

const message = 'Your driver is two minutes away.';

console.log('webpush');

await test('a subscriber can read what was encrypted to them', async () => {
  const { subscription, uaPrivate, uaPublic, auth } = await makeSubscription();
  const body = await encryptPayload(subscription, message);
  assert.equal(await decrypt(body, uaPrivate, auth, uaPublic), message);
});

await test('the body is framed the way RFC 8188 says', async () => {
  const { subscription } = await makeSubscription();
  const body = await encryptPayload(subscription, message);
  assert.equal(new DataView(body.buffer, body.byteOffset).getUint32(16, false), 4096, 'record size');
  assert.equal(body[20], 65, 'key id length is an uncompressed P-256 point');
  assert.equal(body[21], 0x04, 'and the point says so');
  // plaintext + delimiter + 16-byte GCM tag.
  assert.equal(body.length, 21 + 65 + message.length + 1 + 16);
});

await test('tampering with one byte breaks it', async () => {
  const { subscription, uaPrivate, uaPublic, auth } = await makeSubscription();
  const body = await encryptPayload(subscription, message);
  body[body.length - 1] ^= 0x01;
  await assert.rejects(() => decrypt(body, uaPrivate, auth, uaPublic));
});

await test('the auth secret actually participates', async () => {
  // The mistake worth catching. Drop the auth secret from the derivation and
  // everything still round-trips for anyone who dropped it too, so a plain
  // round trip would not notice.
  const { subscription, uaPrivate, uaPublic } = await makeSubscription();
  const body = await encryptPayload(subscription, message);
  const wrongAuth = crypto.getRandomValues(new Uint8Array(16));
  await assert.rejects(() => decrypt(body, uaPrivate, wrongAuth, uaPublic));
});

await test('a fresh salt gives a different body each time', async () => {
  // A repeated salt with the same key pair repeats the nonce, and AES-GCM
  // with a repeated nonce gives the plaintexts away.
  const { subscription } = await makeSubscription();
  const a = await encryptPayload(subscription, message);
  const b = await encryptPayload(subscription, message);
  assert.notEqual(bytesToB64url(a), bytesToB64url(b));
  assert.notEqual(bytesToB64url(a.subarray(0, 16)), bytesToB64url(b.subarray(0, 16)));
});

console.log('vapid');

await test('the header carries a JWT the push service can verify', async () => {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const raw = new Uint8Array(await crypto.subtle.exportKey('raw', pair.publicKey));
  const jwk = await crypto.subtle.exportKey('jwk', pair.privateKey);

  const header = await vapidHeader(
    'https://push.example.org/send/abc',
    { publicKey: bytesToB64url(raw), privateKey: jwk.d! },
    'mailto:ops@example.org',
    Date.parse('2026-10-04T00:00:00Z'),
  );

  const token = header.match(/t=([^,]+)/)![1];
  const [h, c, s] = token.split('.');
  const claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(c)));
  assert.equal(JSON.parse(new TextDecoder().decode(b64urlToBytes(h))).alg, 'ES256');
  assert.equal(claims.aud, 'https://push.example.org', 'audience is the origin, not the path');
  assert.equal(claims.sub, 'mailto:ops@example.org');
  assert.ok(claims.exp - Date.parse('2026-10-04T00:00:00Z') / 1000 <= 24 * 3600, 'exp within 24h');
  assert.ok(header.includes(`k=${bytesToB64url(raw)}`), 'the key the browser subscribed with');

  // The real check: the signature verifies against the public half.
  assert.ok(
    await crypto.subtle.verify(
      { name: 'ECDSA', hash: 'SHA-256' },
      pair.publicKey,
      b64urlToBytes(s),
      encoder.encode(`${h}.${c}`),
    ),
    'signature does not verify',
  );
});

await test('a tampered claim set stops verifying', async () => {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const raw = new Uint8Array(await crypto.subtle.exportKey('raw', pair.publicKey));
  const jwk = await crypto.subtle.exportKey('jwk', pair.privateKey);
  const header = await vapidHeader(
    'https://push.example.org/send/abc',
    { publicKey: bytesToB64url(raw), privateKey: jwk.d! },
    'mailto:ops@example.org',
  );
  const [h, c, s] = header.match(/t=([^,]+)/)![1].split('.');
  const forged = bytesToB64url(encoder.encode(JSON.stringify({ aud: 'https://evil.example' })));
  assert.equal(
    await crypto.subtle.verify(
      { name: 'ECDSA', hash: 'SHA-256' },
      pair.publicKey,
      b64urlToBytes(s),
      encoder.encode(`${h}.${forged}`),
    ),
    false,
    'a forged claim set verified, so the signature is not over the claims',
  );
});

console.log(`\n${passed} passed`);
