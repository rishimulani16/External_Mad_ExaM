/// Search & Filter Screen — wired to [filterProvider] and
/// [filteredAppointmentsProvider].
///
/// This screen WRITES filter state to [filterProvider] and READS results from
/// [filteredAppointmentsProvider]. The same results are visible from
/// [AppointmentListScreen] which also watches [filteredAppointmentsProvider].
///
/// Local widget state is used only for:
///   - The [TextField] controller (UI concern, not business state).
///   - Debounce timer for query updates.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/domain/filter_criteria.dart';
import '../../../core/domain/service_type.dart';
import '../../../core/state/providers.dart';
import '../../../common/widgets/appointment_card.dart';

// ── Screen shell ──────────────────────────────────────────────────────────────

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

// Alias used in home_screen.dart / any embedded reference.
typedef SearchFilterScreen = SearchScreen;

// ── Body ──────────────────────────────────────────────────────────────────────

class _SearchBody extends ConsumerStatefulWidget {
  const _SearchBody();
  @override
  ConsumerState<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends ConsumerState<_SearchBody> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Sync the text field with any pre-existing filterProvider query.
    final existing = ref.read(filterProvider).query;
    if (existing.isNotEmpty) _queryCtrl.text = existing;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  // ── Writes to filterProvider ─────────────────────────────────────────────

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final c = ref.read(filterProvider);
      ref.read(filterProvider.notifier).state = c.withQuery(v);
    });
  }

  void _toggleStatus(AppointmentStatus s) {
    final c = ref.read(filterProvider);
    ref.read(filterProvider.notifier).state = c.toggleStatus(s);
  }

  void _setService(ServiceType? s) {
    final c = ref.read(filterProvider);
    ref.read(filterProvider.notifier).state =
        c.copyWith(clearServiceType: s == null, serviceType: s);
  }

  Future<void> _pickDateRange() async {
    final c = ref.read(filterProvider);
    final init = (c.dateFrom != null && c.dateTo != null)
        ? DateTimeRange(start: c.dateFrom!, end: c.dateTo!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: init,
      helpText: 'Filter by date range',
    );

    if (picked != null) {
      ref.read(filterProvider.notifier).state =
          c.withDateRange(picked.start, picked.end);
    }
  }

  void _clearAll() {
    _queryCtrl.clear();
    ref.read(filterProvider.notifier).state = const FilterCriteria();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // READS — reactive watches
    final criteria = ref.watch(filterProvider);
    final results  = ref.watch(filteredAppointmentsProvider);
    final total    = ref.watch(appointmentListProvider).length;
    final services = ref.watch(serviceTypeListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter Panel ─────────────────────────────────────────────────
        Material(
          elevation: 2,
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Query field ─────────────────────────────────────────
                TextField(
                  key: const Key('field_search_query'),
                  controller: _queryCtrl,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or service…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: criteria.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _queryCtrl.clear();
                              ref.read(filterProvider.notifier).state =
                                  ref.read(filterProvider).withQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Status chips ────────────────────────────────────────
                _SectionLabel('Status'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: AppointmentStatus.values.map((s) {
                    final on = criteria.statuses.contains(s);
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
                      onSelected: (_) => _toggleStatus(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // ── Service type + date range row ───────────────────────
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: DropdownButtonFormField<ServiceType?>(
                      key: const Key('field_service_filter'),
                      // Match by id so reference equality is not required.
                      value: services.cast<ServiceType?>().firstWhere(
                            (s) => s?.id == criteria.serviceType?.id,
                            orElse: () => null,
                          ),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Service',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Services')),
                        ...services.map((s) => DropdownMenuItem(
                            value: s, child: Text(s.name))),
                      ],
                      onChanged: _setService,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Override global minimumSize so button fits next to dropdown.
                  OutlinedButton.icon(
                    key: const Key('btn_date_range'),
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined, size: 16),
                    label: Text(
                      criteria.dateFrom == null
                          ? 'Dates'
                          : '${DateFormat('dd MMM').format(criteria.dateFrom!)}'
                              ' – ${DateFormat('dd MMM').format(criteria.dateTo!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      // CRITICAL: override the global minimumSize(∞ width)
                      // so this button doesn't force full-row width.
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ]),

                // ── Clear button ────────────────────────────────────────
                if (criteria.isActive) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('btn_clear_filters'),
                      onPressed: _clearAll,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: Text(
                        'Clear ${criteria.activeCount} filter'
                        '${criteria.activeCount == 1 ? '' : 's'}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Results header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text('Results',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            _CountBadge(results.length),
            const Spacer(),
            Text(
              '$total total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline),
            ),
          ]),
        ),

        // ── Results list ─────────────────────────────────────────────────
        Expanded(
          child: results.isEmpty
              ? _EmptyState(hasFilters: criteria.isActive)
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
                      // TODO (Milestone 5): Navigate to appointment detail.
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});
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
                  ? 'No appointments match your filters.\nTry clearing a filter.'
                  : 'Start typing to search appointments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ]),
        ),
      );
}
