import 'dart:io';

import 'package:flutter/services.dart';

import 'push.dart';

/// The iOS side of [registerForPush].
///
/// One channel, one method, and the native half owns the permission prompt —
/// the same division as `get.teksi/location`, for the same reason: a Dart
/// wrapper around a system prompt is only a second place for the answer to go
/// missing.
const _channel = MethodChannel('get.teksi/push');

/// This device's APNs token, or null if there isn't one to be had.
///
/// Null covers permission refused, a simulator with no push capability, and
/// APNs not answering. The caller treats all three the same way, and none of
/// them is something to tell the rider about.
Future<PushAddress?> readPushAddress() async {
  // Android returns null without crossing the channel. Route A in
  // docs/PUSH.md covers iOS and the web; MainActivity has no handler for
  // this, and invoking it anyway would mean catching MissingPluginException
  // and calling that a design.
  if (!Platform.isIOS) return null;

  final token = await _channel.invokeMethod<String>('token');
  if (token == null || token.isEmpty) return null;
  return PushAddress(platform: 'ios', token: token);
}
