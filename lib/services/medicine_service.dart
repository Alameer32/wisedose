import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String patientId;
  final String pharmacistId;
  final double amount;
  final String dosage;
  final String timing;
  final String sideEffects;
  final DateTime createdAt;
  final int remainingDoses;
  final double dosageAmount; // Added field for numerical dosage amount

  Medicine({
    required this.id,
    required this.name,
    required this.patientId,
    required this.pharmacistId,
    required this.amount,
    required this.dosage,
    required this.timing,
    required this.sideEffects,
    required this.createdAt,
    required this.remainingDoses,
    this.dosageAmount = 1.0, // Default to 1 if not specified
  });

  factory Medicine.fromMap(Map<String, dynamic> map, String id) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      patientId: map['patientId'] ?? '',
      pharmacistId: map['pharmacistId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dosage: map['dosage'] ?? '',
      timing: map['timing'] ?? '',
      sideEffects: map['sideEffects'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      remainingDoses: map['remainingDoses'] ?? 0,
      dosageAmount: (map['dosageAmount'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'patientId': patientId,
      'pharmacistId': pharmacistId,
      'amount': amount,
      'dosage': dosage,
      'timing': timing,
      'sideEffects': sideEffects,
      'createdAt': Timestamp.fromDate(createdAt),
      'remainingDoses': remainingDoses,
      'dosageAmount': dosageAmount,
    };
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? patientId,
    String? pharmacistId,
    double? amount,
    String? dosage,
    String? timing,
    String? sideEffects,
    DateTime? createdAt,
    int? remainingDoses,
    double? dosageAmount,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      patientId: patientId ?? this.patientId,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      amount: amount ?? this.amount,
      dosage: dosage ?? this.dosage,
      timing: timing ?? this.timing,
      sideEffects: sideEffects ?? this.sideEffects,
      createdAt: createdAt ?? this.createdAt,
      remainingDoses: remainingDoses ?? this.remainingDoses,
      dosageAmount: dosageAmount ?? this.dosageAmount,
    );
  }
}

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMedicine(Medicine medicine) async {
    // Extract dosage amount from the dosage string if possible
    double dosageAmount = _extractDosageAmount(medicine.dosage);
    
    // Create a new map with the extracted dosage amount
    final medicineMap = medicine.toMap();
    medicineMap['dosageAmount'] = dosageAmount;
    
    await _firestore.collection('medicines').add(medicineMap);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _firestore
        .collection('medicines')
        .doc(medicine.id)
        .update(medicine.toMap());
  }

  Future<void> deleteMedicine(String id) async {
    await _firestore.collection('medicines').doc(id).delete();
  }

  Stream<List<Medicine>> getMedicinesForPatient(String patientId) {
    return _firestore
        .collection('medicines')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Medicine>> getMedicinesForPharmacist(String pharmacistId) {
    return _firestore
        .collection('medicines')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Updated to take dosage into account
  Future<void> decrementDose(String medicineId) async {
    try {
      final doc = await _firestore.collection('medicines').doc(medicineId).get();
      if (doc.exists) {
        final medicine = Medicine.fromMap(doc.data()!, doc.id);
        
        // Get the dosage amount (how much is taken per dose)
        double dosageAmount = medicine.dosageAmount;
        
        // Calculate new remaining doses
        int newRemainingDoses = medicine.remainingDoses;
        if (newRemainingDoses >= dosageAmount) {
          newRemainingDoses = (newRemainingDoses - dosageAmount).toInt();
          
          // Ensure we don't go below zero
          if (newRemainingDoses < 0) newRemainingDoses = 0;
          
          await _firestore.collection('medicines').doc(medicineId).update({
            'remainingDoses': newRemainingDoses,
          });
        }
      }
    } catch (e) {
      print('Error decrementing dose: $e');
    }
  }
  
  // Helper method to extract dosage amount from dosage string
  double _extractDosageAmount(String dosage) {
    try {
      // Try to extract a number from the dosage string
      RegExp regExp = RegExp(r'(\d+(\.\d+)?)');
      var match = regExp.firstMatch(dosage);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting dosage amount: $e');
    }
    return 1.0; // Default to 1 if we can't extract a number
  }
}
