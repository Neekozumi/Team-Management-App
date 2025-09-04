import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'dart:io';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('Đang đăng ký với email: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName, 
        },
      );

      print('Kết quả đăng ký: ${response.user?.id}');

      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileResponse == null) {
          print('Tạo profile thủ công...');
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
          });
        }

        return UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }
//_____________________________________________________________
  // Đăng nhập 
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Đang đăng nhập với email: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Kết quả đăng nhập: ${response.user?.id}');

      if (response.user != null) {
        final user = await getCurrentUser();
        print('User profile: ${user?.fullName}');
        return user;
      }
      return null;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }
//______________________________________________________________
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Không có user hiện tại');
        return null;
      }

      print('Lấy profile cho user: ${user.id}');
      
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        print('Không tìm thấy profile');
        return null;
      }

      print('Profile data: $response');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Lỗi lấy user hiện tại: $e');
      return null;
    }
  }
//______________________________________________________________
  // Đăng xuất
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool get isSignedIn => _supabase.auth.currentUser != null;

  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;
  
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Không thể reset password: ${e.toString()}');
    }
  }
//______________________________________________________________

  Future<UserModel?> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final updates = <String, dynamic>{
      'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);

    final resp = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(resp);
  }
}
//______________________________________________________________

