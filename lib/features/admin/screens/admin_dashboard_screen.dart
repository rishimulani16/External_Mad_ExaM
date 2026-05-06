/// Admin Dashboard — polished queue monitoring screen.
///
/// Reacts to [appointmentListProvider] for all derived data.
/// Highlights: summary stats bar, status distribution chart, now-serving hero
/// with live indicator, colour-coded upcoming queue, and action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/state/appointment_controller.dart';
import '../../../core/state/providers.dart';
import '../../../common/widgets/status_badge.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // All reactive reads — this widget rebuilds on every mutation.
    final all       = ref.watch(appointmentListProvider);
    final serving   = ref.watch(currentServingProvider);
    final pending   = ref.watch(scheduledQueueProvider);

    // Summary counts derived from the full list (today + historical).
    final counts = _StatusCounts.from(all);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('btn_admin_search'),
            tooltip: 'Search appointments',
            icon: const Icon(Icons.search_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.routeSearch),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date + live indicator ────────────────────────────────────
            _DateHeader(),
            const SizedBox(height: 20),

            // ── Summary stat cards ───────────────────────────────────────
            _SectionLabel('Today at a Glance'),
            const SizedBox(height: 10),
            _StatGrid(counts: counts),
            const SizedBox(height: 16),

            // ── Status distribution bar ──────────────────────────────────
            _DistributionBar(counts: counts),
            const SizedBox(height: 28),

            // ── Now Serving ──────────────────────────────────────────────
            _SectionLabel('Now Serving'),
            const SizedBox(height: 10),
            serving == null
                ? const _EmptyServingCard()
                : _ServingHero(appointment: serving),
            const SizedBox(height: 20),

            // ── Admin Actions ────────────────────────────────────────────
            _SectionLabel('Actions'),
            const SizedBox(height: 10),
            _ActionButtons(
              serving: serving,
              hasPending: pending.isNotEmpty,
              onMarkCompleted: serving == null
                  ? null
                  : () => _updateStatus(context, ref, serving.id,
                      AppointmentStatus.completed),
              onAdvance: pending.isEmpty
                  ? null
                  : () => _advance(context, ref),
              onReschedule: () => Navigator.pushNamed(
                  context, AppConstants.routeAdminQueueControl),
              onCancel: serving == null
                  ? null
                  : () => _cancel(context, ref, serving.id),
            ),
            const SizedBox(height: 28),

            // ── Upcoming Queue ───────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Upcoming Queue'),
                _CountBadge(
                  count: pending.length,
                  label: 'waiting',
                  color: Theme.of(context).colorScheme.primary,
                  bg: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 10),
            pending.isEmpty
                ? const _QueueClearCard()
                : _UpcomingQueue(pending: pending, ref: ref,
                    onTap: () => Navigator.pushNamed(
                        context, AppConstants.routeAdminQueueControl)),
          ],
        ),
      ),
    );
  }

  // ── Controller calls ────────────────────────────────────────────────────────

  void _advance(BuildContext ctx, WidgetRef ref) =>
      _handle(ctx, ref.read(appointmentListProvider.notifier).advanceQueue(),
          'Advanced to next patient');

  void _updateStatus(
      BuildContext ctx, WidgetRef ref, String id, AppointmentStatus s) =>
      _handle(ctx,
          ref.read(appointmentListProvider.notifier).updateStatus(id, s),
          'Status updated');

  void _cancel(BuildContext ctx, WidgetRef ref, String id) =>
      _handle(ctx,
          ref.read(appointmentListProvider.notifier).cancelAppointment(id),
          'Appointment cancelled');

  void _handle(BuildContext ctx, BookingResult r, String ok) {
    switch (r) {
      case BookingSuccess():
        ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(ok),
                behavior: SnackBarBehavior.floating));
      case BookingFailure(:final error):
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(ctx).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data helper
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCounts {
  const _StatusCounts({
    required this.scheduled,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });

  final int scheduled;
  final int inProgress;
  final int completed;
  final int cancelled;

  int get total => scheduled + inProgress + completed + cancelled;

  factory _StatusCounts.from(List<Appointment> all) {
    int sc = 0, ip = 0, co = 0, ca = 0;
    for (final a in all) {
      switch (a.status) {
        case AppointmentStatus.scheduled:   sc++; break;
        case AppointmentStatus.inProgress:  ip++; break;
        case AppointmentStatus.completed:   co++; break;
        case AppointmentStatus.cancelled:   ca++; break;
      }
    }
    return _StatusCounts(
        scheduled: sc, inProgress: ip, completed: co, cancelled: ca);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Animated live indicator + date.
class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
        const _PulseDot(color: Color(0xFF0E9F6E)),
        const SizedBox(width: 8),
        Text(
          'Live  ·  ${DateFormat('EEEE, dd MMM yyyy').format(DateTime.now())}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
        ),
      ]);
}

/// Pulsing green dot widget (CSS-equivalent using AnimationController).
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1)
            ],
          ),
        ),
      );
}

// ── Summary stat grid ────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.counts});
  final _StatusCounts counts;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _StatCard(
          label: 'Scheduled',
          count: counts.scheduled,
          icon: Icons.schedule_rounded,
          color: const Color(0xFF1A56DB),
          bg: const Color(0xFFEBF5FF),
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(
          label: 'In Progress',
          count: counts.inProgress,
          icon: Icons.play_circle_outline_rounded,
          color: const Color(0xFF92400E),
          bg: const Color(0xFFFEF3C7),
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(
          label: 'Completed',
          count: counts.completed,
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF03543F),
          bg: const Color(0xFFDEF7EC),
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(
          label: 'Cancelled',
          count: counts.cancelled,
          icon: Icons.cancel_outlined,
          color: const Color(0xFF9B1C1C),
          bg: const Color(0xFFFDE8E8),
        )),
      ]);
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8)),
          ),
        ]),
      );
}

// ── Status distribution bar ──────────────────────────────────────────────────

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.counts});
  final _StatusCounts counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.total;
    if (total == 0) return const SizedBox.shrink();

    final segments = [
      _Seg(counts.scheduled,  const Color(0xFF1A56DB), 'Scheduled'),
      _Seg(counts.inProgress, const Color(0xFFF59E0B), 'In Progress'),
      _Seg(counts.completed,  const Color(0xFF0E9F6E), 'Completed'),
      _Seg(counts.cancelled,  const Color(0xFFE02424), 'Cancelled'),
    ].where((s) => s.count > 0).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('Status Distribution'),
      const SizedBox(height: 8),
      // Segmented horizontal bar
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 14,
          child: Row(
            children: segments.map((s) {
              final fraction = s.count / total;
              return Expanded(
                flex: (fraction * 1000).round(),
                child: Container(color: s.color),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 10),
      // Legend
      Wrap(
        spacing: 14,
        runSpacing: 6,
        children: segments.map((s) => _LegendDot(
              color: s.color,
              label: '${s.label} (${s.count})',
            )).toList(),
      ),
    ]);
  }
}

class _Seg {
  const _Seg(this.count, this.color, this.label);
  final int count;
  final Color color;
  final String label;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ]);
}

// ── Now Serving hero ─────────────────────────────────────────────────────────

class _ServingHero extends StatelessWidget {
  const _ServingHero({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF1E429F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                appointment.userName[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  Text(appointment.displayId,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ]),
          ),
          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0E9F6E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const _PulseDot(color: Colors.white),
              const SizedBox(width: 5),
              const Text('LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _InfoPill(
              icon: Icons.medical_services_outlined,
              label: appointment.serviceType.name),
          const SizedBox(width: 8),
          _InfoPill(
              icon: Icons.access_time_outlined,
              label: appointment.timeSlotLabel),
        ]),
        const SizedBox(height: 8),
        _InfoPill(
            icon: Icons.calendar_today_outlined,
            label: fmt.format(appointment.dateTime)),
        const SizedBox(height: 14),
        // Token number
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(
            'Token  #${appointment.queuePosition}',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]);
}

class _EmptyServingCard extends StatelessWidget {
  const _EmptyServingCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No patient currently being served.',
                style: TextStyle(color: Colors.grey.shade500)),
          ]),
        ),
      );
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.serving,
    required this.hasPending,
    required this.onMarkCompleted,
    required this.onAdvance,
    required this.onReschedule,
    required this.onCancel,
  });

  final Appointment? serving;
  final bool hasPending;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onAdvance;
  final VoidCallback onReschedule;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
            child: PrimaryButton(
              key: const Key('btn_mark_completed'),
              label: 'Mark Completed',
              icon: Icons.check_circle_outline_rounded,
              onPressed: onMarkCompleted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              key: const Key('btn_advance_next'),
              label: 'Next Patient',
              icon: Icons.skip_next_rounded,
              onPressed: onAdvance,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('btn_reschedule'),
              onPressed: onReschedule,
              icon: const Icon(Icons.edit_calendar_outlined, size: 16),
              label: const Text('Reschedule'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('btn_cancel_apt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                    color: onCancel == null
                        ? Colors.grey.shade300
                        : Theme.of(context).colorScheme.error),
              ),
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Cancel'),
            ),
          ),
        ]),
      ]);
}

// ── Upcoming queue ────────────────────────────────────────────────────────────

class _UpcomingQueue extends StatelessWidget {
  const _UpcomingQueue({
    required this.pending,
    required this.ref,
    required this.onTap,
  });
  final List<Appointment> pending;
  final WidgetRef ref;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        key: const Key('list_admin_queue'),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _UpcomingTile(
          appointment: pending[i],
          isNext: i == 0,
          onTap: onTap,
        ),
      );
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.appointment,
    required this.isNext,
    required this.onTap,
  });
  final Appointment appointment;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Next patient uses amber highlight; others use neutral white.
    final bg     = isNext ? const Color(0xFFFFFBEB) : Colors.white;
    final border = isNext ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB);
    final numBg  = isNext
        ? const Color(0xFFF59E0B)
        : Theme.of(context).colorScheme.primaryContainer;
    final numFg  = isNext
        ? Colors.white
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(children: [
            // Token circle
            CircleAvatar(
              radius: 20,
              backgroundColor: numBg,
              child: Text('${appointment.queuePosition}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: numFg,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(appointment.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      if (isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Next Up',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      '${appointment.serviceType.name}'
                      '  ·  ${appointment.timeSlotLabel}'
                      '  ·  ~${appointment.estimatedWaitMinutes}m wait',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280)),
                    ),
                  ]),
            ),
            const SizedBox(width: 6),
            const StatusBadge(status: AppointmentStatus.scheduled),
          ]),
        ),
      ),
    );
  }
}

class _QueueClearCard extends StatelessWidget {
  const _QueueClearCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFFDEF7EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6EE7B7)),
        ),
        child: Center(
          child: Column(children: [
            const Icon(Icons.check_circle_rounded,
                size: 40, color: Color(0xFF0E9F6E)),
            const SizedBox(height: 8),
            Text('Queue is clear!',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: const Color(0xFF03543F),
                        fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('No upcoming patients.',
                style: TextStyle(
                    color: Colors.green.shade600, fontSize: 12)),
          ]),
        ),
      );
}

// ── Utility widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
            ),
      );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });
  final int count;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text('$count $label',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}
