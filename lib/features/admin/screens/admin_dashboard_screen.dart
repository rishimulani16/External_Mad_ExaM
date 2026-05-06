import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Appointments Dashboard — Screen 4 (PRD §4)
///
/// Lists all appointments for the day; supports search and filter.
/// Admin actions (mark complete, advance queue) live in AdminQueueControlScreen.
/// Data loading (Firestore / Hive) and Riverpod provider wiring — Milestone 3.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            key: const Key('btn_admin_search'),
            tooltip: 'Search & Filter',
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.routeSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Date Filter Header ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Today — [Date placeholder]',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  key: const Key('btn_change_date'),
                  onPressed: () {
                    // TODO (Milestone 3): Date picker for admin view
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Appointment List ---
          Expanded(
            child: ListView.separated(
              key: const Key('list_appointments'),
              padding: const EdgeInsets.all(16),
              itemCount: 5, // placeholder count
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AppointmentTile(
                index: index,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.routeAdminQueueControl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder tile for an appointment row.
class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.index, required this.onTap});

  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: Key('tile_appointment_$index'),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text('${index + 1}'),
        ),
        title: Text('Patient Name $index'),
        subtitle: const Text('Service: General • 09:00 AM'),
        trailing: Chip(
          label: const Text('Scheduled'),
          visualDensity: VisualDensity.compact,
          backgroundColor: colorScheme.secondaryContainer,
        ),
        onTap: onTap,
      ),
    );
  }
}
