import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

enum TaskSortOrder { deadlineAsc, deadlineDesc }

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _allTasks = [];
  String _statusFilter = 'all'; // 'all', 'pending', 'in_progress', 'completed'
  TaskSortOrder _sortOrder = TaskSortOrder.deadlineAsc;

  String get statusFilter => _statusFilter;
  TaskSortOrder get sortOrder => _sortOrder;

  List<Task> get filteredTasks {
    List<Task> tasks = List.from(_allTasks);

    // Filter
    if (_statusFilter != 'all') {
      tasks = tasks.where((t) => t.status == _statusFilter).toList();
    }

    // Sort
    tasks.sort((a, b) => _sortOrder == TaskSortOrder.deadlineAsc
        ? a.deadline.compareTo(b.deadline)
        : b.deadline.compareTo(a.deadline));

    return tasks;
  }

  void setFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void toggleSort() {
    _sortOrder = _sortOrder == TaskSortOrder.deadlineAsc
        ? TaskSortOrder.deadlineDesc
        : TaskSortOrder.deadlineAsc;
    notifyListeners();
  }

  void updateTasks(List<Task> tasks) {
    bool hasChanges = false;
    if (_allTasks.length != tasks.length) {
      hasChanges = true;
    } else {
      for (int i = 0; i < tasks.length; i++) {
        if (_allTasks[i].id != tasks[i].id || 
            _allTasks[i].status != tasks[i].status || 
            _allTasks[i].deadline != tasks[i].deadline) {
          hasChanges = true;
          break;
        }
      }
    }

    if (hasChanges) {
      _allTasks = tasks;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    await _taskService.updateTaskStatus(taskId, newStatus);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }
}
