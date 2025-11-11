import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petalview/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  static const routeName = 'login';
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFF23C16B);
  static const borderLight = Color(0xFFDAEFDE);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ديكور موحّد للحقول
  InputDecoration _dec(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  // فالاتيدتورز
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) return 'Use letters and numbers';
    return null;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    // Don't submit if invalid or already loading
    if (!valid || _isLoading) return;

    // Start loading
    setState(() => _isLoading = true);

    try {
      // 1. This is the magic line for logging in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      // 2. Navigate on success
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('home');
      }
    } on FirebaseAuthException catch (e) {
      // 3. Handle specific login errors
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // 4. Handle any other unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Stop loading, whether it succeeded or failed
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    // 1. Get the email from the controller
    final String email = _email.text.trim();

    // 2. Show a SnackBar if email is empty
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to reset password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 3. Send the reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // 4. Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox!'),
            backgroundColor: green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 5. Show an error message
      String message = 'Error: ${e.message}';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: mint.withOpacity(0.15)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Image.asset('assets/onboarding/logo.png', height: 56),
                  const SizedBox(height: 16),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Log in',
                            style: GoogleFonts.merriweather(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('Email address'),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _dec(
                              'Password',
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            validator: _passwordValidator,
                          ),
                          const SizedBox(height: 12),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Forgot your Password? ',
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _forgotPassword,
                                      child: Text(
                                        'Click here',
                                        style: GoogleFonts.merriweather(
                                          color: green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Log in button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Log in',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // divider "Continue with"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  'Continue with',
                                  style: GoogleFonts.merriweather(fontSize: 12),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // social buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              _SocialButton(asset: 'assets/icons/google.png'),
                              _SocialButton(asset: 'assets/icons/apple.png'),
                              _SocialButton(asset: 'assets/icons/facbook.png'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // OR
                          Center(
                            child: Text(
                              'OR',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Continue as a guest
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: green,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('home');
                              },
                              child: Text(
                                'Continue as a guest',
                                style: GoogleFonts.poppins(
                                  color: green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Don't have an account? Sign up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Signup.routeName,
                                  );
                                },
                                child: Text(
                                  "Sign up",
                                  style: GoogleFonts.poppins(
                                    color: green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// زرار سوشيال بشكل كارت صغير مستدير
class _SocialButton extends StatelessWidget {
  final String asset;
  const _SocialButton({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(asset, height: 32),
    );
  }
}
