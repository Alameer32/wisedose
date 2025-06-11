import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/utils/app_theme.dart';
import 'package:wisedose/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.userModel == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Safely get the first letter of the name or use a default
    final String avatarText = (authService.userModel!.name.isNotEmpty) 
        ? authService.userModel!.name.substring(0, 1).toUpperCase()
        : "U"; // 'U' for User as default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Profile avatar - now with safely handled text
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                avatarText,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // User name - displayed safely even if empty
            Text(
              authService.userModel!.name.isNotEmpty 
                  ? authService.userModel!.name 
                  : "User",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // User email
            Text(
              authService.userModel!.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // User role
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(authService.userModel!.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getRoleColor(authService.userModel!.role),
                  width: 1,
                ),
              ),
              child: Text(
                _getRoleName(authService.userModel!.role),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(authService.userModel!.role),
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Profile options
            _buildProfileOption(
              context,
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                // Navigate to edit profile screen
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                // Navigate to change password screen
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.notifications,
              title: 'Notification Settings',
              onTap: () {
                // Navigate to notification settings screen
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help & support screen
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.info,
              title: 'About WiseDose',
              onTap: () {
                // Navigate to about screen
              },
            ),
            const SizedBox(height: 24),
            
            // Logout button
            CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.pharmacist:
        return Colors.blue;
      case UserRole.patient:
        return AppTheme.primaryColor;
      // ignore: unreachable_switch_default
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.patient:
        return 'Patient';
      // ignore: unreachable_switch_default
      default:
        return 'Patient';
    }
  }
}