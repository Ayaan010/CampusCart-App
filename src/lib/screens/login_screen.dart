import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/logger_util.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'admin/admin_screen.dart';

/// LoginScreen is a StatefulWidget that provides the user interface for logging in.
/// It includes:
/// - Email and password input fields with visibility toggle
/// - Sign in button
/// - Social login options (Facebook and Google)
/// - Option to navigate to sign up screen
class LoginScreen extends StatefulWidget {
  final String? prefillEmail;

  const LoginScreen({super.key, this.prefillEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isResettingPassword = false;

  // Text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  // Auth service
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Pre-fill email field if provided
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
      // Also pre-fill the reset email field
      _resetEmailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // Sign in with email and password
  Future<void> _signIn() async {
    // Validate form
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        LoggerUtil.info(
          'Attempting to sign in with email: ${_emailController.text.trim()}',
        );

        // Sign in with email and password
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Check if user is admin
        final isAdmin = await _authService.isAdmin();
        LoggerUtil.info('User is admin: $isAdmin');

        // Navigate based on user role
        if (mounted) {
          if (isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        LoggerUtil.error('Error during sign in', e);
        setState(() {
          if (e.toString().contains('user-not-found')) {
            _errorMessage =
                'No user found with this email. Please check your email or sign up.';
          } else if (e.toString().contains('wrong-password')) {
            _errorMessage = 'Incorrect password. Please try again.';
          } else if (e.toString().contains('invalid-credential')) {
            _errorMessage = 'Incorrect email or password. Please try again.';
          } else {
            _errorMessage = 'Login failed: ${e.toString()}';
          }
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Send password reset email
  Future<void> _sendPasswordResetEmail() async {
    // Validate form
    if (_resetFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isResettingPassword = true;
        _errorMessage = '';
      });

      try {
        LoggerUtil.info(
          'Attempting to send password reset email to: ${_resetEmailController.text.trim()}',
        );

        // Send password reset email
        await _authService.sendPasswordResetEmail(
          _resetEmailController.text.trim(),
        );

        LoggerUtil.info('Password reset email sent successfully');

        // Close the dialog
        if (mounted) {
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password reset email sent. Please check your inbox.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        LoggerUtil.error('Error sending password reset email', e);

        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isResettingPassword = false;
          });
        }
      }
    }
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    _resetEmailController.text = _emailController.text.trim();
    _errorMessage = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Reset Password',
              style: TextStyle(
                color: Color(0xFF004D40),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Form(
              key: _resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withAlpha(77)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Email input field
                  TextFormField(
                    controller: _resetEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              _isResettingPassword
                  ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : ElevatedButton(
                    onPressed: _sendPasswordResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions for responsive layout calculations
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Set the main background color to orange
      backgroundColor: const Color(0xFFFFAB40),
      body: Stack(
        children: [
          // Green curved background container positioned from top
          // This creates the wave-like effect at the bottom of the screen
          Positioned(
            top:
                size.height *
                0.37, // Adjusted to align with bottom of sign in image
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // Decoration for the green background with curved top corners
              decoration: const BoxDecoration(
                color: Color(0xFF628673), // Green color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Main content area with scrolling capability
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top section containing the login illustration
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        size.height *
                        0.35, // Keep the same height for proper spacing
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      // Login illustration image
                      child: Image.asset(
                        'assets/images/signinimg.png',
                        height:
                            size.height * 0.22, // Keep the same image height
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Main form section containing input fields and buttons
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 40,
                      ), // Increased spacing after illustration
                      // Container for input fields with translucent white background
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                          20,
                          30,
                          20,
                          20,
                        ), // Added top margin
                        padding: const EdgeInsets.all(20),
                        // Decoration for the form container
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                26,
                              ), // 0.1 opacity = 26 in alpha (255 * 0.1)
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
                                'Sign In',
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
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(26),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.red.withAlpha(77),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Email input field
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

                              // Password input field with visibility toggle
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

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // Sign in button with gradient background
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _buildSignInButton(context),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(), // Pushes the bottom section to the bottom
                      // Bottom section with sign up option and social logins
                      _buildBottomSection(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a custom input field widget with the following features:
  /// - Custom styling with white background and shadow
  /// - Optional password visibility toggle
  /// - Custom keyboard type
  /// - Placeholder text
  ///
  /// Parameters:
  /// [hintText] - The placeholder text to show in the input field
  /// [icon] - The icon to show before the input
  /// [isPassword] - Whether this is a password field (adds visibility toggle)
  /// [keyboardType] - The type of keyboard to show (e.g., email, number)
  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              26,
            ), // 0.1 opacity = 26 in alpha (255 * 0.1)
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
      ),
    );
  }

  /// Builds the sign in button with gradient background and shadow effect
  /// Features:
  /// - Gradient background from dark to light green
  /// - Rounded corners
  /// - Shadow effect
  /// - Custom text styling
  Widget _buildSignInButton(BuildContext context) {
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
            color: const Color(
              0xFF004D40,
            ).withAlpha(102), // 0.4 opacity = 102 in alpha (255 * 0.4)
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(
              0xFF004D40,
            ).withAlpha(51), // 0.2 opacity = 51 in alpha (255 * 0.2)
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: TextButton(
        onPressed: _signIn,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Sign In',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds the bottom section of the login screen containing:
  /// - Sign up link
  /// - Divider with "Or" text
  /// - Social login buttons (Facebook and Google)
  Widget _buildBottomSection(BuildContext context) {
    return Column(
      children: [
        // "Don't have an account?" text with sign up link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Question text
            Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Colors.white.withAlpha(
                  230,
                ), // 0.9 opacity = 230 in alpha (255 * 0.9)
                fontSize: 13,
              ),
            ),
            // Sign up link
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Divider with "Or" text in the middle
        Row(
          children: [
            // Left divider line
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withAlpha(77),
              ), // 0.3 opacity = 77 in alpha (255 * 0.3)
            ),
            // "Or" text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Or',
                style: TextStyle(
                  color: Colors.white.withAlpha(
                    230,
                  ), // 0.9 opacity = 230 in alpha (255 * 0.9)
                  fontSize: 13,
                ),
              ),
            ),
            // Right divider line
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withAlpha(77),
              ), // 0.3 opacity = 77 in alpha (255 * 0.3)
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Social login buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Facebook login button
            _buildSocialButton(icon: Icons.facebook),
            const SizedBox(width: 20),
            // Google login button
            _buildSocialButton(isGoogle: true),
          ],
        ),
      ],
    );
  }

  /// Builds a social login button (Facebook or Google)
  /// Features:
  /// - Circular shape
  /// - Platform-specific colors
  /// - Icon or text based on platform
  ///
  /// Parameters:
  /// [icon] - The icon to display (for Facebook)
  /// [isGoogle] - Whether this is a Google login button
  Widget _buildSocialButton({IconData? icon, bool isGoogle = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      // Decoration for social button
      decoration: BoxDecoration(
        color: isGoogle ? Colors.white : Colors.blue,
        shape: BoxShape.circle,
      ),
      // Show either 'G' text for Google or platform icon
      child:
          isGoogle
              ? const Text(
                'G',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
              : Icon(icon, color: Colors.white, size: 20),
    );
  }
}
