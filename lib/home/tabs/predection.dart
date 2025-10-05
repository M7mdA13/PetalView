import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class PredectionScreen extends StatefulWidget {
  const PredectionScreen({super.key});
  static const routeName = 'Predection';

  @override
  State<PredectionScreen> createState() => _PredectionScreenState();
}

class _PredectionScreenState extends State<PredectionScreen> {
  // THEME
  static const green    = Color(0xFF2E7D32);
  static const mint     = Color(0xFFE6F3EA);
  static const mintCard = Color(0xFFDFF0E3);
  static const cardShadow = BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6));

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final String _apiUrl =
      "https://betty-noncommunicative-hyon.ngrok-free.dev/predict";

  // Predefined locations
  final Map<String, Map<String, double>> _locations = const {
    "Cairo": {"lat": 30.0444, "lng": 31.2357},
    "Alexandria": {"lat": 31.2001, "lng": 29.9187},
    "Giza": {"lat": 30.0131, "lng": 31.2089},
  };

  String? _selectedLocation;

  Future<void> _sendPrediction(double lat, double lng) async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"feature1": lat, "feature2": lng}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double predValue;

        if (data is Map && data.containsKey('prediction')) {
          final outerList = data['prediction'];
          predValue = (outerList[0][0] as num).toDouble();
        } else if (data is List) {
          predValue = (data[0][0] as num).toDouble();
        } else {
          throw Exception("Unexpected response format: $data");
        }

        final isBlooming = predValue >= 0.5;

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PredictionResultScreen(
              blooming: isBlooming,
              latitude: lat,
              longitude: lng,
              locationName: _selectedLocation ?? "Custom Location",
            ),
          ),
        );
      } else {
        throw Exception("Prediction failed (HTTP ${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text("Error: $e", style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB7E0C2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB7E0C2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mint,
      appBar: AppBar(
        backgroundColor: green,
        centerTitle: true,
        elevation: 0,
        title: Text('PetalView', style: GoogleFonts.pacifico(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
        child: Column(
          children: [
            // Card: اختيار الموقع + إدخال الإحداثيات
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: mintCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [cardShadow],
                border: Border.all(color: const Color(0xFFB7E0C2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select a Location',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB7E0C2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocation,
                        hint: Text("Choose a location", style: GoogleFonts.inter(color: Colors.black54)),
                        iconEnabledColor: green,
                        items: _locations.keys
                            .map((loc) => DropdownMenuItem(value: loc, child: Text(loc, style: GoogleFonts.poppins())))
                            .toList(),
                        onChanged: _loading
                            ? null
                            : (value) {
                          setState(() {
                            _selectedLocation = value;
                            _latController.text = _locations[value]!["lat"].toString();
                            _lngController.text = _locations[value]!["lng"].toString();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Or enter latitude & longitude manually',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: _input("Latitude"),
                          validator: (v) {
                            final d = double.tryParse((v ?? '').trim());
                            if (d == null) return 'Enter a valid latitude';
                            if (d < -90 || d > 90) return 'Latitude must be between -90 and 90';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: _input("Longitude"),
                          validator: (v) {
                            final d = double.tryParse((v ?? '').trim());
                            if (d == null) return 'Enter a valid longitude';
                            if (d < -180 || d > 180) return 'Longitude must be between -180 and 180';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                  FocusScope.of(context).unfocus();
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  final lat = double.parse(_latController.text.trim());
                  final lng = double.parse(_lngController.text.trim());
                  _sendPrediction(lat, lng);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
                    : Text("Predict Bloom", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              "Tip: Results are a binary bloom prediction based on your coordinates.",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PredictionResultScreen extends StatelessWidget {
  final bool blooming;
  final double latitude;
  final double longitude;
  final String locationName;

  const PredictionResultScreen({
    super.key,
    required this.blooming,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  // THEME (keep consistent here too)
  static const green    = Color(0xFF2E7D32);
  static const mint     = Color(0xFFE6F3EA);
  static const mintCard = Color(0xFFDFF0E3);

  @override
  Widget build(BuildContext context) {
    final Color bg = blooming ? mint : mint; // نفس الخلفية
    final Color iconColor = blooming ? green : Colors.redAccent;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,
        title: Text('Prediction Result', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                blooming ? Icons.local_florist : Icons.block,
                size: 96,
                color: iconColor,
              ),
              const SizedBox(height: 16),
              Text(
                blooming ? "🌸 Blooming!" : "❌ Not Blooming",
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: iconColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Location: $locationName\n(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: mintCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  blooming ? "Likely blooming conditions" : "Unfavorable blooming conditions",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text("Back", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
