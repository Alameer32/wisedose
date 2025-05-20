import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/services/theme_service.dart';
import 'package:wisedose/screens/pharmacist/assign_medicine_screen.dart';
import 'package:wisedose/screens/pharmacist/pharmacist_chat_screen.dart';
import 'package:wisedose/screens/pharmacist/patient_list_screen.dart';
import 'package:wisedose/widgets/theme_toggle.dart';

class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({super.key});

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    
    if (authService.userModel == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiseDose - Pharmacist'),
        actions: [
          ThemeToggle(
            isDarkMode: themeService.isDarkMode,
            onToggle: themeService.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: _buildBody(authService),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignMedicineScreen(
                      pharmacistId: authService.userModel!.uid,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AuthService authService) {
    switch (_selectedIndex) {
      case 0:
        return PatientListScreen(pharmacistId: authService.userModel!.uid);
      case 1:
        return _buildMedicinesList(authService);
      case 2:
        return PharmacistChatScreen(pharmacistId: authService.userModel!.uid);
      default:
        return PatientListScreen(pharmacistId: authService.userModel!.uid);
    }
  }

  Widget _buildMedicinesList(AuthService authService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Assigned Medications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage medications you\'ve assigned',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignMedicineScreen(
                    pharmacistId: authService.userModel!.uid,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Assign New Medication'),
          ),
        ],
      ),
    );
  }
}
