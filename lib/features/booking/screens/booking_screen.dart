import 'package:flutter/material.dart';

/// Booking Form Screen — Screen 2 (PRD §4)
///
/// Collects: customer name, service type, date, time slot.
/// Validates: no past dates, no invalid times (PRD §Validation).
/// Generates: unique Appointment ID on submission.
/// Business logic (validation, Hive save, conflict detection) — Milestone 3.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: const _BookingFormPlaceholder(),
    );
  }
}

class _BookingFormPlaceholder extends StatelessWidget {
  const _BookingFormPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Customer Name ---
          TextFormField(
            key: const Key('field_customer_name'),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Rishi Mulani',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // --- Service Type ---
          DropdownButtonFormField<String>(
            key: const Key('field_service_type'),
            decoration: const InputDecoration(
              labelText: 'Service Type',
              prefixIcon: Icon(Icons.miscellaneous_services_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General Consultation')),
              DropdownMenuItem(value: 'followup', child: Text('Follow-up')),
              DropdownMenuItem(value: 'lab', child: Text('Lab Test')),
            ],
            onChanged: (_) {
              // TODO (Milestone 3): Update Riverpod provider
            },
          ),
          const SizedBox(height: 16),

          // --- Date Picker ---
          TextFormField(
            key: const Key('field_date'),
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date',
              hintText: 'Select a date',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: () async {
              // TODO (Milestone 3): Show DatePicker, validate no past dates
            },
          ),
          const SizedBox(height: 16),

          // --- Time Slot ---
          DropdownButtonFormField<String>(
            key: const Key('field_time_slot'),
            decoration: const InputDecoration(
              labelText: 'Time Slot',
              prefixIcon: Icon(Icons.access_time_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '09:00', child: Text('09:00 AM – 09:30 AM')),
              DropdownMenuItem(value: '09:30', child: Text('09:30 AM – 10:00 AM')),
              DropdownMenuItem(value: '10:00', child: Text('10:00 AM – 10:30 AM')),
            ],
            onChanged: (_) {
              // TODO (Milestone 3): Check slot availability via provider
            },
          ),
          const SizedBox(height: 32),

          // --- Submit ---
          FilledButton.icon(
            key: const Key('btn_confirm_booking'),
            onPressed: () {
              // TODO (Milestone 3): Trigger BookingNotifier.createAppointment()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('[Placeholder] Booking logic coming in Milestone 3')),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Booking'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
