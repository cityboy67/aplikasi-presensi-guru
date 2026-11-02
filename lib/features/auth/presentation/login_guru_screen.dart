import 'package:flutter/material.dart';
import '../../guru/presentation/guru_dashboard_screen.dart';

class LoginGuruScreen extends StatefulWidget {
  const LoginGuruScreen({super.key});

  @override
  State<LoginGuruScreen> createState() => _LoginGuruScreenState();
}

class _LoginGuruScreenState extends State<LoginGuruScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const GuruDashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Header Gambar Gedung Al Aqsha
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.35,
                child: Image.asset(
                  'assets/images/bg_alaqsha.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1B4D4F),
                      child: const Center(
                        child: Text(
                          'AL AQSHA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Form Putih Lengkung (Scrollable Anti-Overflow)
              Positioned.fill(
                top: screenHeight * 0.28,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            'Halo Guru',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Field Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF41735E), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF41735E), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Checkbox Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: const Color(0xFF41735E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tombol Sign In
                        ElevatedButton(
                          onPressed: _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF41735E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider "Sign in with"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Sign in with',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Sign In
                        Center(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Image.asset(
                                'assets/images/ic_google.png',
                                width: 26,
                                height: 26,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.red,
                                    size: 32,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Footer Logo
                        _buildCollaborationSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollaborationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoCircle(
          imagePath: 'assets/images/logo_sekolah.png',
          fallbackIcon: Icons.school_rounded,
          fallbackColor: Colors.red.shade700,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        _buildLogoCircle(
          imagePath: 'assets/images/logo_mitra.png',
          fallbackIcon: Icons.public_rounded,
          fallbackColor: Colors.teal.shade700,
        ),
      ],
    );
  }

  Widget _buildLogoCircle({
    required String imagePath,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon,
                color: fallbackColor,
                size: 22,
              );
            },
          ),
        ),
      ),
    );
  }
}