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
  });

  factory Medicine.fromMap(Map<String, dynamic> map, String id) {
    return Medicine(
      id: id,
      name: map['name'],
      patientId: map['patientId'],
      pharmacistId: map['pharmacistId'],
      amount: map['amount'].toDouble(),
      dosage: map['dosage'],
      timing: map['timing'],
      sideEffects: map['sideEffects'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      remainingDoses: map['remainingDoses'],
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
    );
  }
}

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMedicine(Medicine medicine) async {
    await _firestore.collection('medicines').add(medicine.toMap());
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

  Future<void> decrementDose(String medicineId) async {
    final doc = await _firestore.collection('medicines').doc(medicineId).get();
    if (doc.exists) {
      final medicine = Medicine.fromMap(doc.data()!, doc.id);
      if (medicine.remainingDoses > 0) {
        await _firestore.collection('medicines').doc(medicineId).update({
          'remainingDoses': medicine.remainingDoses - 1,
        });
      }
    }
  }
}
