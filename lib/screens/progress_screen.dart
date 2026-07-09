import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/task.dart';

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
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Intern Reports' : 'My Progress'),
      ),
      body: widget.isAdmin ? _buildAdminView() : _buildInternView(),
    );
  }

  // ---------- Intern View ----------
  Widget _buildInternView() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return FutureBuilder<List<Task>>(
      future: _taskService.getTasksForUserFuture(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        List<Task> tasks = snapshot.data ?? [];
        return _buildInternStats(tasks);
      },
    );
  }

  Widget _buildInternStats(List<Task> tasks) {
    int pending = tasks.where((t) => t.status == 'pending').length;
    int inProgress = tasks.where((t) => t.status == 'in_progress').length;
    int completed = tasks.where((t) => t.status == 'completed').length;
    int total = tasks.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          Row(
            children: [
              _statCard('Total', total, Colors.blue),
              _statCard('Pending', pending, Colors.orange),
              _statCard('In Progress', inProgress, Colors.orange.shade700),
              _statCard('Completed', completed, Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                Task task = tasks[index];
                Color statusColor;
                switch (task.status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    break;
                  case 'in_progress':
                    statusColor = Colors.blue;
                    break;
                  case 'completed':
                    statusColor = Colors.green;
                    break;
                  default:
                    statusColor = Colors.grey;
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: Text(
                        task.status.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(task.title),
                    subtitle: Text(
                      'Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: Text(task.status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Admin View ----------
  Widget _buildAdminView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userService.getAllUsers(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }
        List<Map<String, dynamic>> allUsers = userSnapshot.data ?? [];
        // Filter only interns
        List<Map<String, dynamic>> interns =
            allUsers.where((u) => u['role'] == 'intern').toList();

        if (interns.isEmpty) {
          return const Center(child: Text('No interns found.'));
        }

        return FutureBuilder<List<Task>>(
          future: _taskService.getAllTasksFuture(),
          builder: (context, taskSnapshot) {
            if (taskSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (taskSnapshot.hasError) {
              return Center(child: Text('Error: ${taskSnapshot.error}'));
            }
            List<Task> allTasks = taskSnapshot.data ?? [];

            // Build a map: internId -> task counts
            Map<String, Map<String, int>> internStats = {};
            for (var intern in interns) {
              String id = intern['id'];
              internStats[id] = {
                'total': 0,
                'pending': 0,
                'in_progress': 0,
                'completed': 0,
              };
            }
            for (var task in allTasks) {
              String assignedTo = task.assignedTo;
              if (internStats.containsKey(assignedTo)) {
                internStats[assignedTo]!['total'] =
                    (internStats[assignedTo]!['total'] ?? 0) + 1;
                if (task.status == 'pending')
                  internStats[assignedTo]!['pending'] =
                      (internStats[assignedTo]!['pending'] ?? 0) + 1;
                else if (task.status == 'in_progress')
                  internStats[assignedTo]!['in_progress'] =
                      (internStats[assignedTo]!['in_progress'] ?? 0) + 1;
                else if (task.status == 'completed')
                  internStats[assignedTo]!['completed'] =
                      (internStats[assignedTo]!['completed'] ?? 0) + 1;
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: interns.length,
              itemBuilder: (context, index) {
                var intern = interns[index];
                String id = intern['id'];
                String name = intern['name'] ?? intern['email'] ?? 'Unknown';
                var stats = internStats[id] ?? {
                  'total': 0,
                  'pending': 0,
                  'in_progress': 0,
                  'completed': 0,
                };
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text('Total tasks: ${stats['total']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCard('Pending', stats['pending'] ?? 0, Colors.orange),
                            _statCard('In Progress', stats['in_progress'] ?? 0, Colors.blue),
                            _statCard('Completed', stats['completed'] ?? 0, Colors.green),
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
}
