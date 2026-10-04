// Sends one notification to every device a person has registered.
//
// Split from index.ts so it can be tested. index.ts calls Deno.serve at
// import time and names Deno.env, neither of which exists under Node — so
// everything that decides who may send, what is sent and which tokens are
// thrown away lived in a file no test could import. The environment and
// fetch arrive as parameters for the same reason.
//
// Called from the database, not from the app. The app already knows what it
// is doing; the interesting notifications are the ones that happen to you
// while you are not looking — a bid arriving, an offer accepted, a driver
// at the kerb — and those are row changes.
//
// This can send a notification to anybody, so the first question is who may
// call it, not what it does. Supabase verifies the JWT before this runs,
// which proves the caller holds *a* valid key; it does not prove they hold
// the service role one. A signed-in passenger's own token passes that check
// too. So the bearer is compared against the service role key here as well,
// and nothing else is accepted.

import { bearerOf, secretsMatch } from '../_shared/auth.ts';
import { sendApns, type Alert, type ApnsKey } from '../_shared/apns.ts';
import { encryptPayload, vapidHeader, type Subscription } from '../_shared/webpush.ts';

interface PushRow {
  id: string;
  platform: 'ios' | 'web';
  token: string;
  p256dh: string | null;
  auth: string | null;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

/// The whole request, with its two impurities handed in.
///
/// [env] is Deno.env.get in production. [fetchImpl] is fetch. Injected rather
/// than reached for, so the tests drive the real logic instead of a copy of
/// it.
export async function handlePush(
  request: Request,
  env: (key: string) => string | undefined,
  fetchImpl: typeof fetch,
): Promise<Response> {
  const fetch = fetchImpl;

  if (request.method !== 'POST') return json({ error: 'POST only' }, 405);

  const serviceRoleKey = env('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!secretsMatch(bearerOf(request.headers.get('authorization')), serviceRoleKey)) {
    // Deliberately not "wrong key": an endpoint that distinguishes a wrong
    // key from a missing one is an endpoint that helps you guess.
    return json({ error: 'not authorised' }, 401);
  }

  const { user_id: userId, title, body, path, collapse_id: collapseId } = await request
    .json()
    .catch(() => ({}));
  if (!userId || !title || !body) {
    return json({ error: 'user_id, title and body are required' }, 400);
  }

  const supabaseUrl = env('SUPABASE_URL') ?? '';
  const headers = {
    apikey: serviceRoleKey,
    authorization: `Bearer ${serviceRoleKey}`,
    'content-type': 'application/json',
  };

  const response = await fetch(
    `${supabaseUrl}/rest/v1/push_tokens?user_id=eq.${encodeURIComponent(userId)}` +
      `&select=id,platform,token,p256dh,auth`,
    { headers },
  );
  if (!response.ok) return json({ error: 'could not read push_tokens' }, 502);
  const rows: PushRow[] = await response.json();

  const alert: Alert = { title, body, path, collapseId };
  const apnsKey: ApnsKey = {
    privateKeyPem: env('APNS_PRIVATE_KEY') ?? '',
    keyId: env('APNS_KEY_ID') ?? '',
    teamId: env('APNS_TEAM_ID') ?? '',
  };
  const apnsTopic = env('APNS_TOPIC') ?? '';
  const apnsHost = env('APNS_HOST') ?? undefined;
  const vapid = {
    publicKey: env('VAPID_PUBLIC_KEY') ?? '',
    privateKey: env('VAPID_PRIVATE_KEY') ?? '',
  };
  const vapidSubject = env('VAPID_SUBJECT') ?? 'mailto:ops@example.org';

  // Tokens that will never work again. An app deleted from a phone leaves a
  // row that fails on every send, for good, unless it is removed.
  const dead: string[] = [];
  let sent = 0;

  await Promise.all(
    rows.map(async (row) => {
      try {
        if (row.platform === 'ios') {
          if (!apnsKey.privateKeyPem || !apnsTopic) return;
          const result = await sendApns(row.token, alert, apnsKey, {
            topic: apnsTopic,
            host: apnsHost,
            fetchImpl: fetch,
          });
          if (result.ok) sent++;
          else if (result.gone) dead.push(row.id);
          return;
        }

        if (!vapid.privateKey || !row.p256dh || !row.auth) return;
        const subscription: Subscription = {
          endpoint: row.token,
          p256dh: row.p256dh,
          auth: row.auth,
        };
        const encrypted = await encryptPayload(
          subscription,
          JSON.stringify({ title, body, path, tag: collapseId }),
        );
        const push = await fetch(row.token, {
          method: 'POST',
          headers: {
            authorization: await vapidHeader(row.token, vapid, vapidSubject),
            'content-encoding': 'aes128gcm',
            'content-type': 'application/octet-stream',
            ttl: '2419200',
          },
          body: encrypted,
        });
        if (push.ok) sent++;
        // 404 and 410 are the push service saying this subscription is over.
        else if (push.status === 404 || push.status === 410) dead.push(row.id);
      } catch {
        // One device failing is not the others' problem, and not the
        // caller's either — a ride does not stop because a notification
        // could not be delivered.
      }
    }),
  );

  if (dead.length > 0) {
    await fetch(
      `${supabaseUrl}/rest/v1/push_tokens?id=in.(${dead.map(encodeURIComponent).join(',')})`,
      { method: 'DELETE', headers },
    ).catch(() => {});
  }

  return json({ devices: rows.length, sent, removed: dead.length });
}
