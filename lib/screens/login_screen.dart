import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  void _login() {
    final username = _userController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên tài khoản.')),
      );
      return;
    }

    AuthService.currentUser = username;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3C4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    size: 58,
                    color: Color(0xFF678B55),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mở nhạc,\nchạm cảm xúc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF27312B),
                    fontSize: 31,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đăng nhập bằng tên tài khoản để lưu playlist yêu thích.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 34),
                TextField(
                  controller: _userController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Tên tài khoản',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF678B55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Đăng nhập & khám phá',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
