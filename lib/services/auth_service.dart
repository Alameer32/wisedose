import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserRole { patient, pharmacist, admin }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Improved role parsing with better error handling
    UserRole parseRole(dynamic roleValue) {
      if (roleValue == null) return UserRole.patient;
      
      final String roleStr = roleValue.toString().toLowerCase();
      print("Parsing role: $roleStr");
      
      if (roleStr.contains('admin')) return UserRole.admin;
      if (roleStr.contains('pharmacist')) return UserRole.pharmacist;
      return UserRole.patient;
    }
    
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: parseRole(map['role']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
    };
  }
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    try {
      print("Initializing AuthService");
      
      // Set up auth state listener
      _auth.authStateChanges().listen((User? user) {
        print("Auth state changed: ${user?.uid}");
        if (user != null) {
          _fetchUserData(user.uid);
        } else {
          _userModel = null;
          notifyListeners();
        }
      });
      
      // Force an immediate check of the current user
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print("Current user found: ${currentUser.uid}");
        await _fetchUserData(currentUser.uid);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print("Error initializing auth service: $e");
      _isInitialized = true; // Mark as initialized even on error
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      print("Fetching user data for: $uid");
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Ensure uid is included in the data
        data['uid'] = uid;
        
        print("User data fetched: $data");
        _userModel = UserModel.fromMap(data);
        print("User role: ${_userModel!.role}");
        notifyListeners();
      } else {
        print("No user document found for: $uid");
        // Create a default user document if it doesn't exist
        final user = _auth.currentUser;
        if (user != null) {
          final defaultUserModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            role: UserRole.patient,
          );
          
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(defaultUserModel.toMap());
          
          _userModel = defaultUserModel;
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }
  
  // Force refresh user data from Firestore
  Future<void> refreshUserData() async {
    if (currentUser != null) {
      try {
        print("Refreshing user data for: ${currentUser!.uid}");
        await _fetchUserData(currentUser!.uid);
      } catch (e) {
        print("Error refreshing user data: $e");
      }
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.patient,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        final userModel = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
          role: role,
        );
        
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());
        
        _userModel = userModel;
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      print("Registration error: $e");
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Force fetch user data immediately after login
      if (result.user != null) {
        await _fetchUserData(result.user!.uid);
      }
      
      return result;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      print("Sign out error: $e");
      rethrow;
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role.toString().split('.').last,
      });
      
      if (_userModel?.uid == uid) {
        _userModel = UserModel(
          uid: _userModel!.uid,
          email: _userModel!.email,
          name: _userModel!.name,
          role: role,
        );
        notifyListeners();
      }
    } catch (e) {
      print("Update user role error: $e");
      rethrow;
    }
  }
}
