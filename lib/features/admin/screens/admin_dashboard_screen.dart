import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/state/appointment_controller.dart';
import '../../../core/state/providers.dart';
import '../../../common/widgets/status_badge.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Dashboard — wired to Riverpod.
///
/// Reads [currentServingProvider] and [scheduledQueueProvider].
/// Calls [AppointmentController.advanceQueue], [updateStatus], [cancelAppointment].
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serving = ref.watch(currentServingProvider);
    final pending = ref.watch(scheduledQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            key: const Key('btn_admin_search'),
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.routeSearch),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      )),
            ]),
            const SizedBox(height: 20),

            // ── Currently Serving ───────────────────────────────────────────
            _Label('Currently Serving'),
            const SizedBox(height: 10),
            serving == null
                ? _EmptyServingCard()
                : _CurrentCard(appointment: serving),
            const SizedBox(height: 20),

            // ── Actions ─────────────────────────────────────────────────────
            _Label('Actions'),
            const SizedBox(height: 10),
            PrimaryButton(
              key: const Key('btn_mark_completed'),
              label: 'Mark as Completed',
              icon: Icons.check_circle_outline_rounded,
              onPressed: serving == null
                  ? null
                  : () => _updateStatus(
                      context, ref, serving.id, AppointmentStatus.completed),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              key: const Key('btn_advance_next'),
              label: 'Next Patient →',
              icon: Icons.skip_next_rounded,
              onPressed: pending.isEmpty ? null : () => _advance(context, ref),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_reschedule'),
                  onPressed: () => Navigator.pushNamed(
                      context, AppConstants.routeAdminQueueControl),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
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
                        color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: serving == null
                      ? null
                      : () => _cancel(context, ref, serving.id),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Pending Queue ───────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Label('Pending Queue'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pending.length} waiting',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer)),
              ),
            ]),
            const SizedBox(height: 10),
            if (pending.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Queue is clear!',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ]),
                ),
              )
            else
              ListView.separated(
                key: const Key('list_admin_queue'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _QueueTile(
                  appointment: pending[i],
                  onTap: () => Navigator.pushNamed(
                      context, AppConstants.routeAdminQueueControl),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Controller calls ──────────────────────────────────────────────────────

  void _advance(BuildContext ctx, WidgetRef ref) {
    final result =
        ref.read(appointmentListProvider.notifier).advanceQueue();
    _handleResult(ctx, result, 'Advanced to next patient');
  }

  void _updateStatus(BuildContext ctx, WidgetRef ref, String id,
      AppointmentStatus s) {
    final result =
        ref.read(appointmentListProvider.notifier).updateStatus(id, s);
    _handleResult(ctx, result, 'Status updated');
  }

  void _cancel(BuildContext ctx, WidgetRef ref, String id) {
    final result =
        ref.read(appointmentListProvider.notifier).cancelAppointment(id);
    _handleResult(ctx, result, 'Appointment cancelled');
  }

  void _handleResult(BuildContext ctx, BookingResult result, String okMsg) {
    switch (result) {
      case BookingSuccess():
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(okMsg)));
      case BookingFailure(:final error):
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(ctx).colorScheme.error,
        ));
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.appointment});
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_outline_rounded,
                color: Colors.white, size: 22),
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
          const StatusBadge(status: AppointmentStatus.inProgress),
        ]),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        _Row(icon: Icons.medical_services_outlined,
            label: appointment.serviceType.name),
        const SizedBox(height: 8),
        _Row(icon: Icons.calendar_today_outlined,
            label: fmt.format(appointment.dateTime)),
        const SizedBox(height: 8),
        _Row(icon: Icons.access_time_outlined,
            label: appointment.timeSlotLabel),
      ]),
    );
  }
}

class _EmptyServingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: Colors.white60),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]);
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.appointment, required this.onTap});
  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text('${appointment.queuePosition}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${appointment.serviceType.name} · ${appointment.timeSlotLabel}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6B7280))),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ]),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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
