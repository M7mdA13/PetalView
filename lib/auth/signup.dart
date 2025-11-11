import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petalview/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  static const routeName = 'SignUp';
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  // ألوان ثابتة
  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFF23C16B);
  static const borderLight = Color(0xFFDAEFDE);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

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

  // فحص الإيميل
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailReg = RegExp(r'^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$');
    if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _nonEmpty(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    if (v.trim().length < 2) return '$field is too short';
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

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Store the result of creating the user in a new variable
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text.trim(),
          );

      // 2. NOW you can create the 'uid' variable from that result
      final String uid = userCredential.user!.uid;

      // 3. This line will now work perfectly
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bg_welcome.png", fit: BoxFit.cover),
          Container(color: mint.withOpacity(0.15)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          Text(
                            "Sign Up",
                            style: GoogleFonts.merriweather(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First name
                          TextFormField(
                            controller: _firstName,
                            decoration: _dec("First name"),
                            validator: (v) => _nonEmpty(v, 'First name'),
                          ),
                          const SizedBox(height: 12),

                          // Last name
                          TextFormField(
                            controller: _lastName,
                            decoration: _dec("Last name"),
                            validator: (v) => _nonEmpty(v, 'Last name'),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec("Email address"),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePass,
                            decoration: _dec(
                              "Password",
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass,
                                ),
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            validator: _passwordValidator,
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscureConfirm,
                            decoration: _dec(
                              "Confirm Password",
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            validator: _confirmValidator,
                          ),
                          const SizedBox(height: 20),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _submit,
                              child:
                                  _isLoading // <-- CHECK THE FLAG HERE
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      "Sign Up",
                                      style: GoogleFonts.merriweather(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Continue with Social
                          Row(
                            children: const [
                              Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("Continue with"),
                              ),
                              Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              _SocialButton(asset: 'assets/icons/google.png'),
                              _SocialButton(asset: 'assets/icons/apple.png'),
                              _SocialButton(asset: 'assets/icons/facbook.png'),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Text("OR"),
                          const SizedBox(height: 16),

                          // Continue as guest
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: green,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: () {
                                // ضيف/Guest → خش على الهوم
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('home');
                              },
                              child: Text(
                                "Continue as a guest",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Already have account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Login.routeName);
                                },
                                child: Text(
                                  "Log in",
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
