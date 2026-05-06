import 'package:flutter/material.dart';
import '../../core/domain/appointment.dart';

/// Colour-coded status badge for all 4 [AppointmentStatus] values.
/// Used across AppointmentListScreen, QueueTrackerScreen, AdminDashboardScreen.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _palette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  static (Color bg, Color fg, IconData icon) _palette(AppointmentStatus s) =>
      switch (s) {
        AppointmentStatus.scheduled => (
            const Color(0xFFEBF5FF),
            const Color(0xFF1E429F),
            Icons.schedule_rounded,
          ),
        AppointmentStatus.inProgress => (
            const Color(0xFFFEF3C7),
            const Color(0xFF92400E),
            Icons.play_circle_outline_rounded,
          ),
        AppointmentStatus.completed => (
            const Color(0xFFDEF7EC),
            const Color(0xFF03543F),
            Icons.check_circle_outline_rounded,
          ),
        AppointmentStatus.cancelled => (
            const Color(0xFFFDE8E8),
            const Color(0xFF9B1C1C),
            Icons.cancel_outlined,
          ),
      };
}
