import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all tasks for a specific user (intern)
  Stream<List<Task>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all tasks (for admin)
  Stream<List<Task>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create a new task
  Future<void> createTask({
    required String title,
    required String description,
    required DateTime deadline,
    required String assignedTo,
    required String assignedBy,
  }) async {
    Task newTask = Task(
      id: '', // will be set by Firestore
      title: title,
      description: description,
      deadline: deadline,
      status: 'pending',
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('tasks').add(newTask.toMap());
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
    });
  }

  // Update entire task (optional, for admin edit)
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _firestore.collection('tasks').doc(taskId).update(data);
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Get tasks for a specific user as a Future (one-time fetch)
  Future<List<Task>> getTasksForUserFuture(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Get all tasks as a Future (for admin)
  Future<List<Task>> getAllTasksFuture() async {
    QuerySnapshot snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
