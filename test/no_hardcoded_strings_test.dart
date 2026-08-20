import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The four literals this test was written for slipped through because a
/// conversion script failed silently partway down its list — the screens still
/// compiled, the analyzer was clean, and the ARB files were complete, so
/// nothing anywhere said the Skip button was still English. Only reading the
/// source found them.
///
/// So read the source here. This walks every screen and widget and fails on a
/// user-visible string literal sitting where a translated one belongs: the
/// arguments to Text() and the named slots that render text.
///
/// It is deliberately narrow. It cannot see a literal passed through a
/// variable, and it says nothing about the quality of the Malay. What it does
/// is make "someone added a screen and forgot" a failing test rather than
/// something a reader has to notice.

/// Literals that are correctly not translated: input format examples, and
/// anything that is the same word in both languages.
const _allowed = <String>{
  '+60 12-345 6789', // what a phone number looks like
  '12 345 6789',
  'e.g. Aiman Rahman', // what a name looks like
  'you@example.com',
  'Perodua', // what a car make looks like
  'Myvi',
  'WXY 1234', // what a plate looks like
  '2022',
  'GET.teksi', // the brand
};

/// Where a rendered string can appear.
const _slots = [
  'hintText',
  'hint',
  'tooltip',
  'title',
  'subtitle',
  'body',
  'label',
  'semanticLabel',
];

final _inSlot = RegExp(
  '(?:${_slots.join('|')}):\\s*(?:const\\s+)?(?:Text\\(\\s*)?'
  "(['\"])([^'\"\\\$]{2,})\\1",
);

/// A bare Text('…'). The leading guard keeps it off `RichText(` and the like.
final _inText = RegExp("(?:^|[^\\w.])Text\\(\\s*(['\"])([^'\"\\\$]{2,})\\1");

void main() {
  test('no screen renders a hardcoded string', () {
    // A set: the slot pattern and the bare-Text pattern both match a line
    // like `title: Text('Menu')`, and reporting it twice helps nobody.
    final offenders = <String>{};
    final sources = [
      ...Directory('lib/screens').listSync(recursive: true),
      ...Directory('lib/widgets').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'));

    expect(sources, isNotEmpty, reason: 'found no sources to scan');

    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in [
          ..._inSlot.allMatches(lines[i]),
          ..._inText.allMatches(lines[i]),
        ]) {
          final literal = match.group(2)!;
          // Lower-case fragments are almost always identifiers or asset paths
          // rather than prose; prose is what this is looking for.
          if (!RegExp('^[A-Z]').hasMatch(literal)) continue;
          if (_allowed.contains(literal)) continue;
          offenders.add('${file.path}:${i + 1}: $literal');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these render as English in every locale — move them to the ARB '
          'files, or add them to _allowed if they genuinely should not be '
          'translated:\n${offenders.join('\n')}',
    );
  });
}
