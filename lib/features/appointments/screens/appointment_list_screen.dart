import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/appointment.dart';
import '../../../common/widgets/appointment_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/state/providers.dart';

/// AppointmentListScreen — shows all user appointments with status tabs and FAB.
/// Used as Tab 0 inside HomeScreen shell, and as standalone route.
class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Scheduled'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ];

  List<Appointment> _filtered(List<Appointment> all, AppointmentStatus? status) {
    if (status == null) return all;
    return all.where((a) => a.status == status).toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(appointmentListProvider);
    final content = Column(
      children: [
        // --- Tab bar ---
        Container(
          color: Colors.white,
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
            tabs: _tabs,
          ),
        ),
        // --- Appointment lists per tab ---
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AppointmentTab(appointments: _filtered(all, null)),
              _AppointmentTab(appointments: _filtered(all, AppointmentStatus.scheduled)),
              _AppointmentTab(appointments: _filtered(all, AppointmentStatus.inProgress)),
              _AppointmentTab(appointments: _filtered(all, AppointmentStatus.completed)),
              _AppointmentTab(appointments: _filtered(all, AppointmentStatus.cancelled)),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              key: const Key('fab_new_booking'),
              onPressed: () => Navigator.pushNamed(
                  context, AppConstants.routeBooking),
              icon: const Icon(Icons.add),
              label: const Text('New Booking'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
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
        key: Key('apt_card_$i'),
        appointment: appointments[i],
        showQueueBadge: true,
        onTap: () {
          // TODO (Milestone 3): Navigate to appointment detail / queue status
        },
      ),
    );
  }
}
