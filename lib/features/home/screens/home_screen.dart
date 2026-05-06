import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Home / Dashboard Screen — Screen 1 (PRD §4)
///
/// Entry point for users. Provides navigation to Booking, Queue Status,
/// and Admin Login. Business logic will be added in Milestone 3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Book appointments & track your queue — online or offline.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _HomeNavButton(
              id: 'btn_book_appointment',
              label: 'Book Appointment',
              icon: Icons.calendar_month_outlined,
              route: AppConstants.routeBooking,
            ),
            const SizedBox(height: 16),
            _HomeNavButton(
              id: 'btn_track_queue',
              label: 'Track My Queue',
              icon: Icons.queue_outlined,
              route: AppConstants.routeQueue,
            ),
            const SizedBox(height: 16),
            _HomeNavButton(
              id: 'btn_search',
              label: 'Search Appointments',
              icon: Icons.search_outlined,
              route: AppConstants.routeSearch,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('btn_admin_login'),
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.routeAdminDashboard),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Admin Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavButton extends StatelessWidget {
  const _HomeNavButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: Key(id),
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
