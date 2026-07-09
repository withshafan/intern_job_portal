import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'package:provider/provider.dart';

class ProgressScreen extends StatefulWidget {
  final bool isAdmin;
  const ProgressScreen({super.key, required this.isAdmin});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.isAdmin ? _buildAdminView() : _buildInternView(),
    );
  }

  // ── Intern View ───────────────────────────────────────────────
  Widget _buildInternView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return FutureBuilder<List<Task>>(
      future: _taskService.getTasksForUserFuture(user.uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snap.data ?? [];
        return _buildInternStats(tasks);
      },
    );
  }

  Widget _buildInternStats(List<Task> tasks) {
    final pending = tasks.where((t) => t.status == 'pending').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final completed = tasks.where((t) => t.status == 'completed').length;
    final total = tasks.length;
    final completionRate =
        total == 0 ? 0.0 : (completed / total * 100);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats Row ──────────────────────────────
                Row(
                  children: [
                    _statCard('Total', total, AppTheme.primaryIndigo),
                    const SizedBox(width: 10),
                    _statCard('Done', completed, AppTheme.statusCompleted),
                    const SizedBox(width: 10),
                    _statCard('Overdue',
                        tasks.where((t) => t.isOverdue).length, Colors.red),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Pie Chart ──────────────────────────────
                if (total > 0) ...[
                  Text('Status Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                if (pending > 0)
                                  PieChartSectionData(
                                    value: pending.toDouble(),
                                    color: AppTheme.statusPending,
                                    title: '$pending',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                if (inProgress > 0)
                                  PieChartSectionData(
                                    value: inProgress.toDouble(),
                                    color: AppTheme.statusInProgress,
                                    title: '$inProgress',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                if (completed > 0)
                                  PieChartSectionData(
                                    value: completed.toDouble(),
                                    color: AppTheme.statusCompleted,
                                    title: '$completed',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _legendItem('Pending', AppTheme.statusPending, pending),
                            const SizedBox(height: 10),
                            _legendItem('In Progress', AppTheme.statusInProgress,
                                inProgress),
                            const SizedBox(height: 10),
                            _legendItem('Completed', AppTheme.statusCompleted,
                                completed),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Completion Rate ────────────────────────
                  Text('Completion Rate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: completionRate / 100,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryIndigo,
                                AppTheme.statusCompleted
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${completionRate.toStringAsFixed(0)}% complete',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Task List ──────────────────────────────
                Text('Your Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final task = tasks[i];
              final color = AppTheme.statusColor(task.status);
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
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
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(task.title,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
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
            },
            childCount: tasks.length,
          ),
        ),
      ],
    );
  }

  // ── Admin View ────────────────────────────────────────────────
  Widget _buildAdminView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userService.getAllUsers(),
      builder: (ctx, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final interns = (userSnap.data ?? [])
            .where((u) => u['role'] == 'intern')
            .toList();

        if (interns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No interns yet',
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return FutureBuilder<List<Task>>(
          future: _taskService.getAllTasksFuture(),
          builder: (ctx, taskSnap) {
            if (taskSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allTasks = taskSnap.data ?? [];

            final Map<String, Map<String, int>> stats = {};
            for (final intern in interns) {
              final id = intern['id'] as String;
              final tasks =
                  allTasks.where((t) => t.assignedTo == id).toList();
              stats[id] = {
                'total': tasks.length,
                'pending':
                    tasks.where((t) => t.status == 'pending').length,
                'in_progress':
                    tasks.where((t) => t.status == 'in_progress').length,
                'completed':
                    tasks.where((t) => t.status == 'completed').length,
              };
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: interns.length,
              itemBuilder: (ctx, i) {
                final intern = interns[i];
                final id = intern['id'] as String;
                final name = intern['name'] ?? intern['email'] ?? 'Unknown';
                final s = stats[id]!;
                final total = s['total']!;
                final done = s['completed']!;
                final rate = total == 0 ? 0.0 : done / total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryIndigo.withOpacity(0.1),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryIndigo,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Row(
                      children: [
                        Text('$done/$total tasks done',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rate,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.statusCompleted),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            _statCard(
                                'Pending', s['pending']!, AppTheme.statusPending),
                            const SizedBox(width: 8),
                            _statCard('In Progress', s['in_progress']!,
                                AppTheme.statusInProgress),
                            const SizedBox(width: 8),
                            _statCard('Completed', s['completed']!,
                                AppTheme.statusCompleted),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text(label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
            width: 12, height: 12, color: color,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ($count)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
