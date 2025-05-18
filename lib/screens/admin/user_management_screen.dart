import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/utils/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Filter by role:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedFilter == 'All',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = 'All';
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Patients'),
                selected: _selectedFilter == 'patient',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = 'patient';
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pharmacists'),
                selected: _selectedFilter == 'pharmacist',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = 'pharmacist';
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Admins'),
                selected: _selectedFilter == 'admin',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = 'admin';
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // User list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedFilter == 'All'
                ? _firestore.collection('users').snapshots()
                : _firestore
                    .collection('users')
                    .where('role', isEqualTo: _selectedFilter)
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

              final users = snapshot.data?.docs ?? [];

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userData = user.data() as Map<String, dynamic>;
                  final userId = user.id;
                  final userName = userData['name'] as String;
                  final userEmail = userData['email'] as String;
                  final userRole = userData['role'] as String;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _showUserOptions(context, userId, userName, userRole);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRoleColor(userRole),
                              child: Text(
                                userName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    userEmail,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(userRole).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _capitalizeRole(userRole),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getRoleColor(userRole),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'pharmacist':
        return Colors.blue;
      case 'patient':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeRole(String role) {
    return role.substring(0, 1).toUpperCase() + role.substring(1);
  }

  void _showUserOptions(BuildContext context, String userId, String userName, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(currentRole).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _capitalizeRole(currentRole),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleColor(currentRole),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeRoleDialog(context, userId, currentRole);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteUserDialog(context, userId, userName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeRoleDialog(BuildContext context, String userId, String currentRole) {
    UserRole selectedRole = _stringToUserRole(currentRole);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change User Role'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<UserRole>(
                    title: const Text('Patient'),
                    value: UserRole.patient,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  RadioListTile<UserRole>(
                    title: const Text('Pharmacist'),
                    value: UserRole.pharmacist,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  RadioListTile<UserRole>(
                    title: const Text('Admin'),
                    value: UserRole.admin,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('users').doc(userId).update({
                    'role': selectedRole.toString().split('.').last,
                  });
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User role updated successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating user role: ${e.toString()}'),
                    ),
                  );
                }
              },
              child: const Text('Update Role'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                try {
                  await _firestore.collection('users').doc(userId).delete();
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting user: ${e.toString()}'),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  UserRole _stringToUserRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'patient':
        return UserRole.patient;
      default:
        return UserRole.patient;
    }
  }
}
