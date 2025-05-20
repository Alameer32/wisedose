import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/medicine_service.dart';
import 'package:wisedose/utils/app_theme.dart';
import 'package:wisedose/widgets/custom_button.dart';
import 'package:wisedose/widgets/custom_text_field.dart';

class AssignMedicineScreen extends StatefulWidget {
  final String pharmacistId;
  final String? patientId;

  const AssignMedicineScreen({
    super.key,
    required this.pharmacistId,
    this.patientId,
  });

  @override
  State<AssignMedicineScreen> createState() => _AssignMedicineScreenState();
}

class _AssignMedicineScreenState extends State<AssignMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timingController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _remainingDosesController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  
  final MedicineService _medicineService = MedicineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _selectedPatientId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    if (widget.patientId != null) {
      _selectedPatientId = widget.patientId;
    }
    
    // Set default value for dosage amount
    _dosageAmountController.text = '1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dosageController.dispose();
    _timingController.dispose();
    _sideEffectsController.dispose();
    _remainingDosesController.dispose();
    _dosageAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .get();
    
    setState(() {
      _patients = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] as String,
                'email': doc.data()['email'] as String,
              })
          .toList();
    });
  }

  Future<void> _assignMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse the dosage amount
      double dosageAmount = double.tryParse(_dosageAmountController.text.trim()) ?? 1.0;
      
      final medicine = Medicine(
        id: '',
        name: _nameController.text.trim(),
        patientId: _selectedPatientId!,
        pharmacistId: widget.pharmacistId,
        amount: double.parse(_amountController.text.trim()),
        dosage: _dosageController.text.trim(),
        timing: _timingController.text.trim(),
        sideEffects: _sideEffectsController.text.trim(),
        createdAt: DateTime.now(),
        remainingDoses: int.parse(_remainingDosesController.text.trim()),
        dosageAmount: dosageAmount,
      );

      await _medicineService.addMedicine(medicine);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine assigned successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning medicine: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Medicine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient selection
              if (widget.patientId == null) ...[
                _buildSectionHeader('Select Patient'),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPatientId,
                      decoration: InputDecoration(
                        labelText: 'Patient',
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: _patients.map((patient) {
                        return DropdownMenuItem<String>(
                          value: patient['id'] as String,
                          child: Text('${patient['name']} (${patient['email']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPatientId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a patient';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Medicine details
              _buildSectionHeader('Medicine Details'),
              
              // Medicine name
              _buildFormCard(
                child: CustomTextField(
                  controller: _nameController,
                  labelText: 'Medicine Name',
                  prefixIcon: Icons.medication,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter medicine name';
                    }
                    return null;
                  },
                ),
              ),
              
              // Amount
              _buildFormCard(
                child: CustomTextField(
                  controller: _amountController,
                  labelText: 'Total Amount (mg/ml)',
                  prefixIcon: Icons.scale,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              
              // Dosage
              _buildFormCard(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _dosageController,
                      labelText: 'Dosage Description (e.g., 1 pill, 5ml)',
                      prefixIcon: Icons.medical_information,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _dosageAmountController,
                      labelText: 'Dosage Amount (units per dose)',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      // helperText: 'How many units are consumed in each dose',
                    ),
                  ],
                ),
              ),
              
              // Timing
              _buildFormCard(
                child: CustomTextField(
                  controller: _timingController,
                  labelText: 'Timing (e.g., Once daily, After meals)',
                  prefixIcon: Icons.access_time,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter timing';
                    }
                    return null;
                  },
                ),
              ),
              
              // Remaining doses
              _buildFormCard(
                child: CustomTextField(
                  controller: _remainingDosesController,
                  labelText: 'Total Units Available',
                  prefixIcon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter total units';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  // helperText: 'Total number of units (not doses) available',
                ),
              ),
              
              // Side effects
              _buildFormCard(
                child: CustomTextField(
                  controller: _sideEffectsController,
                  labelText: 'Side Effects',
                  prefixIcon: Icons.warning,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter side effects';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              CustomButton(
                text: 'Assign Medicine',
                isLoading: _isLoading,
                onPressed: _assignMedicine,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
