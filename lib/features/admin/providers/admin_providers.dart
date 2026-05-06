// Admin feature providers — Milestone 3 placeholder.
//
// In Milestone 3, replace this file with:
//   - adminAppointmentListProvider (StreamProvider<List<Appointment>>)
//   - selectedAppointmentProvider  (StateProvider<Appointment?>)
//   - adminQueueNotifierProvider   (StateNotifierProvider<AdminQueueNotifier, ...>)
//
// AdminQueueNotifier will expose:
//   - markInProgress(String appointmentId)
//   - markCompleted(String appointmentId)
//   - cancelAppointment(String appointmentId)
//   - reschedule(String appointmentId, DateTime newDate, String newSlot)
