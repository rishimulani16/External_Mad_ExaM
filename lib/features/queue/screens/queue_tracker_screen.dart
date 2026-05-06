/// Queue Status Screen — fully wired to Riverpod.
///
/// Reads:
///   [currentServingProvider]        → token currently being served
///   [myAppointmentProvider]         → the user's own appointment
///   [scheduledQueueProvider]        → sorted pending queue
///   [selectedAppointmentIdProvider] → which appointment the user picked
///
/// A temporary "Viewing as:" dropdown lets the user switch between appointments
/// to simulate the "my appointment" concept until auth is implemented (Milestone 4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/state/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen shell
// ─────────────────────────────────────────────────────────────────────────────

class QueueTrackerScreen extends ConsumerWidget {
  const QueueTrackerScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serving  = ref.watch(currentServingProvider);
    final myApt    = ref.watch(myAppointmentProvider);
    final queue    = ref.watch(queueProvider);
    final pending  = ref.watch(scheduledQueueProvider);

    final body = _QueueBody(
      serving: serving,
      myApt: myApt,
      queue: queue,
      pending: pending,
    );

    if (isEmbedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Status')),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────

class _QueueBody extends ConsumerWidget {
  const _QueueBody({
    required this.serving,
    required this.myApt,
    required this.queue,
    required this.pending,
  });

  final Appointment? serving;
  final Appointment? myApt;
  final List<Appointment> queue;
  final List<Appointment> pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Derived display values
    final servingToken = serving?.queuePosition ?? 0;
    final myPos        = myApt?.queuePosition ?? 0;
    final myWait       = myApt?.estimatedWaitMinutes ?? 0;
    final ahead        = (myPos - 1).clamp(0, 999);
    final total        = queue.length;
    final progress     = total == 0
        ? 0.0
        : ((total - ahead) / total).clamp(0.0, 1.0);

    // All appointments available for the selector
    final all = ref.watch(appointmentListProvider);
    final selectable = all
        .where((a) =>
            a.status == AppointmentStatus.scheduled ||
            a.status == AppointmentStatus.inProgress)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Appointment Selector (temp — replaces auth in M4) ────────────
          _AppointmentSelector(
            all: selectable,
            selected: myApt,
            onChanged: (id) =>
                ref.read(selectedAppointmentIdProvider.notifier).state = id,
          ),
          const SizedBox(height: 16),

          // ── Now Serving Hero ─────────────────────────────────────────────
          _NowServingCard(servingToken: servingToken, serving: serving),
          const SizedBox(height: 16),

          // ── My Position Row ──────────────────────────────────────────────
          _MyPositionCard(
            token:       myPos,
            position:    myPos,
            waitMinutes: myWait,
          ),
          const SizedBox(height: 20),

          // ── Progress bar ─────────────────────────────────────────────────
          _QueueProgress(position: myPos, total: total, progress: progress),
          const SizedBox(height: 20),

          // ── Ahead in queue ───────────────────────────────────────────────
          Text(
            'AHEAD IN QUEUE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF),
                ),
          ),
          const SizedBox(height: 10),

          if (myApt == null)
            _NoAppointmentBanner()
          else if (ahead == 0 &&
              myApt!.status == AppointmentStatus.scheduled)
            _YouAreNextBanner()
          else if (myApt!.status == AppointmentStatus.inProgress)
            _NowServingYouBanner()
          else ...[
            for (int i = 0; i < ahead.clamp(0, 3); i++)
              _AheadTile(
                appointment: pending.length > i ? pending[i] : null,
                isNext: i == 0,
              ),
          ],

          const SizedBox(height: 24),

          // ── Refresh (triggers re-read from provider) ─────────────────────
          Center(
            child: TextButton.icon(
              key: const Key('btn_refresh_queue'),
              onPressed: () {
                // Riverpod auto-reacts to state changes; this is a UI hint only.
                // TODO (Milestone 4): Call syncManager.fetchQueue() here.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Queue is live — refreshed automatically.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Queue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appointment Selector (temporary, replaces auth)
// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentSelector extends StatelessWidget {
  const _AppointmentSelector({
    required this.all,
    required this.selected,
    required this.onChanged,
  });

  final List<Appointment> all;
  final Appointment? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(Icons.switch_account_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const Key('dropdown_my_appointment'),
              value: selected?.id,
              isDense: true,
              isExpanded: true,
              hint: const Text('Select your appointment'),
              items: all.map((a) {
                return DropdownMenuItem(
                  value: a.id,
                  child: Text(
                    '${a.displayId}  ·  ${a.userName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NowServingCard extends StatelessWidget {
  const _NowServingCard({required this.servingToken, required this.serving});

  final int servingToken;
  final Appointment? serving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF1E429F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.sensors_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text('Now Serving',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
        ]),
        const SizedBox(height: 12),
        Text(
          servingToken == 0 ? 'Queue Empty' : 'Token #$servingToken',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
        ),
        if (serving != null) ...[
          const SizedBox(height: 6),
          Text(
            serving!.userName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ]),
    );
  }
}

class _MyPositionCard extends StatelessWidget {
  const _MyPositionCard({
    required this.token,
    required this.position,
    required this.waitMinutes,
  });

  final int token;
  final int position;
  final int waitMinutes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
            child: _StatBox(
              key: const Key('card_my_token'),
              label: 'My Token',
              value: position == 0 ? '--' : '#$token',
              icon: Icons.confirmation_number_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade200),
          Expanded(
            child: _StatBox(
              key: const Key('card_my_position'),
              label: 'Position',
              value: position == 0 ? '--' : '#$position',
              icon: Icons.format_list_numbered_rounded,
              color: const Color(0xFF0E9F6E),
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade200),
          Expanded(
            child: _StatBox(
              key: const Key('card_wait_time'),
              label: 'Wait',
              value: position == 0 ? '--' : '${waitMinutes}m',
              icon: Icons.timer_outlined,
              color: const Color(0xFFD97706),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
          ),
        ],
      );
}

class _QueueProgress extends StatelessWidget {
  const _QueueProgress({
    required this.position,
    required this.total,
    required this.progress,
  });

  final int position;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Queue Progress',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              total == 0 ? '–' : '$position of $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      );
}

class _AheadTile extends StatelessWidget {
  const _AheadTile({required this.appointment, required this.isNext});

  final Appointment? appointment;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFFEF3C7) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNext ? const Color(0xFFFCD34D) : Colors.grey.shade200,
        ),
      ),
      child: Row(children: [
        Icon(
          isNext
              ? Icons.person_outline_rounded
              : Icons.people_outline_rounded,
          size: 18,
          color:
              isNext ? const Color(0xFF92400E) : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            appointment != null
                ? '${appointment!.userName}  (Token #${appointment!.queuePosition})'
                : '—',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isNext
                  ? const Color(0xFF92400E)
                  : const Color(0xFF374151),
            ),
          ),
        ),
        if (isNext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Next Up',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner variants
// ─────────────────────────────────────────────────────────────────────────────

class _YouAreNextBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Banner(
        color: const Color(0xFFDEF7EC),
        border: const Color(0xFF6EE7B7),
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF0E9F6E),
        title: "You're next!",
        titleColor: const Color(0xFF03543F),
        subtitle: 'Please proceed to the counter.',
        subtitleColor: const Color(0xFF059669),
      );
}

class _NowServingYouBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Banner(
        color: const Color(0xFFEBF5FF),
        border: const Color(0xFF93C5FD),
        icon: Icons.star_rounded,
        iconColor: const Color(0xFF1E429F),
        title: 'You are being served now!',
        titleColor: const Color(0xFF1E3A5F),
        subtitle: 'Please proceed to the service counter.',
        subtitleColor: const Color(0xFF1A56DB),
      );
}

class _NoAppointmentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Banner(
        color: const Color(0xFFF3F4F6),
        border: Colors.grey,
        icon: Icons.info_outline_rounded,
        iconColor: Colors.grey,
        title: 'No appointment selected',
        titleColor: const Color(0xFF374151),
        subtitle: 'Select an appointment above to track your position.',
        subtitleColor: const Color(0xFF6B7280),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.subtitleColor,
  });

  final Color color;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        )),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        )),
              ],
            ),
          ),
        ]),
      );
}
