import 'package:flutter/material.dart';

/// Admin Queue Control Screen — Screen 5 (PRD §4)
///
/// Shown when admin taps an appointment in the Dashboard.
/// Allows changing status: Advance (→ In Progress), Complete, Cancel, Reschedule.
/// State mutation logic (Riverpod notifier + Firestore/Hive write) — Milestone 3.
class AdminQueueControlScreen extends StatelessWidget {
  const AdminQueueControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queue Control')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Appointment Detail Card ---
            Card(
              key: const Key('card_appointment_detail'),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Appointment ID', value: 'APT-XXXXXXXX'),
                    _DetailRow(label: 'Customer', value: 'Patient Name'),
                    _DetailRow(label: 'Service', value: 'General Consultation'),
                    _DetailRow(label: 'Date & Slot', value: 'DD MMM YYYY • 09:00 AM'),
                    _DetailRow(label: 'Queue Position', value: '#--'),
                    _DetailRow(label: 'Status', value: 'Scheduled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Admin Action Buttons ---
            FilledButton.icon(
              key: const Key('btn_mark_in_progress'),
              onPressed: () {
                // TODO (Milestone 3): Call AdminQueueNotifier.advanceQueue()
                _showPlaceholder(context, 'Mark In Progress');
              },
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Mark as In Progress'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('btn_mark_completed'),
              onPressed: () {
                // TODO (Milestone 3): Call AdminQueueNotifier.complete()
                _showPlaceholder(context, 'Mark Completed');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Completed'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('btn_reschedule'),
              onPressed: () {
                // TODO (Milestone 3): Open booking form in reschedule mode
                _showPlaceholder(context, 'Reschedule');
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Reschedule'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('btn_cancel_appointment'),
              onPressed: () {
                // TODO (Milestone 3): Call AdminQueueNotifier.cancel()
                _showPlaceholder(context, 'Cancel');
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Appointment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                    color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext ctx, String action) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('[Placeholder] "$action" — logic in Milestone 3')),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
