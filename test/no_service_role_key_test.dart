import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No credential that bypasses row-level security may be in the repository.
///
/// config/README.md states this plainly — "The key that must never appear
/// here — or in any build — is the service role key. It bypasses row-level
/// security completely" — and until this file nothing enforced it.
///
/// The publishable key beside it is committed deliberately: it is a public
/// identifier that ships in every copy of the app, and RLS is what protects
/// the data. Its dangerous twin sits on the same page of the Supabase
/// dashboard, is the same shape, and differs by a few characters of prefix.
/// Paste that one into config/get-teksi.json instead and every build made
/// from this repository carries a key that ignores every policy in
/// supabase/migrations, for every user, silently. Nothing else here would
/// notice: the app would work, and work too well.
///
/// Scope, stated honestly. This covers files git tracks, which is what feeds
/// a build made with --dart-define-from-file. A gitignored config/local.json
/// is out of reach by construction, and so is a key typed straight onto a
/// build command line.
void main() {
  // Assembled from fragments so this file does not contain the needles it
  // hunts for. The alternative is excluding this path from the scan, and an
  // exclusion is a hole that grows.
  final secretPrefix = ['sb', 'secret', ''].join('_');
  final publishablePrefix = ['sb', 'publishable', ''].join('_');
  final serviceRole = ['service', 'role'].join('_');

  /// Every file git tracks, as text. Anything that is not UTF-8 is not a
  /// place a key can hide in a form that a build would read back.
  List<(String, String)> trackedText() {
    final listed = Process.runSync('git', ['ls-files', '-z']);
    expect(
      listed.exitCode,
      0,
      reason:
          'git ls-files failed, so this scan covered nothing: '
          '${listed.stderr}',
    );
    final paths = (listed.stdout as String)
        .split('\u0000')
        .where((p) => p.isNotEmpty);

    final out = <(String, String)>[];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        out.add((path, file.readAsStringSync()));
      } on FileSystemException {
        continue;
      } catch (_) {
        continue; // not text
      }
    }
    return out;
  }

  /// JWT-shaped tokens whose payload claims the service role. Supabase's
  /// older keys are JWTs, so a prefix check alone would miss them.
  List<String> serviceRoleJwtsIn(String body) {
    final found = <String>[];
    for (final m in RegExp(
      r'eyJ[A-Za-z0-9_-]{8,}\.(eyJ[A-Za-z0-9_-]{8,})',
    ).allMatches(body)) {
      try {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(m.group(1)!)),
        );
        if (payload.contains(serviceRole)) found.add(m.group(0)!);
      } catch (_) {
        continue; // not a decodable payload
      }
    }
    return found;
  }

  late List<(String, String)> tracked;
  setUpAll(() => tracked = trackedText());

  test('the scan actually reads the repository', () {
    // Without this, a broken `git ls-files` or a wrong working directory
    // reads as a repository with no secrets in it.
    expect(
      tracked.length,
      greaterThan(50),
      reason:
          'only ${tracked.length} tracked text files were read, which is '
          'too few to be this repository — the scan below is not scanning it',
    );
    expect(
      tracked.map((f) => f.$1),
      contains('config/get-teksi.json'),
      reason: 'the one file the key actually lives in was not scanned',
    );
  });

  test('no file carries a secret-prefixed key', () {
    final hits = [
      for (final (path, body) in tracked)
        if (body.contains(secretPrefix)) path,
    ];
    expect(
      hits,
      isEmpty,
      reason:
          'these tracked files contain a Supabase secret key prefix. A '
          'secret key bypasses row-level security entirely, and anything in '
          'this repository reaches every build made from it:\n'
          '${hits.join('\n')}',
    );
  });

  test('no file carries a service-role JWT', () {
    final hits = [
      for (final (path, body) in tracked)
        if (serviceRoleJwtsIn(body).isNotEmpty) path,
    ];
    expect(
      hits,
      isEmpty,
      reason:
          'these tracked files contain a JWT whose payload claims the '
          'service role, which bypasses row-level security entirely:\n'
          '${hits.join('\n')}',
    );
  });

  test('every configured key is a publishable key', () {
    final configs = Directory('config')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));

    var checked = 0;
    for (final file in configs) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final key = json['SUPABASE_PUBLISHABLE_KEY'] as String?;
      if (key == null || key.isEmpty) continue;
      checked++;
      expect(
        key.startsWith(publishablePrefix),
        isTrue,
        reason:
            '${file.path} sets SUPABASE_PUBLISHABLE_KEY to something that '
            'is not a publishable key. The two sit together in the Supabase '
            'dashboard and look alike; only one of them is safe to ship.',
      );
    }
    expect(
      checked,
      greaterThan(0),
      reason: 'no config/*.json declared a key, so this test asserted nothing',
    );
  });

  group('the scan itself', () {
    // Each detector, pointed at something it must catch. A matcher that has
    // quietly stopped matching is indistinguishable from a clean repository.
    test('catches a secret-prefixed key', () {
      expect('"KEY": "${secretPrefix}abc123"'.contains(secretPrefix), isTrue);
    });

    test('catches a service-role JWT', () {
      String seg(Map<String, dynamic> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final jwt =
          '${seg({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${seg({'iss': 'supabase', 'role': serviceRole})}.c2ln';
      expect(
        serviceRoleJwtsIn('const k = "$jwt";'),
        isNotEmpty,
        reason:
            'a synthetic service-role JWT was not detected, so the scan '
            'above is not detecting anything',
      );
    });

    test('does not flag an anon JWT', () {
      String seg(Map<String, dynamic> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final jwt =
          '${seg({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${seg({'iss': 'supabase', 'role': 'anon'})}.c2ln';
      expect(serviceRoleJwtsIn('const k = "$jwt";'), isEmpty);
    });
  });
}
