import 'package:flutter/material.dart';
import '../supabase_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _registerNoController = TextEditingController();
  final _yearController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  bool _isSignup = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _registerNoController.dispose();
    _yearController.dispose();
    _roomNoController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    if (_isSignup) {
      if (_nameController.text.trim().isEmpty ||
          _registerNoController.text.trim().isEmpty) {
        _showMessage('Name and Register Number are required.');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      if (_isSignup) {
        final res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (res.user != null) {
          await supabase.from('profiles').insert({
            'id': res.user!.id,
            'role': 'student',
            'name': _nameController.text.trim(),
            'register_no': _registerNoController.text.trim(),
            'year_of_study':
                int.tryParse(_yearController.text.trim()),
            'room_no': _roomNoController.text.trim(),
            'phone': _phoneController.text.trim(),
            'parent_phone': _parentPhoneController.text.trim(),
          });
        }

        _showMessage('Account created successfully!');
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF6F7FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF536DFE),
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7B8191),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.exit_to_app_rounded,
            size: 42,
            color: Color(0xFF3155D9),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'LeaveEase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          _isSignup
              ? 'Create your student account'
              : 'Leave management, made easy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          decoration: _inputDecoration(
            label: 'Email address',
            icon: Icons.email_outlined,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            label: 'Password',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(
            label: 'Full name',
            icon: Icons.person_outline,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _registerNoController,
          decoration: _inputDecoration(
            label: 'Register number',
            icon: Icons.badge_outlined,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _yearController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            label: 'Year of study',
            icon: Icons.school_outlined,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _roomNoController,
          decoration: _inputDecoration(
            label: 'Room number',
            icon: Icons.meeting_room_outlined,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            label: 'Your phone number',
            icon: Icons.phone_outlined,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _parentPhoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            label: "Parent's phone number",
            icon: Icons.phone_android_outlined,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF142B72),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF142B72),
              Color(0xFF2448C8),
              Color(0xFF4A3DB8),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              22,
              35,
              22,
              30,
            ),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),

                child: Column(
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 32),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.fromLTRB(
                        22,
                        28,
                        22,
                        22,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [
                          Text(
                            _isSignup
                                ? 'Create account'
                                : 'Welcome back 👋',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17203A),
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            _isSignup
                                ? 'Enter your details to get started.'
                                : 'Sign in to manage your leave requests.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7B8191),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 25),

                          _buildLoginFields(),

                          if (_isSignup) ...[
                            const SizedBox(height: 20),

                            const Divider(
                              color: Color(0xFFE8EAF0),
                            ),

                            const SizedBox(height: 20),

                            _buildSignupFields(),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed:
                                  _loading ? null : _handleAuth,

                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF3155D9),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFB7C1E8),

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(15),
                                ),
                              ),

                              child: _loading
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isSignup
                                              ? 'Create Account'
                                              : 'Log In',
                                          style:
                                              const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignup
                                    ? 'Already have an account?'
                                    : "Don't have an account?",
                                style: const TextStyle(
                                  color: Color(0xFF7B8191),
                                  fontSize: 13,
                                ),
                              ),

                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isSignup =
                                              !_isSignup;
                                        });
                                      },

                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                ),

                                child: Text(
                                  _isSignup
                                      ? 'Log in'
                                      : 'Sign up',
                                  style: const TextStyle(
                                    color: Color(0xFF3155D9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: Colors.white.withOpacity(0.65),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Secure & simple hostel management',
                          style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}