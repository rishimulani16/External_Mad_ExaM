/// FilterCriteria — immutable value object representing all active
/// search and filter parameters.
///
/// Held in [filterProvider] and read by [filteredAppointmentsProvider].
/// Every field is optional (null = no constraint on that dimension).
library;

import 'package:flutter/foundation.dart';
import '../domain/appointment.dart';
import '../domain/service_type.dart';

@immutable
class FilterCriteria {
  const FilterCriteria({
    this.query = '',
    this.statuses = const {},
    this.serviceType,
    this.dateFrom,
    this.dateTo,
  });

  /// Free-text search matched against [Appointment.userName] and
  /// [Appointment.displayId] (case-insensitive, trimmed).
  final String query;

  /// Zero or more status values to include (OR logic).
  /// Empty set = no status filter = show all statuses.
  final Set<AppointmentStatus> statuses;

  /// Optional single service-type filter.
  final ServiceType? serviceType;

  /// Inclusive date range start (null = no lower bound).
  final DateTime? dateFrom;

  /// Inclusive date range end (null = no upper bound).
  final DateTime? dateTo;

  // ── Derived ─────────────────────────────────────────────────────────────

  /// True when at least one constraint is active.
  bool get isActive =>
      query.trim().isNotEmpty ||
      statuses.isNotEmpty ||
      serviceType != null ||
      dateFrom != null ||
      dateTo != null;

  /// Count of active filter dimensions (used for badge on filter icon).
  int get activeCount {
    int n = 0;
    if (query.trim().isNotEmpty) n++;
    if (statuses.isNotEmpty) n++;
    if (serviceType != null) n++;
    if (dateFrom != null || dateTo != null) n++;
    return n;
  }

  // ── Mutation helpers (return new instances) ──────────────────────────────

  FilterCriteria withQuery(String q) => copyWith(query: q);

  FilterCriteria withStatuses(Set<AppointmentStatus> s) =>
      copyWith(statuses: s);

  FilterCriteria toggleStatus(AppointmentStatus s) {
    final next = Set<AppointmentStatus>.from(statuses);
    next.contains(s) ? next.remove(s) : next.add(s);
    return copyWith(statuses: next);
  }

  FilterCriteria withServiceType(ServiceType? s) => copyWith(serviceType: s);

  FilterCriteria withDateRange(DateTime? from, DateTime? to) =>
      copyWith(dateFrom: from, dateTo: to);

  FilterCriteria clear() => const FilterCriteria();

  // ── Core ────────────────────────────────────────────────────────────────

  FilterCriteria copyWith({
    String? query,
    Set<AppointmentStatus>? statuses,
    ServiceType? serviceType,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearServiceType = false,
    bool clearDateRange = false,
  }) {
    return FilterCriteria(
      query: query ?? this.query,
      statuses: statuses ?? this.statuses,
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterCriteria &&
          other.query == query &&
          setEquals(other.statuses, statuses) &&
          other.serviceType?.id == serviceType?.id &&
          other.dateFrom == dateFrom &&
          other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(
      query, Object.hashAll(statuses), serviceType?.id, dateFrom, dateTo);

  @override
  String toString() =>
      'FilterCriteria(q:"$query", statuses:${statuses.map((s) => s.name)}, '
      'service:${serviceType?.name}, from:$dateFrom, to:$dateTo)';
}
