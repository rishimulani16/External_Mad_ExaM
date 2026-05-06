import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/domain/booking_error.dart';
import '../../../core/domain/service_type.dart';
import '../../../core/state/appointment_controller.dart';
import '../../../core/state/providers.dart';

/// Booking Form Screen — wired to Riverpod providers.
///
/// Calls [AppointmentController.bookAppointment] and displays typed errors
/// via the [BookingError] sealed class (no string matching needed in UI).
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ServiceType? _selectedService;
  DateTime? _selectedDate;
  int? _selectedHour;   // 0-23
  int? _selectedMinute; // 0 or 30
  bool _isSubmitting = false;

  static const _slots = [
    (label: '09:00 AM', h: 9,  m: 0),
    (label: '09:30 AM', h: 9,  m: 30),
    (label: '10:00 AM', h: 10, m: 0),
    (label: '10:30 AM', h: 10, m: 30),
    (label: '11:00 AM', h: 11, m: 0),
    (label: '11:30 AM', h: 11, m: 30),
    (label: '02:00 PM', h: 14, m: 0),
    (label: '02:30 PM', h: 14, m: 30),
    (label: '03:00 PM', h: 15, m: 0),
    (label: '03:30 PM', h: 15, m: 30),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) { _err('Please select a date.'); return; }
    if (_selectedHour == null)  { _err('Please select a time slot.'); return; }
    if (_selectedService == null) { _err('Please select a service.'); return; }

    final bookingDt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedHour!, _selectedMinute!,
    );

    setState(() => _isSubmitting = true);

    // ── Call the Riverpod controller ──────────────────────────────────────
    final result = ref.read(appointmentListProvider.notifier).bookAppointment(
          userName: _nameController.text.trim(),
          serviceType: _selectedService!,
          dateTime: bookingDt,
        );

    setState(() => _isSubmitting = false);

    // ── Handle typed result ───────────────────────────────────────────────
    switch (result) {
      case BookingSuccess(:final value):
        _showSuccessSheet(value);

      case BookingFailure(:final error):
        // Exhaustive switch — no default needed (sealed class).
        final msg = switch (error) {
          DuplicateBookingError() => error.message,
          SlotFullError()         => error.message,
          PastDateTimeError()     => error.message,
          AppointmentNotFoundError() => error.message,
          EmptyQueueError()       => error.message,
        };
        _err(msg);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSheet(Appointment apt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDEF7EC), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF03543F), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Booking Confirmed!',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(apt.displayId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 4),
            Text('Queue position: #${apt.queuePosition}',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Estimated wait: ${apt.estimatedWaitMinutes} min',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _nameController.clear();
                  setState(() {
                    _selectedService = null;
                    _selectedDate = null;
                    _selectedHour = null;
                  });
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch service list reactively (could be loaded from a remote source later)
    final services = ref.watch(serviceTypeListProvider);

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Patient Details'),
            const SizedBox(height: 10),

            // Name
            TextFormField(
              key: const Key('field_customer_name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            _Label('Service'),
            const SizedBox(height: 10),

            // Service dropdown — reads real Riverpod provider
            DropdownButtonFormField<ServiceType>(
              key: const Key('field_service_type'),
              decoration: const InputDecoration(
                labelText: 'Service Type *',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              value: _selectedService,
              items: services
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.icon}  ${s.name}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
              validator: (v) =>
                  v == null ? 'Please select a service' : null,
            ),

            if (_selectedService != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Duration: ~${_selectedService!.avgDurationMinutes} min  '
                  '·  Max ${_selectedService!.maxCapacityPerSlot} per slot',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ],
            const SizedBox(height: 20),

            _Label('Schedule'),
            const SizedBox(height: 10),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  key: const Key('field_date'),
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    hintText: 'Tap to select',
                  ),
                  controller: TextEditingController(
                    text: _selectedDate == null
                        ? ''
                        : DateFormat('EEE, dd MMM yyyy').format(_selectedDate!),
                  ),
                  validator: (_) =>
                      _selectedDate == null ? 'Please select a date' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time slot chips
            Text('Time Slot *',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: const Color(0xFF374151))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final selected =
                    _selectedHour == slot.h && _selectedMinute == slot.m;
                return ChoiceChip(
                  key: Key('slot_${slot.h}_${slot.m}'),
                  label: Text(slot.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      )),
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (_) =>
                      setState(() {
                        _selectedHour = slot.h;
                        _selectedMinute = slot.m;
                      }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('btn_confirm_booking'),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isSubmitting ? 'Booking…' : 'Book Appointment'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return Column(children: [_BookingHeader(), Expanded(child: body)]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: body,
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _BookingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF1E429F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Book Appointment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Fill in the details below to secure your slot.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.white70)),
        ]),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
            ),
      );
}
