import 'package:flutter/material.dart';

/// Queue & Status Tracker Screen — Screen 3 (PRD §4)
///
/// Displays: current token being served, user's queue position,
/// estimated wait time, and appointment status badge.
/// Real-time update logic (Firestore streams / Hive watch) — Milestone 3.
class QueueTrackerScreen extends StatelessWidget {
  const QueueTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queue Tracker')),
      body: const _QueueTrackerPlaceholder(),
    );
  }
}

class _QueueTrackerPlaceholder extends StatelessWidget {
  const _QueueTrackerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Current Token ---
          Card(
            key: const Key('card_current_token'),
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Now Serving',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Token #--',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- User Position ---
          Card(
            key: const Key('card_user_position'),
            child: ListTile(
              leading: const Icon(Icons.format_list_numbered_outlined),
              title: const Text('Your Position'),
              trailing: Text(
                '#--',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- Estimated Wait Time ---
          Card(
            key: const Key('card_wait_time'),
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Estimated Wait'),
              trailing: Text(
                '-- mins',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- Status Badge ---
          Card(
            key: const Key('card_appointment_status'),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Appointment Status'),
              trailing: Chip(
                label: const Text('Scheduled'),
                backgroundColor: colorScheme.secondaryContainer,
              ),
            ),
          ),

          const Spacer(),

          // --- Refresh (placeholder) ---
          OutlinedButton.icon(
            key: const Key('btn_refresh_queue'),
            onPressed: () {
              // TODO (Milestone 3): Re-fetch queue state from provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('[Placeholder] Queue refresh — Milestone 3')),
              );
            },
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
