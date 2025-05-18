import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/services/medicine_service.dart';
import 'package:wisedose/services/theme_service.dart';
import 'package:wisedose/screens/patient/medicine_detail_screen.dart';
import 'package:wisedose/screens/patient/patient_chat_screen.dart';
import 'package:wisedose/utils/app_theme.dart';
import 'package:wisedose/widgets/medicine_card.dart';
import 'package:wisedose/widgets/theme_toggle.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MedicineService _medicineService = MedicineService();

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
        title: const Text('WiseDose - Patient'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white60 
            : Colors.grey[600],
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.darkCardColor 
            : Colors.white,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
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
        return _buildMedicinesList(authService);
      case 1:
        return PatientChatScreen(patientId: authService.userModel!.uid);
      default:
        return _buildMedicinesList(authService);
    }
  }

  Widget _buildMedicinesList(AuthService authService) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medicines')
          .where('patientId', isEqualTo: authService.userModel!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final medicines = snapshot.data?.docs ?? [];

        if (medicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Medicines',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no medicines assigned yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicineData = medicines[index].data() as Map<String, dynamic>;
              final medicine = Medicine(
                id: medicines[index].id,
                name: medicineData['name'] ?? '',
                patientId: medicineData['patientId'] ?? '',
                pharmacistId: medicineData['pharmacistId'] ?? '',
                amount: (medicineData['amount'] ?? 0).toDouble(),
                dosage: medicineData['dosage'] ?? '',
                timing: medicineData['timing'] ?? '',
                sideEffects: medicineData['sideEffects'] ?? '',
                createdAt: (medicineData['createdAt'] as Timestamp).toDate(),
                remainingDoses: medicineData['remainingDoses'] ?? 0,
                dosageAmount: (medicineData['dosageAmount'] ?? 1.0).toDouble(),
              );

              return MedicineCard(
                medicine: medicine,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineDetailScreen(
                        medicine: medicine,
                      ),
                    ),
                  );
                },
                onTakeDose: () {
                  _takeDose(medicine);
                },
              );
            },
          ),
        );
      },
    );
  }
  
  void _takeDose(Medicine medicine) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to take ${medicine.dosage} of ${medicine.name}?'),
            const SizedBox(height: 16),
            Text(
              'This will reduce your remaining supply by ${medicine.dosageAmount} units.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current remaining: ${medicine.remainingDoses} units',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'After taking: ${(medicine.remainingDoses - medicine.dosageAmount).toInt()} units',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (medicine.remainingDoses - medicine.dosageAmount) <= 5 
                    ? Colors.red 
                    : Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _medicineService.decrementDose(medicine.id);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You took ${medicine.dosage} of ${medicine.name}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Show low supply warning if needed
              if ((medicine.remainingDoses - medicine.dosageAmount) <= 5 && 
                  (medicine.remainingDoses - medicine.dosageAmount) > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Low supply warning: ${medicine.name} is running low!'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              
              // Show out of stock warning if needed
              if ((medicine.remainingDoses - medicine.dosageAmount) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${medicine.name} is now out of stock! Please contact your pharmacist.'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Take Dose'),
          ),
        ],
      ),
    );
  }
}
