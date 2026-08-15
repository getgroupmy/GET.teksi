import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/places.dart';
import '../../models/models.dart';
import '../../state/draft.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final draft = context.read<DraftStore>();
    final user = session.requireUser;

    void go(Place place) {
      draft.setDropoff(place);
      draft.setStep(DraftStep.price);
      context.go('/p');
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Saved places'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionLabel('Shortcuts'),
          AppRow(
            icon: Icons.home_rounded,
            title: user.homePlace?.name ?? 'Add home',
            subtitle:
                user.homePlace?.address ??
                'Set your home address for one-tap booking',
            onTap: () => user.homePlace == null
                ? _pick(context, session, home: true)
                : go(user.homePlace!),
            trailing: user.homePlace == null
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: c.textMute,
                    ),
                    tooltip: 'Remove home',
                    onPressed: () => session.clearShortcut(home: true),
                  ),
          ),
          AppRow(
            icon: Icons.work_outline_rounded,
            title: user.workPlace?.name ?? 'Add work',
            subtitle:
                user.workPlace?.address ??
                'Set your work address for one-tap booking',
            onTap: () => user.workPlace == null
                ? _pick(context, session, home: false)
                : go(user.workPlace!),
            trailing: user.workPlace == null
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: c.textMute,
                    ),
                    tooltip: 'Remove work',
                    onPressed: () => session.clearShortcut(home: false),
                  ),
          ),
          if (user.homePlace != null || user.workPlace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _pick(context, session, home: true),
                      child: const Text('Change home'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _pick(context, session, home: false),
                      child: const Text('Change work'),
                    ),
                  ),
                ],
              ),
            ),
          const SectionLabel('Popular in Kuala Lumpur'),
          for (final place in places.take(10))
            AppRow(
              icon: Icons.place_outlined,
              title: place.name,
              subtitle: place.address,
              onTap: () => go(place),
            ),
        ],
      ),
    );
  }

  void _pick(BuildContext context, SessionStore session, {required bool home}) {
    showAppSheet(
      context,
      title: home ? 'Set your home' : 'Set your work',
      builder: (sheetContext) => _PlacePicker(
        onPick: (place) {
          session.saveShortcut(
            home: home,
            place: place.copyWith(category: PlaceCategory.saved),
          );
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.onPick});

  final ValueChanged<Place> onPick;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _query.trim().isEmpty
        ? allPlaces.take(12).toList()
        : fuzzySearch(_query, limit: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search for an address',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: results.isEmpty
              ? const EmptyState(title: 'No matches', body: 'Try another name.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => widget.onPick(results[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 17,
                            color: c.textDim,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  results[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  results[i].address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: c.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
