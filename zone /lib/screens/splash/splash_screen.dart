// lib/screens/splash/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation; 

  StreamSubscription<AuthState>? _authSub;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    // 1) Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800), 
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.2), 
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, 
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn), 
    ));

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        if (mounted) context.go('/home');
      }
    });

    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (mounted) context.go('/home');
      return;
    }

    _controller.forward().then((_) {
      if (mounted) setState(() => _showButtons = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation.drive(Tween(begin: 1.0, end: 1.0)),
                      child: ShaderMask( 
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70], 
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'zone',
                          style: TextStyle(
                            fontSize: 72, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white, 
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_showButtons)
                FadeTransition( 
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40), 
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 55, 
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, 
                              foregroundColor: AppColors.primary, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), 
                              ),
                              elevation: 5, 
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Đăng nhập'),
                          ),
                        ),
                        const SizedBox(height: 18), 
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: () => context.go('/register'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white, width: 2), 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Đăng ký'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_showButtons) 
                const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}