// lib/core/routes/app_routes.dart

import 'package:go_router/go_router.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/teams/team_list_screen.dart';
import '../../screens/teams/create_team_screen.dart';
import '../../screens/teams/team_detail_screen.dart';

import '../../screens/projects/project_list_screen.dart';
import '../../screens/projects/create_project_screen.dart';
import '../../screens/projects/project_detail_screen.dart';
import '../../screens/projects/edit_project_screen.dart'; 
import '../../screens/tasks/create_task_screen.dart';
import '../../screens/tasks/task_detail_screen.dart';


class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Team routes
      GoRoute(
        path: '/teams',
        builder: (context, state) => const TeamListScreen(),
      ),

      GoRoute(
        path: '/create_team',
        builder: (context, state) => const CreateTeamScreen(),
      ),

      GoRoute(
        path: '/team_detail/:teamId',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return TeamDetailScreen(teamId: teamId);
        },
        routes: [
          GoRoute(
            path: 'projects', 
            builder: (context, state) {
              final teamId = state.pathParameters['teamId']!;
              return ProjectListScreen(teamId: teamId);
            },
            routes: [
              GoRoute(
                path: 'create', 
                builder: (context, state) {
                  final teamId = state.pathParameters['teamId']!;
                  return CreateProjectScreen(teamId: teamId);
                },
              ),
            ],
          ),
        ],
      ),

      // Join team by link route
      GoRoute(
        path: '/join-team/:teamId',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId']!;
          return TeamDetailScreen(teamId: teamId);
        },
      ),

      // --- Project & Task Routes ---
      GoRoute(
        path: '/projects/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectDetailScreen(projectId: projectId);
        },
        routes: [
          GoRoute(
            path: 'edit', // Đường dẫn sẽ là /projects/:projectId/edit
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return EditProjectScreen(projectId: projectId);
            },
          ),
          // -----------------------------
          GoRoute(
            path: 'tasks/create', // Đường dẫn sẽ là /projects/:projectId/tasks/create
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return CreateTaskScreen(projectId: projectId);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
    ],
  );
}