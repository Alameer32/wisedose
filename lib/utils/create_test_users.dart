import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestUserCreator {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTestUsers() async {
    try {
      // Create Patient User
      await _createUser(
        email: 'patient@test.com',
        password: 'password123',
        name: 'Test Patient',
        role: 'patient',
      );
      
      // Create Pharmacist User
      await _createUser(
        email: 'pharmacist@test.com',
        password: 'password123',
        name: 'Test Pharmacist',
        role: 'pharmacist',
      );
      
      // Create Admin User
      await _createUser(
        email: 'admin@test.com',
        password: 'password123',
        name: 'Test Admin',
        role: 'admin',
      );
      
      print('Test users created successfully!');
    } catch (e) {
      print('Error creating test users: $e');
    }
  }

  Future<void> _createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        print('User $email already exists, skipping creation.');
        return;
      }
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Created $role user: $email');
    } catch (e) {
      print('Error creating user $email: $e');
      rethrow;
    }
  }
}

// How to use:
// 1. Import this file in your main.dart or a test file
// 2. Call the following code after Firebase initialization:
//    final testUserCreator = TestUserCreator();
//    await testUserCreator.createTestUsers();
