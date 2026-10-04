// APNs over HTTP/2, with a token-based (.p8) key.
//
// Token-based rather than certificate-based on purpose: one key works for
// every app on the team, it does not expire annually, and it is a file rather
// than a keychain export. The JWT it signs is good for an hour and Apple
// rejects one older than that, so it is cached and re-minted rather than
// signed per notification — a thousand signatures a minute would be the
// expensive part of sending a thousand notifications.

import { bytesToB64url } from './webpush.ts';

const encoder = new TextEncoder();

export interface ApnsKey {
  /// The .p8 file's contents, PEM included.
  privateKeyPem: string;
  /// The Key ID from the Apple Developer portal.
  keyId: string;
  /// The Team ID it belongs to.
  teamId: string;
}

/// The PKCS#8 bytes out of a PEM file, whatever line endings it arrived with.
function pkcs8From(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = atob(body);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

/// The bearer token APNs wants. [now] is injectable so a test can pin it.
export async function apnsToken(key: ApnsKey, now: number = Date.now()): Promise<string> {
  const header = bytesToB64url(
    encoder.encode(JSON.stringify({ alg: 'ES256', kid: key.keyId })),
  );
  const claims = bytesToB64url(
    encoder.encode(JSON.stringify({ iss: key.teamId, iat: Math.floor(now / 1000) })),
  );

  const signingKey = await crypto.subtle.importKey(
    'pkcs8',
    pkcs8From(key.privateKeyPem) as BufferSource,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      signingKey,
      encoder.encode(`${header}.${claims}`) as BufferSource,
    ),
  );
  return `${header}.${claims}.${bytesToB64url(signature)}`;
}

export interface Alert {
  title: string;
  body: string;
  /// Collapses updates about the same ride into one notification rather than
  /// a column of them.
  collapseId?: string;
  path?: string;
}

/// The JSON APNs delivers. `aps` is Apple's; anything beside it is ours and
/// arrives in the app untouched.
export function apnsPayload(alert: Alert): string {
  return JSON.stringify({
    aps: {
      alert: { title: alert.title, body: alert.body },
      sound: 'default',
    },
    path: alert.path ?? '/',
  });
}

export interface SendResult {
  ok: boolean;
  status: number;
  /// Apple's reason string, when it gave one.
  reason?: string;
  /// True when the token is dead and the row should go.
  gone: boolean;
}

/// One notification to one device.
///
/// 410 Gone, and 400 with BadDeviceToken, both mean the token will never
/// work again. Saying so lets the caller delete the row instead of retrying
/// it forever — an app deleted from a phone otherwise leaves a token that
/// fails on every send, for good.
export async function sendApns(
  deviceToken: string,
  alert: Alert,
  key: ApnsKey,
  options: { host?: string; topic: string; bearer?: string },
): Promise<SendResult> {
  const host = options.host ?? 'https://api.push.apple.com';
  const bearer = options.bearer ?? (await apnsToken(key));

  const response = await fetch(`${host}/3/device/${deviceToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${bearer}`,
      'apns-topic': options.topic,
      'apns-push-type': 'alert',
      // 10 is "deliver now". A ride notification that arrives when the system
      // feels like it is not a ride notification.
      'apns-priority': '10',
      ...(alert.collapseId ? { 'apns-collapse-id': alert.collapseId } : {}),
      'content-type': 'application/json',
    },
    body: apnsPayload(alert),
  });

  if (response.status === 200) return { ok: true, status: 200, gone: false };

  let reason: string | undefined;
  try {
    reason = (await response.json())?.reason;
  } catch {
    // APNs answers errors with JSON; anything else is not worth a throw here.
  }
  return {
    ok: false,
    status: response.status,
    reason,
    gone: response.status === 410 || reason === 'BadDeviceToken' || reason === 'Unregistered',
  };
}
