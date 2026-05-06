/// Admin Queue Control Screen — detail view for a specific appointment.
///
/// Opened from [AdminDashboardScreen] via [AppConstants.routeAdminQueueControl].
/// Reads [currentServingProvider] (the in-progress appointment) and
/// [scheduledQueueProvider] (pending appointments).
///
/// All action buttons call real [AppointmentController] methods — no placeholders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/state/appointment_controller.dart';
import '../../../core/state/providers.dart';
import '../../../common/widgets/status_badge.dart';

class AdminQueueControlScreen extends ConsumerWidget {
  const AdminQueueControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serving = ref.watch(currentServingProvider);
    final pending = ref.watch(scheduledQueueProvider);
    final all     = ref.watch(appointmentListProvider);

    // The "subject" of this control screen:
    //  1. If there is an in-progress appointment → show it (admin acts on it).
    //  2. Else if there are scheduled ones → show the next in line.
    //  3. Otherwise show an empty state.
    final subject = serving ?? (pending.isNotEmpty ? pending.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Queue Control'),
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
      ),
      body: subject == null
          ? _EmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Appointment Detail Card ────────────────────────────
                  _DetailCard(appointment: subject),
                  const SizedBox(height: 24),

                  // ── Action Buttons ────────────────────────────────────
                  _SectionLabel('Actions'),
                  const SizedBox(height: 12),
                  _ActionPanel(
                    appointment: subject,
                    ref: ref,
                    context: context,
                  ),
                  const SizedBox(height: 32),

                  // ── Full Queue Preview ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('Full Queue Today'),
                      _Pill('${all.where((a) =>
                          a.status == AppointmentStatus.scheduled ||
                          a.status == AppointmentStatus.inProgress).length} active'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _FullQueueList(
                    appointments: all
                        .where((a) =>
                            a.status == AppointmentStatus.scheduled ||
                            a.status == AppointmentStatus.inProgress ||
                            a.status == AppointmentStatus.completed)
                        .toList()
                      ..sort((a, b) =>
                          a.queuePosition.compareTo(b.queuePosition)),
                    servingId: serving?.id,
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final isInProgress = appointment.status == AppointmentStatus.inProgress;

    return Container(
      decoration: BoxDecoration(
        gradient: isInProgress
            ? const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF1E429F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isInProgress ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: isInProgress
                  ? const Color(0xFF1A56DB).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isInProgress
                ? Colors.white.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              appointment.userName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isInProgress
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.userName,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isInProgress ? Colors.white : const Color(0xFF111827)),
                  ),
                  Text(
                    appointment.displayId,
                    style: TextStyle(
                        fontSize: 12,
                        color: isInProgress ? Colors.white60 : const Color(0xFF6B7280)),
                  ),
                ]),
          ),
          StatusBadge(status: appointment.status),
        ]),
        const SizedBox(height: 16),
        Divider(color: isInProgress ? Colors.white24 : Colors.grey.shade200, height: 1),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.medical_services_outlined,
          label: 'Service',
          value: appointment.serviceType.name,
          light: isInProgress,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: fmt.format(appointment.dateTime),
          light: isInProgress,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.access_time_outlined,
          label: 'Slot',
          value: appointment.timeSlotLabel,
          light: isInProgress,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.format_list_numbered_rounded,
          label: 'Queue #',
          value: appointment.queuePosition == 0
              ? '—'
              : '#${appointment.queuePosition}',
          light: isInProgress,
        ),
        if (appointment.estimatedWaitMinutes > 0) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Est. Wait',
            value: '${appointment.estimatedWaitMinutes} min',
            light: isInProgress,
          ),
        ],
        const SizedBox(height: 8),
        _InfoRow(
          icon: appointment.isSynced
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_outlined,
          label: 'Sync',
          value: appointment.isSynced ? 'Synced' : 'Pending sync',
          light: isInProgress,
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.light,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final labelColor = light ? Colors.white60 : const Color(0xFF6B7280);
    final valueColor = light ? Colors.white : const Color(0xFF111827);

    return Row(children: [
      Icon(icon, size: 15, color: labelColor),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: Text(label,
            style: TextStyle(fontSize: 12, color: labelColor)),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.appointment,
    required this.ref,
    required this.context,
  });

  final Appointment appointment;
  final WidgetRef ref;
  final BuildContext context;

  void _run(BookingResult result, String okMsg) {
    switch (result) {
      case BookingSuccess():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(okMsg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0E9F6E),
        ));
        // Pop back to dashboard after a successful action.
        Navigator.of(context).pop();
      case BookingFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(appointmentListProvider.notifier);
    final id = appointment.id;
    final isScheduled   = appointment.status == AppointmentStatus.scheduled;
    final isInProgress  = appointment.status == AppointmentStatus.inProgress;

    return Column(children: [
      // Mark In Progress (only for scheduled)
      if (isScheduled) ...[
        _ActionBtn(
          key: const Key('btn_mark_in_progress'),
          label: 'Mark as In Progress',
          icon: Icons.play_circle_outline_rounded,
          color: const Color(0xFF1A56DB),
          onPressed: () => _run(
            notifier.updateStatus(id, AppointmentStatus.inProgress),
            'Moved to In Progress',
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Mark Completed (scheduled or in-progress)
      if (isScheduled || isInProgress) ...[
        _ActionBtn(
          key: const Key('btn_mark_completed'),
          label: 'Mark as Completed',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF0E9F6E),
          onPressed: () => _run(
            notifier.updateStatus(id, AppointmentStatus.completed),
            'Appointment marked completed',
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Advance Queue (marks current complete + promotes next)
      if (isInProgress) ...[
        _ActionBtn(
          key: const Key('btn_advance_queue'),
          label: 'Complete & Call Next →',
          icon: Icons.skip_next_rounded,
          color: const Color(0xFF7E3AF2),
          onPressed: () => _run(
            notifier.advanceQueue(),
            'Queue advanced — next patient called',
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Cancel (available for both scheduled and in-progress)
      if (isScheduled || isInProgress) ...[
        OutlinedButton.icon(
          key: const Key('btn_cancel_appointment'),
          onPressed: () => _confirmCancel(context, notifier, id),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Cancel Appointment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],

      // Completed / Cancelled state — no actions left
      if (!isScheduled && !isInProgress)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.grey.shade500, size: 18),
            const SizedBox(width: 10),
            Text('No further actions available for this appointment.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ]),
        ),
    ]);
  }

  void _confirmCancel(
    BuildContext ctx,
    AppointmentController notifier,
    String id,
  ) {
    showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
            'This will remove the patient from the queue and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _run(notifier.cancelAppointment(id), 'Appointment cancelled');
      }
    });
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Queue List
// ─────────────────────────────────────────────────────────────────────────────

class _FullQueueList extends StatelessWidget {
  const _FullQueueList({
    required this.appointments,
    required this.servingId,
  });

  final List<Appointment> appointments;
  final String? servingId;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('No appointments today.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final a = appointments[i];
        final isServing = a.id == servingId;
        final isDone = a.status == AppointmentStatus.completed;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isServing
                ? const Color(0xFFEBF5FF)
                : isDone
                    ? const Color(0xFFF9FAFB)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isServing
                  ? const Color(0xFF93C5FD)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(children: [
            // Token
            CircleAvatar(
              radius: 16,
              backgroundColor: isServing
                  ? const Color(0xFF1A56DB)
                  : isDone
                      ? const Color(0xFF0E9F6E)
                      : Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                a.queuePosition == 0 ? '✓' : '${a.queuePosition}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isServing || isDone
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(a.userName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDone ? const Color(0xFF9CA3AF) : null)),
                Text('${a.serviceType.name}  ·  ${a.timeSlotLabel}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ]),
            ),
            StatusBadge(status: a.status),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded,
                size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text('All done!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('No active appointments to manage.',
                style: TextStyle(color: Colors.grey.shade500)),
          ]),
        ),
      );
}

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

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer)),
      );
}
