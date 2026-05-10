import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/cows/cow_list_page.dart';
import '../features/farms/farm_dashboard_page.dart';
import '../features/farms/farm_list_page.dart';
import '../features/sessions/session_detail_page.dart';
import '../features/sessions/session_list_page.dart';
import '../features/visits/cow_visit_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: '/farms',
        builder: (context, state) => const FarmListPage(),
      ),
      GoRoute(
        path: '/farms/:farmId',
        builder: (context, state) => FarmDashboardPage(
          farmId: state.pathParameters['farmId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/farms/:farmId/cows',
        builder: (context, state) => CowListPage(
          farmId: state.pathParameters['farmId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/farms/:farmId/sessions',
        builder: (context, state) => SessionListPage(
          farmId: state.pathParameters['farmId'] ?? '',
          farmName: state.uri.queryParameters['farmName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/farms/:farmId/sessions/:sessionId',
        builder: (context, state) => SessionDetailPage(
          farmId: state.pathParameters['farmId'] ?? '',
          sessionId: state.pathParameters['sessionId'] ?? '',
          sessionType: state.uri.queryParameters['type'] ?? '',
          farmName: state.uri.queryParameters['farmName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/farms/:farmId/visits/new',
        builder: (context, state) => CowVisitPage(
          farmId: state.pathParameters['farmId'] ?? '',
          sessionId: state.uri.queryParameters['sessionId'],
          sessionType: state.uri.queryParameters['sessionType'],
          cowNumber: state.uri.queryParameters['cowNumber'],
          isEditing: state.uri.queryParameters['mode'] == 'edit',
        ),
      ),
    ],
  );
});
