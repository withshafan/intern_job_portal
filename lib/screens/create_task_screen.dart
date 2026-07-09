import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  String? _assignedTo; // for admin only
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  bool _isAdmin = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    String? role = await _userService.getCurrentUserRole();
    setState(() {
      _currentUserRole = role;
      _isAdmin = (role == 'admin');
    });
    if (_isAdmin) {
      // Load all users for admin to assign
      List<Map<String, dynamic>> users = await _userService.getAllUsers();
      setState(() {
        _users = users.where((u) => u['role'] == 'intern').toList(); // only interns
      });
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a deadline')),
      );
      return;
    }

    String assignedTo;
    if (_isAdmin) {
      if (_assignedTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an intern')),
        );
        return;
      }
      assignedTo = _assignedTo!;
    } else {
      assignedTo = FirebaseAuth.instance.currentUser!.uid;
    }

    setState(() => _loading = true);
    try {
      await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline!,
        assignedTo: assignedTo,
        assignedBy: FirebaseAuth.instance.currentUser!.uid,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully!')),
      );
      Navigator.pop(context); // go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _selectDeadline(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Assign Task' : 'Create Task'),
      ),
      body: _currentUserRole == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () => _selectDeadline(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Deadline',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDeadline == null
                              ? 'Select date'
                              : _selectedDeadline!.toLocal().toString().split(' ')[0],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_isAdmin) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Assign to Intern',
                          border: OutlineInputBorder(),
                        ),
                        value: _assignedTo,
                        items: _users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['id'],
                            child: Text(user['name'] ?? user['email'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _assignedTo = value),
                      ),
                      const SizedBox(height: 15),
                    ],
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _createTask,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(_isAdmin ? 'Assign Task' : 'Create Task'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
