/// AppointmentListScreen — tabbed list wired to [filteredAppointmentsProvider].
///
/// Reads [filteredAppointmentsProvider] so any active search/filter from
/// [SearchFilterScreen] is reflected here automatically.
///
/// The tab bar provides a secondary status filter (All / Scheduled / …)
/// applied on top of [filteredAppointmentsProvider]'s output.
///
/// A filter-active banner appears when [filterProvider] has constraints so the
/// user knows they are looking at a filtered subset.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/appointment.dart';
import '../../../core/domain/filter_criteria.dart';
import '../../../common/widgets/appointment_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/state/providers.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key, this.isEmbedded = false});
  final bool isEmbedded;

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState
    extends ConsumerState<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabStatuses = [
    null,                           // All
    AppointmentStatus.scheduled,
    AppointmentStatus.inProgress,
    AppointmentStatus.completed,
    AppointmentStatus.cancelled,
  ];

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Scheduled'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Secondary tab-level status filter applied on top of the global filter.
  List<Appointment> _byTab(List<Appointment> filtered, AppointmentStatus? s) =>
      s == null ? filtered : filtered.where((a) => a.status == s).toList();

  // ── Clear filter action ──────────────────────────────────────────────────

  void _clearFilter() {
    ref.read(filterProvider.notifier).state = const FilterCriteria();
  }

  @override
  Widget build(BuildContext context) {
    // ── READS ───────────────────────────────────────────────────────────────
    // filteredAppointmentsProvider = appointmentListProvider filtered by
    // the current FilterCriteria from filterProvider.
    final filtered  = ref.watch(filteredAppointmentsProvider);
    final criteria  = ref.watch(filterProvider);
    final totalAll  = ref.watch(appointmentListProvider).length;

    final content = Column(
      children: [
        // ── Filter-active banner ────────────────────────────────────────
        if (criteria.isActive)
          _FilterBanner(
            activeCount: criteria.activeCount,
            showing: filtered.length,
            total: totalAll,
            onClear: _clearFilter,
          ),

        // ── Tab bar ─────────────────────────────────────────────────────
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: const Color(0xFF6B7280),
            dividerColor: Colors.grey.shade200,
            tabs: List.generate(_tabs.length, (i) {
              final count = _byTab(filtered, _tabStatuses[i]).length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_tabs[i].text!),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      _TabBadge(count),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),

        // ── Tab views ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabStatuses.map((s) {
              return _AppointmentTab(appointments: _byTab(filtered, s));
            }).toList(),
          ),
        ),
      ],
    );

    // ── Embedded (inside BottomNavigationBar shell) ──────────────────────
    if (widget.isEmbedded) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              key: const Key('fab_new_booking'),
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.routeBooking),
              icon: const Icon(Icons.add),
              label: const Text('New Booking'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          // Filter shortcut → navigate to Search screen
          IconButton(
            key: const Key('btn_open_filter'),
            tooltip: 'Search & Filter',
            icon: Badge(
              isLabelVisible: criteria.isActive,
              label: Text('${criteria.activeCount}'),
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.routeSearch),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_new_booking'),
        onPressed: () =>
            Navigator.pushNamed(context, AppConstants.routeBooking),
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Small inline badge count on each tab label.
class _TabBadge extends StatelessWidget {
  const _TabBadge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
}

/// Banner shown when filterProvider has active constraints.
class _FilterBanner extends StatelessWidget {
  const _FilterBanner({
    required this.activeCount,
    required this.showing,
    required this.total,
    required this.onClear,
  });

  final int activeCount;
  final int showing;
  final int total;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Row(children: [
          Icon(Icons.filter_alt_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing $showing of $total  •  '
              '$activeCount filter${activeCount == 1 ? '' : 's'} active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            key: const Key('btn_clear_list_filter'),
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimaryContainer,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Clear'),
          ),
        ]),
      );
}

class _AppointmentTab extends StatelessWidget {
  const _AppointmentTab({required this.appointments});
  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No appointments here',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => AppointmentCard(
        key: Key('apt_card_${appointments[i].id}'),
        appointment: appointments[i],
        showQueueBadge: true,
        onTap: () {
          // TODO (Milestone 5): Navigate to appointment detail.
        },
      ),
    );
  }
}
