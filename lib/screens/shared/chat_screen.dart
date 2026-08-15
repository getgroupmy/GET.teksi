import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../data/fixtures.dart';
import '../../models/models.dart';
import '../../state/rides.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text, Role viewer) {
    if (text.trim().isEmpty) return;
    context.read<RidesStore>().sendMessage(widget.rideId, viewer, text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.watch<SessionStore>();
    final rides = context.watch<RidesStore>();
    final user = session.requireUser;
    final ride = rides.rides[widget.rideId];

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chat'),
        ),
        body: const EmptyState(
          title: 'Conversation unavailable',
          body: 'This ride no longer exists.',
        ),
      );
    }

    // Whichever side of the ride I'm on decides who I'm talking to.
    final viewer = ride.driverId == user.id
        ? Role.driver
        : (ride.passengerId == user.id ? Role.passenger : session.prefs.role);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rides.markChatRead(widget.rideId, viewer);
    });

    final other = viewer == Role.driver
        ? (ride.passengerName, ride.passengerAvatarColor, 'Passenger')
        : (ride.driverName ?? 'Driver', ride.driverAvatarColor ?? 0xFF9AA39D, 'Your driver');

    final messages = rides.chatFor(widget.rideId);
    final phrases = viewer == Role.driver ? quickPhrasesDriver : quickPhrasesPassenger;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: other.$1, color: other.$2, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${other.$3} · trip to ${ride.dropoff.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_rounded, color: c.accent),
            tooltip: 'Call',
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Calling ${other.$1}…'))),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, color: c.line),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Messages are only available during the trip.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.textMute),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final mine = m.from == viewer;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: mine ? c.brand : c.surface2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                m.text,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.3,
                                  color: mine ? c.brandInk : c.text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                clockTime(m.createdAt),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: mine
                                      ? c.brandInk.withValues(alpha: 0.55)
                                      : c.textMute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final phrase in phrases)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: phrase,
                      selected: false,
                      onTap: () => _send(phrase, viewer),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (v) => _send(v, viewer),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Send',
                    child: Material(
                      color: c.brand,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _send(_controller.text, viewer),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.send_rounded, size: 19, color: c.brandInk),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
