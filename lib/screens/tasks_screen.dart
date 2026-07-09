import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  final bool isAdmin;
  const TasksScreen({super.key, required this.isAdmin});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  late Stream<List<Task>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (widget.isAdmin) {
      _tasksStream = _taskService.getAllTasks();
    } else {
      _tasksStream = _taskService.getTasksForUser(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'All Tasks' : 'My Tasks'),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks found.'));
          }
          List<Task> tasks = snapshot.data!;
          return ListView.builder(
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      const SizedBox(height: 4),
                      Text(
                        'Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      task.status.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'update_status') {
                        _showUpdateStatusDialog(context, task);
                      } else if (value == 'delete') {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _taskService.deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'update_status',
                        child: Text('Update Status'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTaskScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Task task) {
    String selectedStatus = task.status;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: DropdownButton<String>(
          value: selectedStatus,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
          ],
          onChanged: (value) {
            if (value != null) selectedStatus = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _taskService.updateTaskStatus(task.id, selectedStatus);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
