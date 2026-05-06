import 'package:flutter/material.dart';

/// Search & Filter Screen — Screen 6 (PRD §4 / Functional: Search & Filter)
///
/// Supports searching by customer name or Appointment ID.
/// Filter chips for: status (Scheduled / In Progress / Completed / Cancelled),
/// service type, and date range.
/// Search provider and Hive/Firestore queries — Milestone 3.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: const _SearchPlaceholder(),
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  static const _statuses = [
    'Scheduled',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Search Bar ---
          SearchBar(
            key: const Key('field_search_query'),
            hintText: 'Search by name or Appointment ID…',
            leading: const Icon(Icons.search),
            onChanged: (_) {
              // TODO (Milestone 3): Debounce and trigger search provider
            },
          ),
          const SizedBox(height: 16),

          // --- Status Filter Chips ---
          Text('Filter by Status',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _statuses
                .map((s) => FilterChip(
                      key: Key('chip_status_$s'),
                      label: Text(s),
                      selected: false,
                      onSelected: (_) {
                        // TODO (Milestone 3): Update filter provider state
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // --- Date Range Filter ---
          OutlinedButton.icon(
            key: const Key('btn_date_range'),
            onPressed: () {
              // TODO (Milestone 3): showDateRangePicker and update provider
            },
            icon: const Icon(Icons.date_range_outlined),
            label: const Text('Select Date Range'),
          ),
          const SizedBox(height: 24),

          // --- Results Placeholder ---
          Text('Results', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                'Search results will appear here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
