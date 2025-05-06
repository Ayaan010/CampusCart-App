import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/logger_util.dart';
// import 'home_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// SignUpScreen widget for user registration
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Auth service
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign up with email and password
  Future<void> _signUp() async {
    LoggerUtil.info('Sign up button clicked');

    // Validate form
    if (_formKey.currentState?.validate() ?? false) {
      LoggerUtil.info('Form validation passed');

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      LoggerUtil.info('Loading state set to true');

      try {
        LoggerUtil.info(
          'Starting sign up process with email: ${_emailController.text.trim()}',
        );

        // Step 1: Create the user account
        UserCredential? userCredential;
        try {
          userCredential = await _authService.signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
          LoggerUtil.info('User created: ${userCredential.user?.uid}');
        } catch (authError) {
          LoggerUtil.error('Error during user creation', authError);
          rethrow;
        }

        // Set loading to false and navigate to home screen
        if (mounted) {
          LoggerUtil.info(
            'Setting loading state to false and navigating to home screen',
          );
          setState(() {
            _isLoading = false;
          });

          // Navigate to login screen with email pre-filled
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      LoginScreen(prefillEmail: _emailController.text.trim()),
            ),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration successful! Please sign in with your credentials.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Step 2: Update profile in the background after navigation
          // This ensures the UI doesn't get stuck even if profile update takes time
          Future.delayed(const Duration(milliseconds: 500), () async {
            try {
              LoggerUtil.info(
                'Updating user profile with name and phone in the background',
              );
              await _authService.updateProfile(
                displayName: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
              );
              LoggerUtil.info('Profile updated successfully in the background');
            } catch (profileError) {
              LoggerUtil.error(
                'Error updating profile in the background',
                profileError,
              );
              // No need to show error to user as they've already moved on
            }
          });
        } else {
          LoggerUtil.warning('Widget is not mounted, cannot update UI');
        }
      } catch (e) {
        LoggerUtil.error('Error during sign up', e);
        if (mounted) {
          LoggerUtil.info('Setting error message and loading state to false');
          setState(() {
            // Make error message more user-friendly
            if (e.toString().contains('email-already-in-use')) {
              _errorMessage =
                  'This email is already registered. Please use a different email or try logging in.';
            } else if (e.toString().contains('weak-password')) {
              _errorMessage =
                  'Password is too weak. Please use a stronger password.';
            } else if (e.toString().contains('invalid-email')) {
              _errorMessage =
                  'The email address is invalid. Please check and try again.';
            } else if (e.toString().contains('network-request-failed')) {
              _errorMessage =
                  'Network error. Please check your internet connection and try again.';
            } else {
              _errorMessage = 'Registration failed: ${e.toString()}';
            }
            _isLoading = false;
          });
        } else {
          LoggerUtil.warning(
            'Widget is not mounted, cannot update UI after error',
          );
        }
      }
    } else {
      LoggerUtil.warning('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40),
      body: Stack(
        children: [
          // Green curved background
          Positioned(
            top: size.height * 0.29,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF628673),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top illustration
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: size.height * 0.30,
                    child: Image.asset(
                      'assets/images/signupimg.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Form section
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    margin: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        // Input fields container
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004D40),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),

                                // Error message
                                if (_errorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                _buildInputField(
                                  controller: _nameController,
                                  hintText: 'Enter Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
                                      return 'Name must start with a letter';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    TextInputFormatter.withFunction((
                                      oldValue,
                                      newValue,
                                    ) {
                                      // If the field is empty or the first character is not a letter, reject
                                      if (newValue.text.isEmpty ||
                                          !RegExp(
                                            r'^[a-zA-Z]',
                                          ).hasMatch(newValue.text)) {
                                        // If the user is trying to enter a non-letter as the first character, reject
                                        if (newValue.text.isNotEmpty &&
                                            !RegExp(
                                              r'^[a-zA-Z]',
                                            ).hasMatch(newValue.text)) {
                                          return oldValue;
                                        }
                                        return newValue;
                                      }

                                      // Allow letters, numbers, spaces, and some special characters after the first letter
                                      if (RegExp(
                                        r'^[a-zA-Z][a-zA-Z0-9\s\.\-]*$',
                                      ).hasMatch(newValue.text)) {
                                        return newValue;
                                      }

                                      return oldValue;
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildInputField(
                                  controller: _phoneController,
                                  hintText: 'Enter Mobile Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your mobile number';
                                    }
                                    if (value.length != 10) {
                                      return 'Phone number must be exactly 10 digits';
                                    }
                                    if (!RegExp(
                                      r'^[0-9]{10}$',
                                    ).hasMatch(value)) {
                                      return 'Phone number must contain only digits';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildInputField(
                                  controller: _emailController,
                                  hintText: 'Enter Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildInputField(
                                  controller: _passwordController,
                                  hintText: 'Enter Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 25),
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _buildSignUpButton(),
                              ],
                            ),
                          ),
                        ),

                        // Bottom section
                        const Spacer(),
                        _buildBottomSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextButton(
        onPressed: _signUp,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Expanded(child: _BuildDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Or',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                ),
              ),
            ),
            const Expanded(child: _BuildDivider()),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(icon: Icons.facebook, color: Colors.blue),
            const SizedBox(width: 20),
            _buildSocialButton(isGoogle: true, color: Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF628673), size: 22),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    required Color color,
    bool isGoogle = false,
  }) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child:
            isGoogle
                ? const Text(
                  'G',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

class _BuildDivider extends StatelessWidget {
  const _BuildDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withAlpha(77));
  }
}
