/// Search & Filter Screen — fully wired to Riverpod.
///
/// Reads [appointmentListProvider] and applies in-memory filtering.
/// No Hive / Firestore queries yet — all filtering is client-side.
/// Milestone 4: replace filter logic with a search provider backed by Hive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/domain/service_type.dart';
import '../../../core/state/providers.dart';
import '../../../common/widgets/appointment_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen (standalone route + embedded tab)
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    if (isEmbedded) return const _SearchBody();

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: const _SearchBody(),
    );
  }
}

// Also export the alias used in home_screen.dart as an embedded tab.
typedef SearchFilterScreen = SearchScreen;

// ─────────────────────────────────────────────────────────────────────────────
// Body — ConsumerStatefulWidget so we own local filter state
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBody extends ConsumerStatefulWidget {
  const _SearchBody();

  @override
  ConsumerState<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends ConsumerState<_SearchBody> {
  final _searchCtrl = TextEditingController();

  // ── Filter state ────────────────────────────────────────────────────────────
  String _query = '';
  final Set<AppointmentStatus> _statusFilters = {};
  ServiceType? _serviceFilter;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── In-memory filter ────────────────────────────────────────────────────────

  List<Appointment> _applyFilters(List<Appointment> all) {
    return all.where((a) {
      // Name / ID search
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          a.userName.toLowerCase().contains(q) ||
          a.displayId.toLowerCase().contains(q);

      // Status chips
      final matchesStatus =
          _statusFilters.isEmpty || _statusFilters.contains(a.status);

      // Service type dropdown
      final matchesService =
          _serviceFilter == null || a.serviceType.id == _serviceFilter!.id;

      // Date range
      final matchesDate = _dateRange == null ||
          (!a.dateTime.isBefore(_dateRange!.start) &&
              !a.dateTime.isAfter(
                  _dateRange!.end.add(const Duration(days: 1))));

      return matchesQuery && matchesStatus && matchesService && matchesDate;
    }).toList();
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _statusFilters.clear();
      _serviceFilter = null;
      _dateRange = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: _dateRange,
      helpText: 'Filter by date range',
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Read live data from appointmentListProvider ──────────────────────────
    final all = ref.watch(appointmentListProvider);           // reactive
    final services = ref.watch(serviceTypeListProvider);      // static catalog
    final results = _applyFilters(all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter Panel ─────────────────────────────────────────────────────
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  key: const Key('field_search_query'),
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or Appointment ID…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Status filter chips
                _FilterLabel('Status'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: AppointmentStatus.values.map((s) {
                    final on = _statusFilters.contains(s);
                    return FilterChip(
                      key: Key('chip_${s.name}'),
                      label: Text(s.displayName,
                          style: const TextStyle(fontSize: 12)),
                      selected: on,
                      showCheckmark: false,
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      side: BorderSide(
                        color: on
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                      onSelected: (_) => setState(() {
                        on
                            ? _statusFilters.remove(s)
                            : _statusFilters.add(s);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Service type + date range row
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<ServiceType?>(
                      key: const Key('field_service_filter'),
                      value: _serviceFilter,
                      decoration: const InputDecoration(
                        labelText: 'Service',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Services')),
                        ...services.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.name))),
                      ],
                      onChanged: (v) => setState(() => _serviceFilter = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    key: const Key('btn_date_range'),
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined, size: 16),
                    label: Text(
                      _dateRange == null
                          ? 'Dates'
                          : '${DateFormat('dd MMM').format(_dateRange!.start)}'
                              ' – ${DateFormat('dd MMM').format(_dateRange!.end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12)),
                  ),
                ]),
                const SizedBox(height: 10),

                // Clear filters
                if (_statusFilters.isNotEmpty ||
                    _serviceFilter != null ||
                    _dateRange != null ||
                    _query.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('btn_clear_filters'),
                      onPressed: _clearAll,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: const Text('Clear Filters'),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Results Header ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text('Results',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${results.length}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const Spacer(),
            Text(
              '${all.length} total',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ]),
        ),

        // ── Results List ─────────────────────────────────────────────────────
        Expanded(
          child: results.isEmpty
              ? _EmptyResults(hasFilters: _query.isNotEmpty ||
                    _statusFilters.isNotEmpty ||
                    _serviceFilter != null ||
                    _dateRange != null)
              : ListView.separated(
                  key: const Key('list_search_results'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => AppointmentCard(
                    key: Key('result_card_${results[i].id}'),
                    appointment: results[i],
                    showQueueBadge: true,
                    onTap: () {
                      // TODO (Milestone 4): Navigate to appointment detail
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
            ),
      );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              hasFilters
                  ? Icons.filter_alt_off_outlined
                  : Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No appointments match your filters.'
                  : 'Start typing to search appointments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ]),
        ),
      );
}
