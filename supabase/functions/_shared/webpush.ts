// Web Push payload encryption (RFC 8291) and VAPID (RFC 8292).
//
// Hand-rolled over Web Crypto rather than pulled from npm, because the
// standard library for this is Node-shaped — node:crypto, node:https — and
// this runs on Deno. Web Crypto is identical in both, which is also what
// lets the tests run under Node here.
//
// Honest limits on what the tests prove, stated here rather than discovered:
// RFC 8291 publishes a worked test vector, and this is NOT checked against
// it, because rfc-editor.org and datatracker.ietf.org are both blocked by
// this environment's egress policy and a crypto constant written from memory
// is worse than none. What is checked is a round trip, that tampering breaks
// the tag, and that the auth secret genuinely participates — that last one
// being the mistake most likely to go unnoticed, since ignoring it still
// produces something that decrypts for whoever made the same mistake.
// A real send to a live subscription remains the only complete proof.

const encoder = new TextEncoder();

export function b64urlToBytes(value: string): Uint8Array {
  const padded = value.padEnd(value.length + ((4 - (value.length % 4)) % 4), '=');
  const binary = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

export function bytesToB64url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function concat(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((n, p) => n + p.length, 0);
  const out = new Uint8Array(total);
  let at = 0;
  for (const part of parts) {
    out.set(part, at);
    at += part.length;
  }
  return out;
}

/// HKDF in its two halves.
///
/// Web Crypto's HKDF does extract-and-expand in one call, and RFC 8291 needs
/// them separately: the auth secret is the salt of the first extract, and the
/// result of that becomes the input keying material of the second. Hence HMAC
/// by hand. Every output here is 32 bytes or fewer, so expand is a single
/// block and the counter is always 0x01.
async function hmac(key: Uint8Array, data: Uint8Array): Promise<Uint8Array> {
  const imported = await crypto.subtle.importKey(
    'raw',
    key as BufferSource,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return new Uint8Array(await crypto.subtle.sign('HMAC', imported, data as BufferSource));
}

const extract = hmac;

async function expand(prk: Uint8Array, info: Uint8Array, length: number) {
  if (length > 32) throw new Error('expand: one block only');
  const block = await hmac(prk, concat(info, Uint8Array.of(1)));
  return block.subarray(0, length);
}

/// A P-256 key pair as Web Crypto wants it, from the raw bytes everything
/// else in Web Push speaks: a 65-byte uncompressed point and a 32-byte
/// scalar.
function jwkFrom(publicKey: Uint8Array, privateKey: Uint8Array): JsonWebKey {
  if (publicKey.length !== 65 || publicKey[0] !== 0x04) {
    throw new Error('expected a 65-byte uncompressed P-256 point');
  }
  return {
    kty: 'EC',
    crv: 'P-256',
    x: bytesToB64url(publicKey.subarray(1, 33)),
    y: bytesToB64url(publicKey.subarray(33, 65)),
    d: bytesToB64url(privateKey),
    ext: true,
  };
}

async function importPrivate(publicKey: Uint8Array, privateKey: Uint8Array, usage: KeyUsage[]) {
  const algorithm = usage.includes('sign')
    ? { name: 'ECDSA', namedCurve: 'P-256' }
    : { name: 'ECDH', namedCurve: 'P-256' };
  return crypto.subtle.importKey('jwk', jwkFrom(publicKey, privateKey), algorithm, false, usage);
}

export interface Subscription {
  endpoint: string;
  p256dh: string;
  auth: string;
}

export interface ServerKeys {
  publicKey: string;
  privateKey: string;
}

/// The encrypted body of a Web Push request, framed as RFC 8188 aes128gcm.
///
/// [salt] and [ephemeral] exist so a test can pin them. In production both
/// are random per message, which is not optional: reusing a salt with the
/// same key pair reuses the nonce, and AES-GCM with a repeated nonce leaks
/// the plaintexts outright.
export async function encryptPayload(
  subscription: Subscription,
  payload: string,
  options: { salt?: Uint8Array; ephemeral?: CryptoKeyPair } = {},
): Promise<Uint8Array> {
  const uaPublic = b64urlToBytes(subscription.p256dh);
  const authSecret = b64urlToBytes(subscription.auth);
  const salt = options.salt ?? crypto.getRandomValues(new Uint8Array(16));

  const ephemeral =
    options.ephemeral ??
    ((await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, [
      'deriveBits',
    ])) as CryptoKeyPair);
  const asPublic = new Uint8Array(await crypto.subtle.exportKey('raw', ephemeral.publicKey));

  const uaKey = await crypto.subtle.importKey(
    'raw',
    uaPublic as BufferSource,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  );
  const shared = new Uint8Array(
    await crypto.subtle.deriveBits({ name: 'ECDH', public: uaKey }, ephemeral.privateKey, 256),
  );

  // "WebPush: info" then both public keys, receiver first. The order is not
  // arbitrary — swap them and both sides still agree only if both are wrong.
  const authInfo = concat(
    encoder.encode('WebPush: info\0'),
    uaPublic,
    asPublic,
  );
  const ikm = await expand(await extract(authSecret, shared), authInfo, 32);
  const prk = await extract(salt, ikm);

  const cek = await expand(prk, encoder.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await expand(prk, encoder.encode('Content-Encoding: nonce\0'), 12);

  const key = await crypto.subtle.importKey('raw', cek as BufferSource, 'AES-GCM', false, [
    'encrypt',
  ]);
  // 0x02 is the delimiter marking the last record. 0x01 would say another
  // follows, and the browser would wait for one that never comes.
  const padded = concat(encoder.encode(payload), Uint8Array.of(2));
  const ciphertext = new Uint8Array(
    await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: nonce as BufferSource, tagLength: 128 },
      key,
      padded as BufferSource,
    ),
  );

  // salt | record size | key id length | key id | ciphertext
  const recordSize = new Uint8Array(4);
  new DataView(recordSize.buffer).setUint32(0, 4096, false);
  return concat(salt, recordSize, Uint8Array.of(asPublic.length), asPublic, ciphertext);
}

/// The VAPID Authorization header (RFC 8292): a JWT the push service checks
/// against the public key the browser subscribed with.
export async function vapidHeader(
  endpoint: string,
  keys: ServerKeys,
  subject: string,
  now: number = Date.now(),
): Promise<string> {
  const audience = new URL(endpoint).origin;
  const header = bytesToB64url(encoder.encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const claims = bytesToB64url(
    encoder.encode(
      JSON.stringify({
        aud: audience,
        // Twelve hours. The spec caps it at 24 and push services reject
        // anything longer outright.
        exp: Math.floor(now / 1000) + 12 * 60 * 60,
        sub: subject,
      }),
    ),
  );
  const signingInput = encoder.encode(`${header}.${claims}`);

  const key = await importPrivate(
    b64urlToBytes(keys.publicKey),
    b64urlToBytes(keys.privateKey),
    ['sign'],
  );
  // Web Crypto emits the raw r|s pair ECDSA JWS wants, not the DER sequence
  // that most command-line tooling produces. No conversion needed, and one
  // would break it.
  const signature = new Uint8Array(
    await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, signingInput as BufferSource),
  );

  return `vapid t=${header}.${claims}.${bytesToB64url(signature)}, k=${keys.publicKey}`;
}
