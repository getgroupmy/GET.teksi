import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/push.dart';

void main() {
  const iosAddress = PushAddress(platform: 'ios', token: 'abc123');
  const webAddress = PushAddress(
    platform: 'web',
    token: 'https://push.example/x',
    p256dh: 'key',
    auth: 'secret',
  );

  group('the shape the server will accept', () {
    // Web Push is encrypted end to end, so an endpoint without the keys to
    // encrypt to is not an address — it is a row the database refuses and a
    // device that silently never hears anything.
    test('a web subscription needs both of its keys', () {
      expect(webAddress.isDeliverable, isTrue);
      expect(
        const PushAddress(
          platform: 'web',
          token: 'https://push.example/x',
          p256dh: 'key',
        ).isDeliverable,
        isFalse,
        reason: 'a web address with no auth key cannot be encrypted to',
      );
      expect(
        const PushAddress(
          platform: 'web',
          token: 'https://push.example/x',
          auth: 'secret',
        ).isDeliverable,
        isFalse,
      );
    });

    test('an iOS token carries no keys', () {
      expect(iosAddress.isDeliverable, isTrue);
      expect(
        const PushAddress(
          platform: 'ios',
          token: 'abc123',
          p256dh: 'key',
          auth: 'secret',
        ).isDeliverable,
        isFalse,
        reason:
            'keys on an iOS row mean something filled in the wrong shape, '
            'and the database says so too',
      );
    });
  });

  /// The client builds a row; the database declares the columns. Those are
  /// two statements of the same fact, and nothing made them agree — a renamed
  /// column would leave this passing and every upsert failing on a device
  /// nobody is watching. So read the migration.
  group('agrees with the migration', () {
    final migration = File('supabase/migrations/20260822160000_push_tokens.sql')
        .readAsStringSync();

    /// Column names from `create table public.push_tokens ( ... )`.
    Set<String> declaredColumns() {
      final body = RegExp(
        r'create table public\.push_tokens\s*\((.*?)\n\);',
        dotAll: true,
      ).firstMatch(migration)?.group(1);
      expect(
        body,
        isNotNull,
        reason:
            'could not find the push_tokens table in the migration, so this '
            'check has stopped checking and needs rewriting',
      );
      // [a-z0-9_] and not [a-z_]: the first version of this missed p256dh
      // entirely, because of the digits, and reported the client writing a
      // column the table did not declare. It failed loudly, which is the
      // only reason it is right now.
      //
      // `constraint` and `unique` sit at the same indent and are not
      // columns; leaving them in would only loosen a `contains` check, but a
      // set that claims to be the columns should be the columns.
      return {
        for (final line in body!.split('\n'))
          if (RegExp(r'^\s{2}[a-z_][a-z0-9_]*\s').hasMatch(line))
            if (!const {
              'constraint',
              'unique',
              'primary',
              'foreign',
            }.contains(line.trim().split(RegExp(r'\s')).first))
              line.trim().split(RegExp(r'\s')).first,
      };
    }

    test('every column the client writes exists in the table', () {
      final declared = declaredColumns();
      expect(
        declared,
        contains('user_id'),
        reason: 'the column scan found nothing recognisable',
      );
      for (final column in webAddress.toRow('user-1').keys) {
        expect(
          declared,
          contains(column),
          reason:
              'the client upserts "$column", which public.push_tokens does '
              'not declare. The upsert would fail on the device rather than '
              'here.',
        );
      }
    });

    test('the scan would notice a column that is not there', () {
      // Without this, a regex that quietly matched nothing would read as a
      // client and a schema in perfect agreement.
      expect(declaredColumns(), isNot(contains('not_a_real_column')));
      expect(declaredColumns().length, greaterThan(5));
    });
  });

  test('the row is keyed the way the upsert expects', () {
    final row = iosAddress.toRow('user-1');
    expect(row['user_id'], 'user-1');
    expect(row['platform'], 'ios');
    expect(row['token'], 'abc123');
    expect(row['p256dh'], isNull);
    expect(row['auth'], isNull);
  });
}
