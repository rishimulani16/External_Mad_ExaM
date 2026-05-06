import 'package:flutter/material.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/queue/screens/queue_tracker_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_queue_control_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../constants/app_constants.dart';

/// Centralised named-route factory.
/// Add new routes here — no routing logic lives outside this file.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeHome:
        return _build(const HomeScreen());

      case AppConstants.routeBooking:
        return _build(const BookingScreen());

      case AppConstants.routeQueue:
        return _build(const QueueTrackerScreen());

      case AppConstants.routeAdminDashboard:
        return _build(const AdminDashboardScreen());

      case AppConstants.routeAdminQueueControl:
        return _build(const AdminQueueControlScreen());

      case AppConstants.routeSearch:
        return _build(const SearchScreen());

      default:
        return _build(
          Scaffold(
            body: Center(
              child: Text('No route defined for "${settings.name}"'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _build(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
