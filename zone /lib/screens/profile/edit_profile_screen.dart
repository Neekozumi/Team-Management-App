import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _auth = AuthService();

  UserModel? _user;
  XFile? _pickedFile; 
  Uint8List? _imageBytes; 
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _auth.getCurrentUser();
    if (mounted && u != null) {
      _user = u;
      _nameCtrl.text = u.fullName ?? ''; 
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (xfile != null) {
        _pickedFile = xfile;

        if (kIsWeb) {
          _imageBytes = await xfile.readAsBytes();
        }

        print('Picked image: ${xfile.path}');
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String> _uploadAvatar(XFile file) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final ext = p.extension(file.name); 
    final key = 'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}$ext';

    print('Uploading to avatars bucket at key: $key');

    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await client.storage.from('avatars').uploadBinary(key, bytes,
            fileOptions: const FileOptions(upsert: true)); 
      } else {
        await client.storage.from('avatars').upload(key, File(file.path),
            fileOptions: const FileOptions(upsert: true));
      }
      print('Upload complete.');

      final publicUrl = client.storage.from('avatars').getPublicUrl(key);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Supabase Storage Error: $e');
      rethrow; 
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      String? avatarUrl;
      if (_pickedFile != null) {
        avatarUrl = await _uploadAvatar(_pickedFile!);
      }

      print('Updating profile: fullName=${_nameCtrl.text.trim()}, avatarUrl=$avatarUrl');
      final updatedUser = await _auth.updateProfile(
        fullName: _nameCtrl.text.trim(),
        avatarUrl: avatarUrl,
      );
      print('Profile update returned: ${updatedUser?.avatarUrl}');

      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      print('Error during save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_pickedFile != null) {
      if (kIsWeb && _imageBytes != null) {
        imageProvider = MemoryImage(_imageBytes!);
      } else if (!kIsWeb) {
        imageProvider = FileImage(File(_pickedFile!.path));
      }
    } else if (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_user!.avatarUrl!);
    }

    return GestureDetector( 
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60, 
            backgroundColor: AppColors.lightGrey,
            backgroundImage: imageProvider,
            child: (imageProvider == null)
                ? Text(
                    _user?.fullName?.isNotEmpty == true 
                        ? _user!.fullName![0].toUpperCase()
                        : (_user?.email.isNotEmpty == true ? _user!.email![0].toUpperCase() : 'U'), 
                    style: const TextStyle(fontSize: 40, color: AppColors.white),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 20, 
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.camera_alt, size: 22, color: Colors.white), 
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black), 
          onPressed: () => context.go('/profile'),
        ),
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _user == null
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
              padding: const EdgeInsets.all(24),
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
                          _buildAvatar(),
                          const SizedBox(height: 16),
                          Text(
                            _user!.email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      controller: _nameCtrl,
                      label: 'Họ và tên',
                      hintText: 'Nhập họ và tên của bạn',
                      prefixIcon: const Icon(Icons.person_outline), 
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ và tên không được để trống' : null,
                    ),
                  ),
                  const SizedBox(height: 40), 
                  CustomButton(
                    text: 'Lưu thay đổi',
                    isLoading: _loading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}