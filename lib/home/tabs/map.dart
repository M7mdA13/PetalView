import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  static const routeName = 'Map';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // THEME
  static const green    = Color(0xFF2E7D32);
  static const mint     = Color(0xFFE6F3EA);
  static const mintCard = Color(0xFFDFF0E3);
  static const cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 10,
    offset: Offset(0, 6),
  );

  double _daysOffset = 0;
  String _selectedLayer = 'NDVI';
  bool _isLoading = true;
  String? _dataMessage;

  // NDVI & EVI WMTS (NASA GIBS)
  String _nasaLayerUrl(String layer, DateTime date) {
    // 👈 لازم تكون بشرطات مش سلاشات
    final formattedDateForTiles = DateFormat('yyyy-MM-dd').format(date);
    if (layer == 'NDVI') {
      return "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_L3_NDVI_16Day/default/$formattedDateForTiles/GoogleMapsCompatible_Level9/{z}/{y}/{x}.png";
    } else if (layer == 'EVI') {
      return "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_L3_EVI_16Day/default/$formattedDateForTiles/GoogleMapsCompatible_Level9/{z}/{y}/{x}.png";
    } else {
      return "";
    }
  }

  // أقرب تاريخ صالح (كل 16 يوم) لبيانات MODIS
  DateTime _nearestValidDate(DateTime target) {
    final base = DateTime(2000, 2, 18);
    final diffDays = target.difference(base).inDays;
    final snappedDays = (diffDays ~/ 16) * 16;
    return base.add(Duration(days: snappedDays));
  }

  @override
  Widget build(BuildContext context) {
    final requestedDate = DateTime.now().subtract(Duration(days: _daysOffset.toInt()));
    final validDate = _nearestValidDate(requestedDate);
    final nasaUrl = _nasaLayerUrl(_selectedLayer, validDate);

    // رسالة في حال التاريخ المطلوب بعيد عن أقرب تاريخ صالح
    if ((requestedDate.difference(validDate).inDays).abs() > 8) {
      _dataMessage =
      "⚠️ No $_selectedLayer data for ${DateFormat('yyyy/MM/dd').format(requestedDate)}.\nNearest: ${DateFormat('yyyy/MM/dd').format(validDate)}";
    } else {
      _dataMessage = null;
    }

    return Scaffold(
      backgroundColor: mint,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "PetalView",
          style: GoogleFonts.pacifico(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط الإعدادات العلوي (الطبقة + معلومات)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: mintCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [cardShadow],
                border: Border.all(color: const Color(0xFFB7E0C2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.layers_outlined, color: green),
                  const SizedBox(width: 8),
                  Text("Layer:  ",
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87,
                      )),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFB7E0C2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLayer,
                        iconEnabledColor: green,
                        style: GoogleFonts.inter(color: Colors.black87),
                        items: const [
                          DropdownMenuItem(
                            value: 'NDVI',
                            child: Row(
                              children: [
                                Icon(Icons.grass, color: green, size: 18),
                                SizedBox(width: 10),
                                Text("NDVI(Vegetation Index)"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'EVI',
                            child: Row(
                              children: [
                                Icon(Icons.eco, color: green, size: 18),
                                SizedBox(width: 10),
                                Text("EVI(Enhanced Vegetation)"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLayer = value!;
                            _isLoading = true;
                          });
                        },
                      ),
                    ),
                  ),
                  Tooltip(
                    message:
                    "NDVI = Normalized Difference Vegetation Index\nEVI = Enhanced Vegetation Index\n(16-day MODIS Terra composites)",
                    textStyle: GoogleFonts.poppins(color: Colors.white),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.black54),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text("Layer Information", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                            content: Text(
                              "🟢 NDVI shows general vegetation health.\n"
                                  "🌿 EVI enhances sensitivity for high biomass regions.\n\n"
                                  "Both are 16-day NASA MODIS Terra composites.",
                              style: GoogleFonts.poppins(height: 1.3),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK", style: GoogleFonts.poppins(color: green, fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // الخريطة + لودر + رسالة
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    center: LatLng(30.0444, 31.2357), // Cairo
                    zoom: 5.0,
                    minZoom: 2.0,
                    maxZoom: 9.0, // مستوى GIBS
                  ),
                  children: [
                    // Base map
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.petalview.app',
                    ),
                    // NASA vegetation tiles
                    TileLayer(
                      urlTemplate: nasaUrl,
                      userAgentPackageName: 'com.petalview.app',
                      tileProvider:  NetworkTileProvider(),
                      tileBuilder: (context, tileWidget, tile) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_isLoading) setState(() => _isLoading = false);
                        });
                        return tileWidget;
                      },
                    ),
                  ],
                ),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: green),
                  ),

                if (_dataMessage != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _dataMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // التايملاين (سلايدر) بنفس الثيم
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Timeline (Last 2 Years)",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: green,
                      inactiveTrackColor: mintCard,
                      thumbColor: green,
                      overlayColor: green.withOpacity(0.15),
                      valueIndicatorColor: green,
                      valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white),
                    ),
                    child: Slider(
                      value: _daysOffset,
                      min: 0,
                      max: 730, // سنتين
                      divisions: 45,
                      label:
                      "${DateFormat('yyyy-MM-dd').format(requestedDate)} (${_daysOffset.toInt()}d ago)",
                      onChanged: (value) {
                        setState(() {
                          _isLoading = true;
                          _daysOffset = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _dateChip("Requested", requestedDate),  // عرض UI بس
                      const SizedBox(width: 8),
                      _dateChip("Displayed", validDate),      // التاريخ الفعلي للتايلز
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chip أنيق لعرض التواريخ
  Widget _dateChip(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mintCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB7E0C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 14, color: green),
          const SizedBox(width: 6),
          Text(
            // نعرض بالسلاشات عشان الشكل فقط
            "$label: ${DateFormat('yyyy/MM/dd').format(date)}",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
