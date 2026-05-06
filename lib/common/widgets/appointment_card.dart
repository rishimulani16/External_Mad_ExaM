import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import 'status_badge.dart';

/// Reusable appointment list card used in AppointmentListScreen and
/// SearchFilterScreen. Tapping calls [onTap] (e.g., navigate to detail).
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showQueueBadge = false,
  });

  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final bool showQueueBadge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat('dd MMM yyyy').format(appointment.date);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header row: name + status ---
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      appointment.customerName[0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          appointment.displayId,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: appointment.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // --- Detail row ---
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.medical_services_outlined,
                    label: appointment.serviceType.name,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: formattedDate,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.access_time_outlined,
                    label: appointment.timeSlot,
                  ),
                  if (showQueueBadge &&
                      appointment.status == AppointmentStatus.scheduled) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.format_list_numbered_outlined,
                      label: 'Q: #${appointment.queuePosition}',
                      isHighlighted: true,
                    ),
                  ],
                ],
              ),

              // --- Offline indicator ---
              if (!appointment.isSynced) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 14, color: Color(0xFF92400E)),
                    const SizedBox(width: 4),
                    Text(
                      'Pending sync',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF6B7280);
    final bgColor = isHighlighted
        ? Theme.of(context).colorScheme.primaryContainer
        : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
