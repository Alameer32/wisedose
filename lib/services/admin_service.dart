import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total users count
  Stream<int> getTotalUsersCount() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // Get patients count
  Stream<int> getPatientsCount() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // Get pharmacists count
  Stream<int> getPharmacistsCount() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacist')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  // Get total medications count
  Stream<int> getMedicationsCount() {
    return _firestore.collection('medicines').snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }
} 