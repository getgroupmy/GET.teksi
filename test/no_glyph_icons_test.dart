import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No symbol character standing in for an icon.
///
/// EarningsScreen rendered a rating as `' · ★ 5'`. U+2605 is only on screen
/// if the platform font happens to carry it; on the web build it does not,
/// and the star came out as an empty box next to the number. The app bundles
/// no fonts, so every such character is a bet on whoever's device it is.
///
/// Icons.star_rounded has none of that problem: the Material icon font ships
/// with the app. The rest of the app already uses it, which is why this was
/// one line rather than a pattern.
///
/// Deliberately narrow. Prose punctuation is fine and widespread — em dashes,
/// curly quotes, the middle dot used as a separator, and the whole of Malay.
/// What is not fine is a character from the blocks people reach into when
/// they want a picture.
void main() {
  /// The blocks a glyph-as-icon comes from.
  const ranges = <(int, int, String)>[
    (0x2190, 0x21FF, 'arrows'),
    (0x2300, 0x23FF, 'technical symbols'),
    (0x25A0, 0x25FF, 'geometric shapes'),
    (0x2600, 0x27BF, 'symbols and dingbats'),
    (0x2B00, 0x2BFF, 'arrows and shapes'),
    (0x1F300, 0x1FAFF, 'emoji'),
  ];

  String? blockOf(int rune) {
    for (final (low, high, name) in ranges) {
      if (rune >= low && rune <= high) return name;
    }
    return null;
  }

  /// Dart source with comments stripped, so a `→` in a doc comment is not a
  /// finding. Two of them exist and both are prose about a state machine.
  String code(String source) => source
      .split('\n')
      .map((line) {
        final at = line.indexOf('//');
        return at == -1 ? line : line.substring(0, at);
      })
      .join('\n');

  late List<(String, String)> sources;

  setUpAll(() {
    sources = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            // Generated from the .arb files, and translations are text.
            !entity.path.contains('/l10n/'))
          (entity.path, code(entity.readAsStringSync())),
    ];
  });

  test('the scan reads the app', () {
    // A directory walk that found nothing reads exactly like a clean app.
    expect(sources.length, greaterThan(30));
    expect(sources.map((f) => f.$1), contains('lib/router.dart'));
  });

  test('no screen draws a picture with a character', () {
    final hits = <String>[];
    for (final (path, source) in sources) {
      for (final rune in source.runes) {
        final block = blockOf(rune);
        if (block == null) continue;
        hits.add(
          '$path: U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          '($block)',
        );
        break;
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'these files use a symbol character where an icon belongs. The app '
          'bundles no fonts, so whether it draws anything is a property of '
          "the reader's device:\n${hits.join('\n')}",
    );
  });

  test('the scan can tell a picture from punctuation', () {
    // Without this, a wrong range would read as an app with no glyph icons.
    expect(blockOf('★'.runes.first), 'symbols and dingbats');
    expect(blockOf('→'.runes.first), 'arrows');
    expect(blockOf('●'.runes.first), 'geometric shapes');
    // And the punctuation the app genuinely uses, which must not be flagged.
    for (final ok in ['—', '·', '’', '“', '…', 'é', 'ü']) {
      expect(blockOf(ok.runes.first), isNull, reason: '$ok is punctuation');
    }
  });
}
