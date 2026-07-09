import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  final bool isAdmin;
  const ProgressScreen({super.key, required this.isAdmin});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.isAdmin ? _buildAdminView() : _buildInternView(),
    );
  }

  // ── Intern View (live stream) ──────────────────────────────────
  Widget _buildInternView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasksForUser(user.uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text('Failed to load data',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
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
    final completionRate = total == 0 ? 0.0 : (completed / total * 100);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats Row ────────────────────────────────
                Row(
                  children: [
                    _statCard('Total', total, AppTheme.primaryIndigo),
                    const SizedBox(width: 10),
                    _statCard('Done', completed, AppTheme.statusCompleted),
                    const SizedBox(width: 10),
                    _statCard(
                        'Overdue',
                        tasks.where((t) => t.isOverdue).length,
                        Colors.red.shade400),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Interactive Pie Chart ─────────────────────
                if (total > 0) ...[
                  Text(
                    'Status Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback:
                                          (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedPieIndex = null;
                                            return;
                                          }
                                          _touchedPieIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sections: _buildPieSections(
                                        pending, inProgress, completed),
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 45,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendItem(
                                      'Pending', AppTheme.statusPending, pending),
                                  const SizedBox(height: 12),
                                  _legendItem('In Progress',
                                      AppTheme.statusInProgress, inProgress),
                                  const SizedBox(height: 12),
                                  _legendItem('Completed',
                                      AppTheme.statusCompleted, completed),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap a slice for details',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Animated Completion Rate Bar ───────────────
                  Text(
                    'Completion Rate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${completionRate.toStringAsFixed(0)}% Complete',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$completed / $total tasks',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: completionRate / 100),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (ctx, value, _) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.statusCompleted),
                              minHeight: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Bar Chart: Task Status Distribution ───────
                  Text(
                    'Task Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(pending, inProgress, completed),
                  const SizedBox(height: 24),
                ],

                // ── Task List Header ───────────────────────────
                Text(
                  'Your Tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
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
                    if (task.isOverdue)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Overdue',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700),
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
            },
            childCount: tasks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
      int pending, int inProgress, int completed) {
    final data = [
      (pending, AppTheme.statusPending, 'Pending'),
      (inProgress, AppTheme.statusInProgress, 'In Progress'),
      (completed, AppTheme.statusCompleted, 'Done'),
    ];
    return data.asMap().entries.where((e) => e.value.$1 > 0).map((e) {
      final isTouched = _touchedPieIndex == e.key;
      final radius = isTouched ? 72.0 : 60.0;
      return PieChartSectionData(
        value: e.value.$1.toDouble(),
        color: e.value.$2,
        title: isTouched ? '${e.value.$3}\n${e.value.$1}' : '${e.value.$1}',
        radius: radius,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: isTouched ? 13 : 12,
        ),
        borderSide: isTouched
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      );
    }).toList();
  }

  Widget _buildBarChart(int pending, int inProgress, int completed) {
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: ([pending, inProgress, completed].reduce((a, b) => a > b ? a : b) + 1).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final labels = ['Pending', 'In Progress', 'Done'];
                return BarTooltipItem(
                  '${labels[groupIndex]}\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['Pending', 'In Prog.', 'Done'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (val, meta) => Text(
                  val.toInt().toString(),
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _barGroup(0, pending.toDouble(), AppTheme.statusPending),
            _barGroup(1, inProgress.toDouble(), AppTheme.statusInProgress),
            _barGroup(2, completed.toDouble(), AppTheme.statusCompleted),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y + 1,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ── Admin View (StreamBuilder for live tasks) ─────────────────
  Widget _buildAdminView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userService.getAllUsers(),
      builder: (ctx, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        if (userSnap.hasError) {
          return Center(
            child: Text('Error loading users',
                style: TextStyle(color: Colors.grey.shade500)),
          );
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

        return StreamBuilder<List<Task>>(
          stream: _taskService.getAllTasks(),
          builder: (ctx, taskSnap) {
            if (taskSnap.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }
            if (taskSnap.hasError) {
              return Center(
                child: Text('Error loading tasks',
                    style: TextStyle(color: Colors.grey.shade500)),
              );
            }
            final allTasks = taskSnap.data ?? [];

            final Map<String, Map<String, int>> stats = {};
            for (final intern in interns) {
              final id = intern['id'] as String;
              final tasks = allTasks.where((t) => t.assignedTo == id).toList();
              stats[id] = {
                'total': tasks.length,
                'pending': tasks.where((t) => t.status == 'pending').length,
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
                final pending = s['pending']!;
                final inProg = s['in_progress']!;
                final rate = total == 0 ? 0.0 : done / total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryIndigo.withValues(alpha: 0.1),
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
                        Text('$done/$total done',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: rate),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (ctx, val, _) => LinearProgressIndicator(
                                value: val,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.statusCompleted),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _statCard('Pending', pending,
                                    AppTheme.statusPending),
                                const SizedBox(width: 8),
                                _statCard('In Progress', inProg,
                                    AppTheme.statusInProgress),
                                const SizedBox(width: 8),
                                _statCard('Completed', done,
                                    AppTheme.statusCompleted),
                              ],
                            ),
                            // Mini pie chart per intern
                            if (total > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 100,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      if (pending > 0)
                                        PieChartSectionData(
                                          value: pending.toDouble(),
                                          color: AppTheme.statusPending,
                                          title: '',
                                          radius: 30,
                                        ),
                                      if (inProg > 0)
                                        PieChartSectionData(
                                          value: inProg.toDouble(),
                                          color: AppTheme.statusInProgress,
                                          title: '',
                                          radius: 30,
                                        ),
                                      if (done > 0)
                                        PieChartSectionData(
                                          value: done.toDouble(),
                                          color: AppTheme.statusCompleted,
                                          title: '',
                                          radius: 30,
                                        ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 20,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
