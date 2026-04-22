// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'revenus_screen.dart';
import 'depenses_screen.dart';
import 'statistiques_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _userName;
  String? _userEmail;

  static const _darkBlue = Color(0xFF014AAA);
  static const _lightBlue = Color(0xFFEAF2FB);
  static const _mutedBlue = Color(0xFF8899BB);
  static const _warmBg = Color(0xFFF8F3F0);

  final List<Widget> _screens = [
    const RevenusScreen(),
    const DepensesScreen(),
    const StatistiquesScreen(),
  ];

  final List<String> _titles = ['Revenus', 'Dépenses', 'Statistiques'];
  final List<IconData> _icons = [
    Icons.trending_up,
    Icons.trending_down,
    Icons.bar_chart,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.getName();
    final email = await AuthService.getEmail();
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmBg,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color.fromARGB(255, 19, 75, 148),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 19, 75, 148),
        unselectedItemColor: _mutedBlue,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_icons[0]),
            label: _titles[0],
          ),
          BottomNavigationBarItem(
            icon: Icon(_icons[1]),
            label: _titles[1],
          ),
          BottomNavigationBarItem(
            icon: Icon(_icons[2]),
            label: _titles[2],
          ),
        ],
      ),
    );
  }
}