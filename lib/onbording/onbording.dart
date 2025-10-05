import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnbordingScreen extends StatelessWidget {
  static const routeName = 'OnboardingScreen';
  const OnbordingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalHeader: Padding(
        padding: EdgeInsetsGeometry.only(top: 60),
        child: Center(child: Image.asset("assets/onboarding/logo.png")),
      ),
      globalBackgroundColor: const Color(0xFFE6F3EA), // الخلفية Mint
      pages: [
        PageViewModel(
          titleWidget: Column(
            children: [
              const SizedBox(height: 16),
            ],
          ),
          bodyWidget: Column(
            children: [
              Text(
                "Tracking the Bloom,\nProtecting the Earth",
                style: GoogleFonts.merriweather(   // ✨ بدل TextStyle
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
               Text(
                "Monitor the impact of climate and\npollution on flowering seasons across the globe.",
                style: GoogleFonts.inter(  // ✨ خط مختلف
                  fontSize: 20,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          image: Image.asset("assets/onboarding/ob1.png", height: 250),
        ),
        PageViewModel(
          titleWidget: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                "Support Sustainability",
                style: GoogleFonts.merriweather(   // ✨ بدل TextStyle
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          bodyWidget:  Text(
            "Discover how renewable energy and\n"
                "eco-friendly farming practices preserve biodiversity.",
            style: GoogleFonts.inter(  // ✨ خط مختلف
              fontSize: 20,
              color: const Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          image: Image.asset("assets/onboarding/ob2.png", height: 250),
        ),
        PageViewModel(
          titleWidget: Column(
            children: [
              const SizedBox(height: 16),
               Align(alignment: Alignment.center,
                 child: Text(
                  "Join the PetalView\n Community",
                  style: GoogleFonts.merriweather(   // ✨ بدل TextStyle
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                               ),
               ),
            ],
          ),
          bodyWidget:  Text(
            "Contribute observations, plant trees,\n"
                "and help restore balance to nature.",
            style: GoogleFonts.inter(  // ✨ خط مختلف
              fontSize: 20,
              color: const Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          image: Image.asset("assets/onboarding/ob3.png", height: 250),
        ),
        PageViewModel(
          titleWidget: Column(
            children: [
              const SizedBox(height: 16),
               Text(
                "Your Role Matters",
                style: GoogleFonts.merriweather(   // ✨ بدل TextStyle
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          bodyWidget:  Text(
            "Every observation helps researchers\n"
                "and communities predict, protect, and plan for the future.",
            style: GoogleFonts.inter(  // ✨ خط مختلف
              fontSize: 20,
              color: const Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          image: Image.asset("assets/onboarding/ob4.png", height: 250),
        ),
      ],
      onDone: () {
        Navigator.of(context).pushReplacementNamed("Introduction");
      },
      skip: const Text("Skip", style: TextStyle(color: Color(0xFF2E7D32))),
      next: const Icon(Icons.arrow_forward, color: Color(0xFF2E7D32)),
      done: const Text(
        "Get Started",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
        ),
      ),
      dotsDecorator: const DotsDecorator(
        activeColor: Color(0xFF2E7D32),
        size: Size(10, 10),
        activeSize: Size(22, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}