import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/tenant_search_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/teacher_dashboard_screen.dart';
import '../../features/dashboard/presentation/parent_dashboard_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/assignments/presentation/assignments_screen.dart';
import '../../features/assignments/presentation/assignment_detail_screen.dart';
import '../../features/grades/presentation/grades_list_screen.dart';
import '../../features/grades/presentation/grade_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/report_cards/presentation/report_cards_list_screen.dart';
import '../../features/report_cards/presentation/report_card_detail_screen.dart';
import '../../features/announcements/presentation/announcements_list_screen.dart';
import '../../features/announcements/presentation/announcement_detail_screen.dart';
import '../../shared/widgets/floz_bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch user ID. When it changes, this creates a BRAND NEW GoRouter instance,
  // completely wiping any StatefulShellRoute navigation history.
  // ignore: unused_local_variable
  final userId = ref.watch(authProvider.select((s) => s.user?.id));

  final listenable = ValueNotifier<bool>(false);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.tenant != next.tenant ||
        previous?.isLoading != next.isLoading) {
      listenable.value = !listenable.value;
    }
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isLoggingIn = state.uri.toString() == '/login';
      final isSearchingTenant = state.uri.toString() == '/tenant-search';
      final isSplash = state.uri.toString() == '/';

      // If loading, show splash
      if (authState.isLoading && isSplash) return null;

      // If no tenant selected, go to tenant search
      if (authState.tenant == null) {
        return isSearchingTenant ? null : '/tenant-search';
      }

      // If tenant selected but not authenticated
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // If authenticated, go to dashboard (if currently on login/search/splash)
      if (isLoggingIn || isSearchingTenant || isSplash) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/tenant-search',
        builder: (context, state) => const TenantSearchScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FlozBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home (Dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) {
                  final user = ref.read(authProvider).user;
                  if (user?.isStudent ?? false) {
                    return const StudentDashboardScreen();
                  }
                  if (user?.isTeacher ?? false) {
                    return const TeacherDashboardScreen();
                  }
                  if (user?.isParent ?? false) {
                    return const ParentDashboardScreen();
                  }
                  return const Scaffold(
                    body: Center(child: Text('Unknown Role')),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'announcements',
                    builder: (context, state) =>
                        const AnnouncementsListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return AnnouncementDetailScreen(id: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Schedule
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          // Branch 3: Assignments
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assignments',
                builder: (context, state) => const AssignmentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return AssignmentDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Grades
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/grades',
                builder: (context, state) => const GradesListScreen(),
                routes: [
                  GoRoute(
                    path: ':subjectId',
                    builder: (context, state) {
                      final subjectId = int.parse(
                        state.pathParameters['subjectId']!,
                      );
                      return GradeDetailScreen(subjectId: subjectId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 5: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'report-cards',
                    builder: (context, state) => const ReportCardsListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          return ReportCardDetailScreen(id: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
