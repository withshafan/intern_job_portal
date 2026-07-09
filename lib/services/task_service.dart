import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Streams ────────────────────────────────────────────────────

  Stream<List<Task>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Task>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromMap(d.data(), d.id)).toList());
  }

  // ── One-time fetches ───────────────────────────────────────────

  Future<List<Task>> getTasksForUserFuture(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .get();
    return snapshot.docs.map((d) => Task.fromMap(d.data(), d.id)).toList();
  }

  Future<List<Task>> getAllTasksFuture() async {
    final snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs.map((d) => Task.fromMap(d.data(), d.id)).toList();
  }

  // ── CRUD ───────────────────────────────────────────────────────

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime deadline,
    required String assignedTo,
    required String assignedBy,
    String? assignedToName,
  }) async {
    final task = Task(
      id: '',
      title: title,
      description: description,
      deadline: deadline,
      status: 'pending',
      assignedTo: assignedTo,
      assignedBy: assignedBy,
      createdAt: DateTime.now(),
      assignedToName: assignedToName,
    );
    await _firestore.collection('tasks').add(task.toMap());
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .update({'status': newStatus});
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _firestore.collection('tasks').doc(taskId).update(data);
  }

  Future<void> deleteTask(String taskId) async {
    // Also delete comments subcollection
    final commentsRef = _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments');
    final comments = await commentsRef.get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // ── Comments ───────────────────────────────────────────────────

  Stream<List<TaskComment>> getComments(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TaskComment.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addComment({
    required String taskId,
    required String text,
    required String authorId,
    required String authorName,
  }) async {
    final comment = TaskComment(
      id: '',
      authorId: authorId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .add(comment.toMap());
  }
}
