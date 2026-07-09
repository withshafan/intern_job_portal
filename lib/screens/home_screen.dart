import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Added as per step 8 note
import 'tasks_screen.dart';
import 'create_task_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
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
        const Center(child: Text('Admin Dashboard (coming soon)')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
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
}
