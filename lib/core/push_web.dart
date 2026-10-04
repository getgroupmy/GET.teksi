import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'config.dart';
import 'push.dart';

/// The web side of [registerForPush].
///
/// No method channel — the browser exposes this directly. What it does need
/// is a service worker, because a push that arrives with the tab closed is
/// delivered to a worker and to nothing else.
///
/// That worker is deliberately **not** the one Flutter generates. Registering
/// a different script at the same scope replaces the registration, which
/// would quietly take the offline worker with it. So this one lives under
/// `push/` and claims only that scope. A subscription belongs to a
/// registration rather than to a scope, so a narrow one costs nothing.
const _workerPath = 'push/sw.js';
const _workerScope = 'push/';

/// This browser's push subscription, or null if there isn't one to be had.
Future<PushAddress?> readPushAddress() async {
  if (AppConfig.vapidPublicKey.isEmpty) return null;

  final serviceWorker = web.window.navigator.serviceWorker;

  // Permission first. Asking after subscribing means subscribe() throws on a
  // refusal, which is a worse way to learn the same thing.
  final permission = await web.Notification.requestPermission().toDart;
  if (permission.toDart != 'granted') return null;

  final registration = await serviceWorker
      .register(_workerPath.toJS, web.RegistrationOptions(scope: _workerScope))
      .toDart;

  final subscription = await registration.pushManager
      .subscribe(
        web.PushSubscriptionOptionsInit(
          // Required by Chrome: a push that shows the person nothing is not
          // allowed, and subscribe() rejects without this.
          userVisibleOnly: true,
          applicationServerKey: _decodeVapidKey(AppConfig.vapidPublicKey).toJS,
        ),
      )
      .toDart;

  // toJSON is the spec's own accessor and gives the keys already base64url
  // encoded. Reading them off getKey() instead would mean encoding two
  // ArrayBuffers by hand for no gain.
  final json = subscription.toJSON().dartify();
  if (json is! Map) return null;
  final endpoint = json['endpoint'];
  final keys = json['keys'];
  if (endpoint is! String || keys is! Map) return null;

  final p256dh = keys['p256dh'];
  final auth = keys['auth'];
  if (p256dh is! String || auth is! String) return null;

  return PushAddress(
    platform: 'web',
    token: endpoint,
    p256dh: p256dh,
    auth: auth,
  );
}

/// The VAPID public key, base64url with the padding left off, as the bytes
/// `applicationServerKey` wants.
///
/// Only the padding needs restoring: `base64Url` already reads the URL-safe
/// alphabet, so translating '-' and '_' by hand would be a no-op dressed up
/// as a conversion.
Uint8List _decodeVapidKey(String key) =>
    base64Url.decode(key.padRight((key.length + 3) & ~3, '='));
