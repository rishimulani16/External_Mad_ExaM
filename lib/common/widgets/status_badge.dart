import 'package:flutter/material.dart';

/// Re-usable status badge chip.
/// Shows a colour-coded label for Appointment status values
/// (Scheduled, In Progress, Completed, Cancelled).
/// Used by both the Admin Dashboard and Queue Tracker screens.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color fgColor;

    switch (status.toLowerCase()) {
      case 'scheduled':
        bgColor = colorScheme.primaryContainer;
        fgColor = colorScheme.onPrimaryContainer;
        break;
      case 'in progress':
        bgColor = Colors.amber.shade100;
        fgColor = Colors.amber.shade900;
        break;
      case 'completed':
        bgColor = Colors.green.shade100;
        fgColor = Colors.green.shade900;
        break;
      case 'cancelled':
        bgColor = colorScheme.errorContainer;
        fgColor = colorScheme.onErrorContainer;
        break;
      default:
        bgColor = colorScheme.surfaceContainerHighest;
        fgColor = colorScheme.onSurface;
    }

    return Chip(
      label: Text(status),
      backgroundColor: bgColor,
      labelStyle: TextStyle(
          color: fgColor, fontSize: 12, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
