import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                color: Colors.black.withOpacity(0.07),
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

  // ── Admin Dashboard ──────────────────────────────────────────
  Widget _buildAdminDashboard() {
    return FutureBuilder<Map<String, int>>(
      future: _getAdminStats(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snap.data ?? {};
        final totalInterns = stats['totalInterns'] ?? 0;
        final totalTasks = stats['totalTasks'] ?? 0;
        final pending = stats['pending'] ?? 0;
        final inProgress = stats['inProgress'] ?? 0;
        final completed = stats['completed'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good to see you 👋',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your team's overview.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),

              // ── Summary Cards ──────────────────────────────
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

              Text(
                'Task Distribution',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _statusCard('Pending', pending, AppTheme.statusPending),
                  const SizedBox(width: 10),
                  _statusCard('In Progress', inProgress,
                      AppTheme.statusInProgress),
                  const SizedBox(width: 10),
                  _statusCard('Completed', completed, AppTheme.statusCompleted),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Tasks ──────────────────────────────
              Text(
                'Recent Tasks',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<Task>>(
                stream: _taskService.getAllTasks(),
                builder: (ctx, taskSnap) {
                  if (!taskSnap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final tasks = taskSnap.data!.take(5).toList();
                  if (tasks.isEmpty) {
                    return Text('No tasks yet.',
                        style: TextStyle(color: Colors.grey.shade400));
                  }
                  return Column(
                    children: tasks.map((task) {
                      final color = AppTheme.statusColor(task.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
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
                                color: color.withOpacity(0.12),
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
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
                        color: Colors.white.withOpacity(0.85),
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
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

  Future<Map<String, int>> _getAdminStats() async {
    final allTasks = await _taskService.getAllTasksFuture();
    final allUsers = await _userService.getAllUsers();
    return {
      'totalInterns':
          allUsers.where((u) => u['role'] == 'intern').length,
      'totalTasks': allTasks.length,
      'pending': allTasks.where((t) => t.status == 'pending').length,
      'inProgress':
          allTasks.where((t) => t.status == 'in_progress').length,
      'completed': allTasks.where((t) => t.status == 'completed').length,
    };
  }
}
