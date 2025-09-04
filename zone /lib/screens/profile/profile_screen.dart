import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart'; 
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = u;
        _loading = false;
      });
    }

  }

  Future<void> _signOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy', style: TextStyle(color: AppColors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Đăng xuất', style: TextStyle(color: AppColors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        context.go('/login'); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white, 
        elevation: 1, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black), 
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Hồ sơ của bạn', 
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => context.push('/profile/edit'), 
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải hồ sơ...', style: TextStyle(color: AppColors.grey)),
                ],
              ),
            )
          : SingleChildScrollView( 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60, 
                            backgroundColor: AppColors.lightGrey,
                            backgroundImage: (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(_user!.avatarUrl!)
                                : null,
                            child: (_user?.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                                ? Text(
                                    _user?.fullName?.isNotEmpty == true
                                        ? _user!.fullName![0].toUpperCase()
                                        : (_user?.email?.isNotEmpty == true ? _user!.email![0].toUpperCase() : 'U'),
                                    style: const TextStyle(fontSize: 48, color: AppColors.white), // Font lớn hơn
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _user?.fullName ?? 'Chưa cập nhật tên', 
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _user?.email ?? 'Không có email',
                          ),
                          const Divider(height: 25, thickness: 1, color: AppColors.lightGrey),
                          _buildInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Ngày tham gia',
                            value: _user?.createdAt != null
                                ? '${_user!.createdAt.toLocal().day}/${_user!.createdAt.toLocal().month}/${_user!.createdAt.toLocal().year}'
                                : 'Không xác định',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  CustomButton(
                    text: 'Đăng xuất',
                    backgroundColor: AppColors.error,
                    textColor: AppColors.white,
                    icon: Icons.logout, // Thêm icon
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Icon(icon, size: 22, color: AppColors.primary), 
        Expanded( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}