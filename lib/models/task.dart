class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String status; // 'pending', 'in_progress', 'completed'
  final String assignedTo; // user id of the intern
  final String assignedBy; // user id of the admin
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.assignedTo,
    required this.assignedBy,
    required this.createdAt,
  });

  // From Firestore
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'status': status,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'createdAt': createdAt,
    };
  }
}
