import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No credential that must stay secret may be in the repository.
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

  /// The sending keys, added with the push Edge Function.
  ///
  /// Different stakes from the service role key and the same rule. An APNs
  /// .p8 lets anyone send notifications that are, to the phone, from this
  /// app; a VAPID private key does the same for the browser. Neither is a
  /// data breach, which is exactly why they are easy to be careless with.
  group('push sending keys', () {
    // Assembled from fragments, like the rest, so this file is not its own
    // first finding.
    final pemHeader = '-----${['BEGIN', 'PRIVATE', 'KEY'].join(' ')}-----';
    final pemFooter = '-----${['END', 'PRIVATE', 'KEY'].join(' ')}-----';

    /// A whole PEM block, not a mention of one.
    ///
    /// The first version matched the header alone and flagged three files:
    /// the .p8 parser, which carries the header as a literal because
    /// stripping it is its job; the test that wraps a generated throwaway
    /// key in a PEM; and this file's own self-check. None of them is a key.
    /// A scan that flags the parser for the thing it parses is a scan
    /// somebody eventually switches off, so this looks for what a key
    /// actually is — header, a real base64 body, footer. A P-256 .p8 is
    /// around 200 characters of base64; 100 is well below any real key and
    /// well above any mention.
    final pemBlock = RegExp(
      '$pemHeader[\\s]*[A-Za-z0-9+/=\\s]{100,}$pemFooter',
    );

    test('no PEM private key is committed', () {
      final hits = [
        for (final (path, body) in tracked)
          if (pemBlock.hasMatch(body)) path,
      ];
      expect(
        hits,
        isEmpty,
        reason:
            'these tracked files contain a PEM private key block. An APNs '
            '.p8 is one of these, and it signs for the whole developer '
            'team:\n${hits.join('\n')}',
      );
    });

    test('no .p8 file is tracked at all', () {
      final hits = [
        for (final (path, _) in tracked)
          if (path.endsWith('.p8')) path,
      ];
      expect(
        hits,
        isEmpty,
        reason: 'an APNs key belongs in a secret, not here',
      );
    });

    test('no secret is assigned a value in a tracked file', () {
      // The shape a leak actually takes: not a loose key, but a config file
      // or a workflow with the value filled in beside the name.
      const names = [
        'VAPID_PRIVATE_KEY',
        'APNS_PRIVATE_KEY',
        'SUPABASE_SERVICE_ROLE_KEY',
      ];
      final hits = <String>[];
      for (final (path, body) in tracked) {
        for (final name in names) {
          // name, then : or =, then something that is not obviously a
          // placeholder or a reference to a secret store.
          final assigned = RegExp('$name"?\\s*[:=]\\s*"?([^\\s",}\$]{8,})')
              .firstMatch(body);
          if (assigned != null) hits.add('$path: $name');
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            'these tracked files appear to assign a sending secret a '
            'literal value:\n${hits.join('\n')}',
      );
    });

    test('the scan would notice each of those', () {
      // Each detector against something it must catch, because three
      // matchers that have quietly stopped matching look exactly like a
      // clean repository.
      // A whole block, assembled here rather than written out, so this file
      // does not become its own first finding.
      final body = List.filled(
        4,
        'MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIB',
      ).join();
      expect(pemBlock.hasMatch('$pemHeader\n$body\n$pemFooter'), isTrue);
      // And that naming the format is not the same as containing a key.
      expect(pemBlock.hasMatch('strip the $pemHeader prefix'), isFalse);

      expect('a/key.p8'.endsWith('.p8'), isTrue);

      final vapid = ['VAPID', 'PRIVATE', 'KEY'].join('_');
      final assignment = RegExp('$vapid"?\\s*[:=]\\s*"?([^\\s",}\$]{8,})');
      expect(assignment.hasMatch('"$vapid": "abcdefghijklmnop"'), isTrue);
      // A reference to a secret store is not a value.
      expect(assignment.hasMatch('$vapid: \${{ secrets.$vapid }}'), isFalse);
    });
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
