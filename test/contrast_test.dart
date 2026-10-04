import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_teksi/theme.dart';

/// WCAG relative luminance and contrast, so the palette can't silently
/// regress. Foreground text roles must clear 4.5:1 against every surface the
/// app actually paints them on; non-text indicators must clear 3:1.

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {'dark': AppColors.dark, 'light': AppColors.light};

  for (final entry in themes.entries) {
    final name = entry.key;
    final p = entry.value;
    final surfaces = <String, Color>{
      'bg': p.bg,
      'surface': p.surface,
      'surface2': p.surface2,
      'surface3': p.surface3,
    };

    group('$name theme', () {
      final textRoles = <String, Color>{
        'text': p.text,
        'textDim': p.textDim,
        'textMute': p.textMute,
        'danger': p.danger,
        'warn': p.warn,
        'ok': p.ok,
        'info': p.info,
        'accent': p.accent,
      };

      textRoles.forEach((roleName, color) {
        test('$roleName clears 4.5:1 on every surface', () {
          surfaces.forEach((surfaceName, surface) {
            final ratio = contrast(color, surface);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason:
                  '$name/$roleName on $surfaceName is '
                  '${ratio.toStringAsFixed(2)}:1, below the 4.5:1 text minimum',
            );
          });
        });
      });

      test('primary button label clears 4.5:1 on the brand fill', () {
        expect(contrast(p.brandInk, p.brand), greaterThanOrEqualTo(4.5));
      });

      test('chat bubble text clears 4.5:1 on the brand fill', () {
        // Outgoing messages paint brandInk on brand.
        expect(contrast(p.brandInk, p.brand), greaterThanOrEqualTo(4.5));
      });

      test('accent clears 3:1 as a focus ring and state indicator', () {
        surfaces.forEach((surfaceName, surface) {
          final ratio = contrast(p.accent, surface);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                '$name/accent on $surfaceName is '
                '${ratio.toStringAsFixed(2)}:1, below the 3:1 non-text minimum',
          );
        });
      });
    });
  }

  test('accent and brand agree in dark mode and diverge in light', () {
    // Dark mode can use the vivid lime directly; light mode cannot.
    expect(AppColors.dark.accent, AppColors.dark.brand);
    expect(AppColors.light.accent, isNot(AppColors.light.brand));
  });

  test('both themes are actually distinct', () {
    expect(AppColors.dark.bg, isNot(AppColors.light.bg));
    expect(AppColors.dark.text, isNot(AppColors.light.text));
  });
}
