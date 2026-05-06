/// ServiceType domain model + built-in catalog.
///
/// Each ServiceType defines how long a session takes and how many
/// bookings can share the same 30-minute window (PRD §5.2, §6.1).
library;

import 'package:flutter/foundation.dart';

@immutable
class ServiceType {
  const ServiceType({
    required this.id,
    required this.name,
    required this.icon,
    required this.avgDurationMinutes,
    required this.maxCapacityPerSlot,
  });

  final String id;
  final String name;

  /// Emoji or icon label used in the UI.
  final String icon;

  /// Average time to serve one patient (used for wait-time estimate, PRD §6.2).
  final int avgDurationMinutes;

  /// Maximum concurrent bookings allowed in the same 30-minute window (PRD §6.1).
  final int maxCapacityPerSlot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ServiceType && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceType($name)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Built-in catalog  (matches mock_data.dart — single source of truth going
// forward; mock_data.dart's list will delegate here in Milestone 4).
// ─────────────────────────────────────────────────────────────────────────────
abstract final class ServiceCatalog {
  static const generalConsultation = ServiceType(
    id: 'svc_general',
    name: 'General Consultation',
    icon: '🩺',
    avgDurationMinutes: 30,
    maxCapacityPerSlot: 5,
  );

  static const followUpVisit = ServiceType(
    id: 'svc_followup',
    name: 'Follow-up Visit',
    icon: '🔁',
    avgDurationMinutes: 20,
    maxCapacityPerSlot: 6,
  );

  static const labTest = ServiceType(
    id: 'svc_lab',
    name: 'Lab Test',
    icon: '🧪',
    avgDurationMinutes: 15,
    maxCapacityPerSlot: 8,
  );

  static const vaccination = ServiceType(
    id: 'svc_vaccine',
    name: 'Vaccination',
    icon: '💉',
    avgDurationMinutes: 10,
    maxCapacityPerSlot: 10,
  );

  static const dentalCheckup = ServiceType(
    id: 'svc_dental',
    name: 'Dental Checkup',
    icon: '🦷',
    avgDurationMinutes: 45,
    maxCapacityPerSlot: 3,
  );

  /// Ordered list for dropdowns.
  static const List<ServiceType> all = [
    generalConsultation,
    followUpVisit,
    labTest,
    vaccination,
    dentalCheckup,
  ];

  /// Look up by id — returns null for unknown ids.
  static ServiceType? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
