import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatelessWidget {
  final String userName;
  const AccountScreen({super.key, this.userName = "Sofia"});
  static const routeName = 'Account';

  // ثوابت ألوان
  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFFDAEFDE);
  static const barGreen = Color(0xFF1E7E5A);
  static const pastelChip = Color(0xFFFFE0B2); // لون المؤشر في البار (لو حابة)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // لو الشاشة ضمن Tabs بتركبيها بدون appBar
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية زخرفية
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: mint.withOpacity(0.15)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // لوجو الكلمة
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/onboarding/logo.png',
                    height: 52,
                  ),
                ),
                const SizedBox(height: 32),

                // الأفاتار (دائرة) مع قلب صغير وأيقونة قلم للتعديل
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.perm_identity_sharp, size: 90, color: Colors.black),
                      ),
                      // قلب صغير
                      const Positioned(
                        right: 30,
                        top: 50,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.favorite, size: 30, color: Color(0xffFCD9BB)),
                        ),
                      ),
                      // قلم تعديل
                      Positioned(
                        bottom: -12,
                        right: 56,
                        child: InkWell(
                          onTap: () {
                            // TODO: تغيير الصورة/فتح محرر الملف الشخصي
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit, size: 18, color: barGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // التحية Hello, Sofia!
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hello, ",
                      style: GoogleFonts.merriweather(
                        fontSize: 22,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$userName!",
                      style: GoogleFonts.merriweather(
                        fontSize: 30,
                        color: barGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // الكارت الأبيض بالأزرار
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                  child: Column(
                    children: [
                      _AccountButton(
                        text: "SOS",
                        onPressed: () {
                          // TODO: افتحي صفحة الطلبات
                          // Navigator.pushNamed(context, '/orders');
                        },
                      ),
                      const SizedBox(height: 12),
                      _AccountButton(
                        text: "Settings",
                        onPressed: () {
                          // TODO: صفحة الإعدادات
                          // Navigator.pushNamed(context, '/settings');
                        },
                      ),
                      const SizedBox(height: 12),


                      _AccountButton(
                        text: "About us",
                        onPressed: () {
                          // TODO: صفحة about
                          // Navigator.pushNamed(context, '/about');
                        },
                      ),
                      const SizedBox(height: 12),
                      _AccountButton(
                        text: "Sign out",
                        filled: true, // خليها بارزة لو حابة
                        onPressed: () async {
                          // TODO: signOut()  (Firebase/Auth)
                          Navigator.pushReplacementNamed(context, 'signin');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      // ملاحظة: لو بتستخدمي البار المخصّص اللي عملناه قبل كده، سيبي bottomNavigationBar هناك
    );
  }
}

/// زر مطابق للتصميم (مستدير الحواف، سماكة حدود خفيفة، مع خيار Filled)
class _AccountButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;

  const _AccountButton({
    required this.text,
    required this.onPressed,
    this.filled = false,
  });

  static const green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            text,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: green, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.merriweather(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
