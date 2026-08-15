import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/geo.dart';
import '../../data/places.dart';
import '../../models/models.dart';
import '../../state/draft.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final _pickupController = TextEditingController();
  final _stopController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _pickupFocus = FocusNode();
  final _stopFocus = FocusNode();
  final _dropoffFocus = FocusNode();

  String _query = '';

  /// The stop field only exists once the passenger asks for one.
  bool _wantStop = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<DraftStore>();
    _wantStop = draft.stop != null;
    _pickupController.text = draft.pickup?.name ?? '';
    _dropoffController.text = draft.dropoff?.name ?? '';
    _stopController.text = draft.stop?.name ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusActiveField());
  }

  void _focusActiveField() {
    if (!mounted) return;
    final field = context.read<DraftStore>().editing;
    switch (field) {
      case DraftField.pickup:
        _pickupFocus.requestFocus();
      case DraftField.stop:
        _stopFocus.requestFocus();
      case DraftField.dropoff:
        _dropoffFocus.requestFocus();
    }
    final controller = _controllerFor(field);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _stopController.dispose();
    _dropoffController.dispose();
    _pickupFocus.dispose();
    _stopFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(DraftField field) => switch (field) {
    DraftField.pickup => _pickupController,
    DraftField.stop => _stopController,
    DraftField.dropoff => _dropoffController,
  };

  void _choose(Place place) {
    final draft = context.read<DraftStore>();
    final field = draft.editing;

    switch (field) {
      case DraftField.pickup:
        draft.setPickup(place);
      case DraftField.stop:
        draft.setStop(place);
      case DraftField.dropoff:
        draft.setDropoff(place);
    }
    _controllerFor(field).text = place.name;

    // Once both ends are known, go straight to setting the fare.
    if (draft.pickup != null && draft.dropoff != null) {
      draft.setStep(DraftStep.price);
      context.pop();
      return;
    }
    setState(() {
      _query = '';
      draft.setEditing(
        draft.dropoff == null ? DraftField.dropoff : DraftField.pickup,
      );
    });
    _focusActiveField();
  }

  IconData _iconFor(Place place) => switch (place.category) {
    PlaceCategory.airport => Icons.flight_rounded,
    PlaceCategory.transit => Icons.directions_transit_rounded,
    PlaceCategory.mall => Icons.storefront_rounded,
    PlaceCategory.recent => Icons.history_rounded,
    PlaceCategory.saved => Icons.star_rounded,
    _ => Icons.place_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final draft = context.watch<DraftStore>();
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;

    final pool = draft.service == ServiceType.intercity
        ? intercityPlaces
        : allPlaces;

    final recents = <Place>[];
    final seen = <String>{};
    for (final ride in rides.historyFor(user.id, Role.passenger)) {
      for (final place in [ride.dropoff, ride.pickup]) {
        if (!seen.add(place.name)) continue;
        recents.add(place.copyWith(category: PlaceCategory.recent));
      }
      if (recents.length >= 6) break;
    }

    final base = draft.service == ServiceType.intercity
        ? intercityPlaces
        : places;
    final suggestions = [...base]
      ..sort(
        (a, b) => haversineKm(
          a.coord,
          session.myLocation,
        ).compareTo(haversineKm(b.coord, session.myLocation)),
      );

    final results = _query.trim().isNotEmpty
        ? fuzzySearch(_query, pool: pool)
        : [...recents, ...suggestions.take(10)];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Set your route'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(
                  controller: _pickupController,
                  focusNode: _pickupFocus,
                  hint: 'Pickup location',
                  active: draft.editing == DraftField.pickup,
                  onFocus: () {
                    draft.setEditing(DraftField.pickup);
                    setState(() => _query = '');
                  },
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _pickupController.clear();
                    setState(() => _query = '');
                  },
                ),
                if (_wantStop) ...[
                  const SizedBox(height: 8),
                  _Field(
                    controller: _stopController,
                    focusNode: _stopFocus,
                    hint: 'Stop along the way',
                    active: draft.editing == DraftField.stop,
                    onFocus: () {
                      draft.setEditing(DraftField.stop);
                      setState(() => _query = '');
                    },
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _stopController.clear();
                      draft.setStop(null);
                      draft.setEditing(DraftField.dropoff);
                      setState(() {
                        _wantStop = false;
                        _query = '';
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _Field(
                  controller: _dropoffController,
                  focusNode: _dropoffFocus,
                  hint: 'Where to?',
                  active: draft.editing == DraftField.dropoff,
                  onFocus: () {
                    draft.setEditing(DraftField.dropoff);
                    setState(() => _query = '');
                  },
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _dropoffController.clear();
                    setState(() => _query = '');
                  },
                ),
                if (!_wantStop)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _wantStop = true;
                        _query = '';
                      });
                      draft.setEditing(DraftField.stop);
                      _focusActiveField();
                    },
                    icon: Icon(Icons.add_rounded, size: 18, color: c.accent),
                    label: Text(
                      'Add a stop',
                      style: TextStyle(color: c.accent),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching places',
                    body: 'Try a mall, a station, or a neighbourhood name.',
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: c.line),
                    itemBuilder: (_, i) {
                      final place = results[i];
                      return InkWell(
                        onTap: () => _choose(place),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconFor(place),
                                  size: 17,
                                  color: c.textDim,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      place.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: c.textDim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                distanceLabel(
                                  haversineKm(place.coord, session.myLocation),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textMute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.active,
    required this.onFocus,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool active;
  final VoidCallback onFocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: () {
        // Select the existing place name so typing replaces it rather than
        // appending to it — otherwise editing a set field never matches.
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        onFocus();
      },
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: active ? c.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(
            hint == 'Where to?' ? Icons.stop_rounded : Icons.circle,
            size: hint == 'Where to?' ? 12 : 10,
            color: hint == 'Pickup location'
                ? c.accent
                : (hint == 'Where to?' ? c.text : c.warn),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, size: 17, color: c.textMute),
                onPressed: onClear,
              ),
      ),
    );
  }
}
