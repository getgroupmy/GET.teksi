import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// latlong2 exports its own `Path`, which shadows dart:ui's.
import 'package:latlong2/latlong.dart' hide Path;

import '../models/models.dart';
import '../theme.dart';

enum PinKind { pickup, dropoff, stop, me }

class MapPin {
  const MapPin(this.id, this.coord, this.kind, {this.label});
  final String id;
  final LatLng coord;
  final PinKind kind;
  final String? label;
}

/// The map surface.
///
/// Uses flutter_map with OpenStreetMap raster tiles rather than
/// google_maps_flutter. That is a deliberate portability decision: it needs no
/// API key, renders identically on every target, and — critically — keeps the
/// app free of Google Play Services, so the same build works on Huawei
/// devices that ship without GMS.
class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.center,
    this.pins = const [],
    this.drivers = const [],
    this.route,
    this.approach,
    this.fitToken,
    this.interactive = true,
    this.bottomPadding = 0,
    this.initialZoom = 14,
  });

  final LatLng center;
  final List<MapPin> pins;
  final List<NearbyDriver> drivers;
  final List<LatLng>? route;

  /// Second polyline, drawn dashed — the driver's leg to the pickup.
  final List<LatLng>? approach;

  /// Re-fit the viewport whenever this token changes.
  final String? fitToken;
  final bool interactive;
  final double bottomPadding;
  final double initialZoom;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _controller = MapController();
  bool _ready = false;
  String? _lastFit;

  @override
  void didUpdateWidget(covariant MapView old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (widget.fitToken != null && widget.fitToken != _lastFit) {
      _lastFit = widget.fitToken;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    } else if (widget.fitToken == null && widget.center != old.center) {
      // Follow the device when nothing else is framing the view.
      _safeMove(widget.center, _controller.camera.zoom);
    }
  }

  void _safeMove(LatLng center, double zoom) {
    if (!mounted || !_ready) return;
    try {
      _controller.move(center, zoom);
    } catch (_) {
      // The controller is only usable while the map is attached; a move that
      // lands during teardown is safe to drop.
    }
  }

  void _fit() {
    if (!mounted || !_ready) return;
    final points = <LatLng>[
      ...?widget.route,
      ...?widget.approach,
      ...widget.pins.map((p) => p.coord),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _safeMove(points.first, 15);
      return;
    }
    try {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: EdgeInsets.fromLTRB(36, 96, 36, widget.bottomPadding + 36),
          maxZoom: 16,
        ),
      );
    } catch (_) {
      /* map detached mid-frame */
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final interaction = widget.interactive
        ? const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          )
        : const InteractionOptions(flags: InteractiveFlag.none);

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.initialZoom,
        interactionOptions: interaction,
        backgroundColor: c.bg,
        onMapReady: () {
          _ready = true;
          if (widget.fitToken != null) {
            _lastFit = widget.fitToken;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'my.getgroup.get_teksi',
          maxZoom: 19,
          // Tiles are unavailable offline; the pins and routes above still
          // render over the background colour rather than a broken grid.
          errorTileCallback: (_, _, _) {},
        ),
        // Dark mode wash so the light raster tiles sit in the app's key.
        if (c.mapTint.a > 0) IgnorePointer(child: Container(color: c.mapTint)),

        if (widget.approach != null && widget.approach!.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.approach!,
                strokeWidth: 4,
                color: c.textDim,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),

        if (widget.route != null && widget.route!.length > 1)
          PolylineLayer(
            polylines: [
              // Dark casing under the brand line, for contrast on any tile.
              Polyline(
                points: widget.route!,
                strokeWidth: 9,
                color: const Color(0xCC0B0D0C),
              ),
              Polyline(points: widget.route!, strokeWidth: 5, color: c.brand),
            ],
          ),

        MarkerLayer(
          markers: [
            for (final driver in widget.drivers)
              Marker(
                key: ValueKey('car_${driver.id}'),
                point: driver.coord,
                width: 34,
                height: 34,
                child: _CarMarker(bearing: driver.bearing),
              ),
            for (final pin in widget.pins)
              Marker(
                key: ValueKey('pin_${pin.id}'),
                point: pin.coord,
                width: pin.kind == PinKind.me ? 24 : 140,
                height: pin.kind == PinKind.me ? 24 : 62,
                alignment: pin.kind == PinKind.me
                    ? Alignment.center
                    : const Alignment(0, -0.45),
                child: _PinMarker(kind: pin.kind, label: pin.label),
              ),
          ],
        ),
      ],
    );
  }
}

class _CarMarker extends StatelessWidget {
  const _CarMarker({required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: bearing, end: bearing),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, _) => Transform.rotate(
        angle: value * math.pi / 180,
        child: CustomPaint(painter: _CarPainter(), size: const Size(30, 30)),
      ),
    );
  }
}

/// A simple chevron reads as a heading at any zoom, and needs no asset.
class _CarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.09)
      ..lineTo(w * 0.79, h * 0.88)
      ..lineTo(w * 0.5, h * 0.70)
      ..lineTo(w * 0.21, h * 0.88)
      ..close();

    canvas.drawShadow(path, Colors.black, 2, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFFF4F7F4));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0B0D0C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.kind, this.label});

  final PinKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (kind == PinKind.me) {
      return Container(
        decoration: BoxDecoration(
          color: c.info,
          shape: BoxShape.circle,
          border: Border.all(color: c.bg, width: 3),
          boxShadow: [
            BoxShadow(color: c.info.withValues(alpha: 0.4), blurRadius: 8),
          ],
        ),
      );
    }

    final color = switch (kind) {
      PinKind.pickup => c.brand,
      PinKind.stop => c.warn,
      _ => Colors.white,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line),
            ),
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
          ),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0B0D0C),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(width: 2, height: 9, color: color),
      ],
    );
  }
}
