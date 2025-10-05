import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';

class Introduction extends StatelessWidget {
  const Introduction({super.key});
  static const routeName = 'Introduction';

  @override
  Widget build(BuildContext context) {
    final mint = const Color(0xFFE6F3EA);
    final green = const Color(0xFF2E7D32);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية صورة
          Image.asset(
            'assets/bg_welcome.png',
            fit: BoxFit.cover,
          ),

          // (اختياري) طبقة شفافة لتقوية الكونتراست
          Container(color: mint.withOpacity(0.15)),

          // محتوى في منتصف الشاشة
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // يخلي المحتوى يتوسّط عموديًا
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'PetalView',
                    style: GoogleFonts.pacifico(
                      fontSize: 44,
                      color: green,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Join us',
                    style: GoogleFonts.merriweather(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زرار Continue → يروح لصفحة تسجيل الدخول
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Login.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A861),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
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
