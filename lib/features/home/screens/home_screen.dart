/// HomeScreen — matches the QueueEase design reference.
///
/// Layout:
///   • Teal AppBar with bold centred app name.
///   • Cream scaffold background.
///   • Centred "Welcome" heading + subtitle.
///   • Three full-width teal FilledButton (Book, Track, Search).
///   • One full-width teal OutlinedButton (Admin Login).
///   • BottomNavigationBar: Home | Queue | Appts | Admin.
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on Home — no-op.
        break;
      case 1:
        Navigator.pushNamed(context, AppConstants.routeQueue);
        break;
      case 2:
        Navigator.pushNamed(context, AppConstants.routeBooking);
        break;
      case 3:
        Navigator.pushNamed(context, AppConstants.routeAdminDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // ── Welcome heading ────────────────────────────────────────
              Text(
                'Welcome to\n${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: teal,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),

              // ── Subtitle ───────────────────────────────────────────────
              Text(
                'Book appointments & track your queue —\nonline or offline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // ── Primary nav buttons ────────────────────────────────────
              _NavButton(
                id: 'btn_book_appointment',
                label: 'Book Appointment',
                icon: Icons.calendar_month_outlined,
                onPressed: () =>
                    Navigator.pushNamed(context, AppConstants.routeBooking),
              ),
              const SizedBox(height: 14),

              _NavButton(
                id: 'btn_track_queue',
                label: 'Track My Queue',
                icon: Icons.people_outline_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppConstants.routeQueue),
              ),
              const SizedBox(height: 14),

              _NavButton(
                id: 'btn_search_appointments',
                label: 'Search Appointments',
                icon: Icons.search_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppConstants.routeSearch),
              ),
              const SizedBox(height: 28),

              // ── Admin Login (outlined) ─────────────────────────────────
              OutlinedButton.icon(
                key: const Key('btn_admin_login'),
                onPressed: () => Navigator.pushNamed(
                    context, AppConstants.routeAdminDashboard),
                icon: const Icon(Icons.shield_outlined, size: 20),
                label: const Text('Admin Login'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _onNavTap(i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Appts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

// ── Reusable nav button ───────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: Key(id),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      // Height override — theme default is 56 which matches the design.
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
