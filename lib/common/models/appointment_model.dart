/// Plain-Dart model for UI layer.
/// Hive TypeAdapter will be generated in Milestone 3 via build_runner.
/// All fields match PRD §5.1 data model specification.
library;

enum AppointmentStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class ServiceType {
  final String id;
  final String name;
  final String icon;
  final int avgDurationMinutes;
  final int maxCapacityPerSlot;

  const ServiceType({
    required this.id,
    required this.name,
    required this.icon,
    required this.avgDurationMinutes,
    required this.maxCapacityPerSlot,
  });
}

class AppointmentModel {
  final String id;
  final String customerName;
  final ServiceType serviceType;
  final DateTime date;
  final String timeSlot;
  final AppointmentStatus status;
  final int queuePosition;
  final int estimatedWaitMinutes;
  final bool isSynced;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.customerName,
    required this.serviceType,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
    required this.isSynced,
    required this.createdAt,
  });

  /// Human-readable appointment ID shown in UI (PRD §5.1)
  String get displayId => 'APT-${id.substring(0, 8).toUpperCase()}';

  AppointmentModel copyWith({
    AppointmentStatus? status,
    int? queuePosition,
    int? estimatedWaitMinutes,
    bool? isSynced,
  }) {
    return AppointmentModel(
      id: id,
      customerName: customerName,
      serviceType: serviceType,
      date: date,
      timeSlot: timeSlot,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
    );
  }
}
