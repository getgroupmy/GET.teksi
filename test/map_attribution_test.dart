import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/core/config.dart';
import 'package:get_teksi/theme.dart';
import 'package:get_teksi/widgets/map_view.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap data is under the Open Database Licence, and the credit is a
/// term of it rather than a courtesy. It lives inside MapView so no screen can
/// forget to add it — and this is the test that says so, because the way a
/// licence term gets dropped is not malice, it is a refactor.
///
/// The other half is placement. Every screen that shows the map also puts a
/// sheet over the bottom of it, so a credit pinned to the bottom of the widget
/// is a credit behind an opaque panel. Attribution nobody can see is not
/// attribution.

const _kl = LatLng(3.1478, 101.6953);

void main() {
  Future<void> pumpMap(WidgetTester tester, {double bottomPadding = 0}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(dark: true),
          home: Scaffold(
            body: MapView(center: _kl, bottomPadding: bottomPadding),
          ),
        ),
      );

  testWidgets('the map credits OpenStreetMap', (tester) async {
    await pumpMap(tester);
    await tester.pump();

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });

  testWidgets('the credit clears whatever sheet is over the map', (
    tester,
  ) async {
    // The sheet height the screen passes for its camera padding is the same
    // number the credit has to sit above.
    const sheet = 300.0;
    await pumpMap(tester, bottomPadding: sheet);
    await tester.pump();

    final credit = tester.getRect(find.textContaining('OpenStreetMap'));
    final map = tester.getRect(find.byType(MapView));

    expect(
      credit.bottom,
      lessThan(map.bottom - sheet),
      reason: 'the credit is underneath the sheet, where nobody can read it',
    );
  });

  test('the tile source is OpenStreetMap unless told otherwise', () {
    // The default is the OSM Foundation's own server: it is what makes the
    // demo draw a map with nothing provisioned, and it is explicitly not for
    // production traffic. Configurable, so a real deployment changes a URL
    // rather than a widget.
    expect(AppConfig.tileUrl, contains('openstreetmap.org'));
    expect(AppConfig.tileUrl, contains('{z}/{x}/{y}'));
  });
}
