import '../models/appointment_model.dart';

/// Static mock data used by all UI screens while real providers are being built.
/// Replace references to MockData with Riverpod providers in Milestone 3.
abstract final class MockData {
  // ---------------------------------------------------------------------------
  // Service Types (PRD §5.2)
  // ---------------------------------------------------------------------------
  static const List<ServiceType> serviceTypes = [
    ServiceType(
      id: 'svc_general',
      name: 'General Consultation',
      icon: '🩺',
      avgDurationMinutes: 30,
      maxCapacityPerSlot: 5,
    ),
    ServiceType(
      id: 'svc_followup',
      name: 'Follow-up Visit',
      icon: '🔁',
      avgDurationMinutes: 20,
      maxCapacityPerSlot: 6,
    ),
    ServiceType(
      id: 'svc_lab',
      name: 'Lab Test',
      icon: '🧪',
      avgDurationMinutes: 15,
      maxCapacityPerSlot: 8,
    ),
    ServiceType(
      id: 'svc_vaccine',
      name: 'Vaccination',
      icon: '💉',
      avgDurationMinutes: 10,
      maxCapacityPerSlot: 10,
    ),
    ServiceType(
      id: 'svc_dental',
      name: 'Dental Checkup',
      icon: '🦷',
      avgDurationMinutes: 45,
      maxCapacityPerSlot: 3,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Available Time Slots
  // ---------------------------------------------------------------------------
  static const List<String> timeSlots = [
    '09:00 AM – 09:30 AM',
    '09:30 AM – 10:00 AM',
    '10:00 AM – 10:30 AM',
    '10:30 AM – 11:00 AM',
    '11:00 AM – 11:30 AM',
    '11:30 AM – 12:00 PM',
    '02:00 PM – 02:30 PM',
    '02:30 PM – 03:00 PM',
    '03:00 PM – 03:30 PM',
    '03:30 PM – 04:00 PM',
  ];

  // ---------------------------------------------------------------------------
  // Mock Appointments  (PRD §5.1)
  // ---------------------------------------------------------------------------
  static final List<AppointmentModel> appointments = [
    AppointmentModel(
      id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      customerName: 'Rishi Mulani',
      serviceType: serviceTypes[0],
      date: DateTime.now(),
      timeSlot: '10:00 AM – 10:30 AM',
      status: AppointmentStatus.inProgress,
      queuePosition: 1,
      estimatedWaitMinutes: 0,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppointmentModel(
      id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
      customerName: 'Priya Sharma',
      serviceType: serviceTypes[2],
      date: DateTime.now(),
      timeSlot: '10:30 AM – 11:00 AM',
      status: AppointmentStatus.scheduled,
      queuePosition: 2,
      estimatedWaitMinutes: 15,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    AppointmentModel(
      id: 'c3d4e5f6-a7b8-9012-cdef-123456789012',
      customerName: 'Arjun Patel',
      serviceType: serviceTypes[1],
      date: DateTime.now(),
      timeSlot: '11:00 AM – 11:30 AM',
      status: AppointmentStatus.scheduled,
      queuePosition: 3,
      estimatedWaitMinutes: 30,
      isSynced: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppointmentModel(
      id: 'd4e5f6a7-b8c9-0123-defa-234567890123',
      customerName: 'Sneha Joshi',
      serviceType: serviceTypes[3],
      date: DateTime.now(),
      timeSlot: '11:30 AM – 12:00 PM',
      status: AppointmentStatus.scheduled,
      queuePosition: 4,
      estimatedWaitMinutes: 45,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    AppointmentModel(
      id: 'e5f6a7b8-c9d0-1234-efab-345678901234',
      customerName: 'Rahul Desai',
      serviceType: serviceTypes[4],
      date: DateTime.now().subtract(const Duration(days: 1)),
      timeSlot: '09:00 AM – 09:45 AM',
      status: AppointmentStatus.completed,
      queuePosition: 1,
      estimatedWaitMinutes: 0,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    AppointmentModel(
      id: 'f6a7b8c9-d0e1-2345-fabc-456789012345',
      customerName: 'Kavya Nair',
      serviceType: serviceTypes[0],
      date: DateTime.now().subtract(const Duration(days: 1)),
      timeSlot: '10:00 AM – 10:30 AM',
      status: AppointmentStatus.completed,
      queuePosition: 2,
      estimatedWaitMinutes: 0,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    AppointmentModel(
      id: 'a7b8c9d0-e1f2-3456-abcd-567890123456',
      customerName: 'Vikram Singh',
      serviceType: serviceTypes[1],
      date: DateTime.now().subtract(const Duration(days: 2)),
      timeSlot: '02:00 PM – 02:30 PM',
      status: AppointmentStatus.cancelled,
      queuePosition: 0,
      estimatedWaitMinutes: 0,
      isSynced: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    AppointmentModel(
      id: 'b8c9d0e1-f2a3-4567-bcde-678901234567',
      customerName: 'Meera Reddy',
      serviceType: serviceTypes[2],
      date: DateTime.now().subtract(const Duration(days: 3)),
      timeSlot: '03:00 PM – 03:15 PM',
      status: AppointmentStatus.cancelled,
      queuePosition: 0,
      estimatedWaitMinutes: 0,
      isSynced: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Queue Simulation (PRD §6.2)
  // Current token being served, user's token info
  // ---------------------------------------------------------------------------
  static const int currentServingToken = 12;
  static const int myQueueToken = 15;
  static const int myQueuePosition = 3;
  static const int estimatedWaitMinutes = 30;

  /// Appointments still pending (for admin queue view)
  static List<AppointmentModel> get pendingAppointments =>
      appointments.where((a) => a.status == AppointmentStatus.scheduled).toList();

  /// Currently active appointment (for admin control)
  static AppointmentModel get activeAppointment =>
      appointments.firstWhere((a) => a.status == AppointmentStatus.inProgress);
}
