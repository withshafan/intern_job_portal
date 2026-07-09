import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Added as per step 8 note
import 'tasks_screen.dart';
import 'create_task_screen.dart';
import 'progress_screen.dart';
import '../widgets/app_drawer.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  String? _userRole;
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    String? role = await _userService.getCurrentUserRole();
    setState(() {
      _userRole = role;
      _loading = false;
    });
  }

  // Define tab screens based on role
  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        _buildAdminDashboard(),
        const TasksScreen(isAdmin: true),
        const ProgressScreen(isAdmin: true),
      ];
    } else {
      // Intern
      return [
        const TasksScreen(isAdmin: false),
        const CreateTaskScreen(),
        const ProgressScreen(isAdmin: false),
      ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    if (_userRole == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'My Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create Task'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Progress'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If role is null, maybe sign out or show error
    if (_userRole == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unable to determine user role.'),
              ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                  // Navigate to login (use pushReplacement to clear stack)
                  // For now, just pop to root? We'll handle later.
                  // Actually, we can use Navigator.pushReplacementNamed
                  // but we don't have named routes yet, so we'll just pop.
                  // We'll improve in later steps.
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> screens = _getScreens();
    List<BottomNavigationBarItem> items = _getBottomNavItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Portal'),
      ),
      drawer: AppDrawer(userRole: _userRole ?? 'guest'),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: items,
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return FutureBuilder<Map<String, int>>(
      future: _getAdminStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        var stats = snapshot.data ?? {};
        int totalInterns = stats['totalInterns'] ?? 0;
        int totalTasks = stats['totalTasks'] ?? 0;
        int pending = stats['pending'] ?? 0;
        int inProgress = stats['inProgress'] ?? 0;
        int completed = stats['completed'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statCard('Interns', totalInterns, Colors.blue),
                  _statCard('Total Tasks', totalTasks, Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Task Status Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard('Pending', pending, Colors.orange),
                  _statCard('In Progress', inProgress, Colors.blue),
                  _statCard('Completed', completed, Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper stat card
  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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

  // Future to fetch stats
  Future<Map<String, int>> _getAdminStats() async {
    var allTasks = await _taskService.getAllTasksFuture();
    var allUsers = await _userService.getAllUsers();
    int totalInterns = allUsers.where((u) => u['role'] == 'intern').length;
    int pending = allTasks.where((t) => t.status == 'pending').length;
    int inProgress = allTasks.where((t) => t.status == 'in_progress').length;
    int completed = allTasks.where((t) => t.status == 'completed').length;
    return {
      'totalInterns': totalInterns,
      'totalTasks': allTasks.length,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
    };
  }
}
