import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/task_provider.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';
import 'tasks_screen.dart';
import 'create_task_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  int _selectedIndex = 0;

  List<Widget> _getScreens(bool isAdmin) {
    if (isAdmin) {
      return [
        _buildAdminDashboard(),
        const TasksScreen(isAdmin: true),
        const ProgressScreen(isAdmin: true),
      ];
    } else {
      return [
        const TasksScreen(isAdmin: false),
        const CreateTaskScreen(),
        const ProgressScreen(isAdmin: false),
        const ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(bool isAdmin) {
    if (isAdmin) {
      return const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Tasks'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'My Tasks'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Task'),
        BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Progress'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();

    if (auth.status == app_auth.AuthStatus.unknown) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (auth.status == app_auth.AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = auth.isAdmin;
    final screens = _getScreens(isAdmin);
    final navItems = _getNavItems(isAdmin);

    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
              text: 'Intern',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryIndigo,
              ),
              children: [
                TextSpan(
                  text: ' Job',
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: navItems,
          ),
        ),
      ),
    );
  }

  // ── Admin Dashboard (StreamBuilder for live data) ─────────────
  Widget _buildAdminDashboard() {
    return StreamBuilder<List<Task>>(
      stream: _taskService.getAllTasks(),
      builder: (ctx, taskSnap) {
        final isLoading = taskSnap.connectionState == ConnectionState.waiting;
        final allTasks = taskSnap.data ?? [];

        final pending = allTasks.where((t) => t.status == 'pending').length;
        final inProgress = allTasks.where((t) => t.status == 'in_progress').length;
        final completed = allTasks.where((t) => t.status == 'completed').length;
        final totalTasks = allTasks.length;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _userService.getAllUsers(),
          builder: (ctx2, userSnap) {
            final totalInterns = (userSnap.data ?? [])
                .where((u) => u['role'] == 'intern')
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────
                  Text(
                    'Good to see you 👋',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's your team's live overview.",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),

                  // ── Summary Cards ──────────────────────────────
                  if (isLoading)
                    _buildShimmerCards()
                  else
                    Row(
                      children: [
                        _summaryCard(
                          'Total Interns',
                          '$totalInterns',
                          Icons.people_outline,
                          AppTheme.primaryIndigo,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          'Total Tasks',
                          '$totalTasks',
                          Icons.task_outlined,
                          AppTheme.primaryTeal,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // ── Task Distribution ──────────────────────────
                  Text(
                    'Task Distribution',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    _buildShimmerStatusCards()
                  else
                    Row(
                      children: [
                        _statusCard('Pending', pending, AppTheme.statusPending),
                        const SizedBox(width: 10),
                        _statusCard('In Progress', inProgress, AppTheme.statusInProgress),
                        const SizedBox(width: 10),
                        _statusCard('Completed', completed, AppTheme.statusCompleted),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ──────────────────────────────
                  Text(
                    'Quick Actions',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (innerCtx) {
                    return ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        innerCtx,
                        MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Assign New Task'),
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── Recent Tasks (live stream) ─────────────────
                  Text(
                    'Recent Tasks',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    _buildShimmerList()
                  else if (allTasks.isEmpty)
                    Text('No tasks yet.',
                        style: TextStyle(color: Colors.grey.shade400))
                  else
                    Column(
                      children: allTasks.take(5).map((task) {
                        final color = AppTheme.statusColor(task.status);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (task.assignedToName != null)
                                      Text(
                                        task.assignedToName!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppTheme.statusLabel(task.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerCards() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
              child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)))),
          const SizedBox(width: 12),
          Expanded(
              child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)))),
        ],
      ),
    );
  }

  Widget _buildShimmerStatusCards() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 64,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

}

