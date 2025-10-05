import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  static const routeName = 'Explore';

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Theme
  static const green = Color(0xFF2E7D32);
  static const mint = Color(0xFFE6F3EA);
  static const mintCard = Color(0xFFDFF0E3);
  static const cardShadow = BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6));

  final TextEditingController _searchCtrl = TextEditingController();
  final _debounce = Duration(milliseconds: 250);

  List<PlantSpot> _all = [];
  List<PlantSpot> _results = [];
  Timer? _debouncer;

  // filters
  String _quality = 'any'; // any/high/medium/low

  // search history
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHistory();
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final txt = await rootBundle.loadString(
      'assets/data/WildflowerBlooms_AreaOfInterest.geojson',
    );
    final jsonMap = json.decode(txt) as Map<String, dynamic>;
    final feats = (jsonMap['features'] as List).cast<Map<String, dynamic>>();

    // Map -> PlantSpot (حقول: الاسم، الوصف، الجودة، اليوم، lat/lng، صورة إن وُجدت)
    _all = feats.map((f) {
      final p = (f['properties'] as Map).map((k, v) => MapEntry(k.toString(), v));
      return PlantSpot(
        plant: (p['Plant'] ?? '').toString(),
        desc: (p['Location Description'] ?? '').toString(),
        quality: (p['Location Quality'] ?? '').toString().toLowerCase(),
        lat: double.tryParse(p['Latitude']?.toString() ?? ''),
        lng: double.tryParse(p['Longitude']?.toString() ?? ''),
        // Photo URL في الداتا راجع غالباً لموقع أصلي بدون دومين،
        // فبنستخدم صور ثابتة من Picsum كـ placeholder حسب اسم النبات.
        photoUrlSeed: (p['Plant'] ?? '').toString(),
      );
    }).toList();

    // default: مفيش بحث → بنعرض التاريخ/مساحة فاضية
    if (mounted) setState(() => _results = []);
  }

  Future<void> _loadHistory() async {
    final sp = await SharedPreferences.getInstance();
    setState(() => _history = sp.getStringList('explore_history') ?? []);
  }

  Future<void> _saveHistory() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('explore_history', _history);
  }

  void _onSearchChanged(String q) {
    _debouncer?.cancel();
    _debouncer = Timer(_debounce, () => _runSearch(q));
  }

  void _runSearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    // filter quality + text
    final filtered = _all.where((s) {
      final qualityOK = _quality == 'any' ? true : s.quality == _quality;
      if (!qualityOK) return false;
      final t = '${s.plant} ${s.desc}'.toLowerCase();
      return t.contains(query);
    }).take(150).toList(); // cap للآداء

    // history
    if (query.isNotEmpty) {
      _history.remove(query);
      _history.insert(0, query);
      if (_history.length > 10) _history = _history.sublist(0, 10);
      _saveHistory();
    }

    setState(() => _results = filtered);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        String temp = _quality;
        return StatefulBuilder(
          builder: (ctx, setM) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 36, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text('Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('any', temp == 'any', (v) => setM(() => temp = 'any')),
                    _chip('high', temp == 'high', (v) => setM(() => temp = 'high')),
                    _chip('medium', temp == 'medium', (v) => setM(() => temp = 'medium')),
                    _chip('low', temp == 'low', (v) => setM(() => temp = 'low')),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: green, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _quality = temp);
                      _runSearch(_searchCtrl.text);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ChoiceChip _chip(String label, bool selected, void Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: mintCard,
      onSelected: onSelected,
    );
  }

  void _clearHistory() async {
    setState(() => _history.clear());
    await _saveHistory();
  }

  void _useHistoryItem(String q) {
    _searchCtrl.text = q;
    _runSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Image.asset('assets/onboarding/logo.png', height: 40),
                  const Spacer(),
                  IconButton(
                      onPressed: () {}, icon: const Icon(Icons.notifications_none, color: green)),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [cardShadow],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black45),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.poppins(color: Colors.black45),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {}, icon: const Icon(Icons.mic_none, color: green)),
                    IconButton(
                        onPressed: _openFilters, icon: const Icon(Icons.tune_rounded, color: green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Body: history or results
            Expanded(
              child: _results.isEmpty
                  ? _HistoryView(
                history: _history,
                onClearAll: _clearHistory,
                onTapItem: _useHistoryItem,
              )
                  : _ResultsList(results: _results),
            ),
          ],
        ),
      ),
      backgroundColor: mint,
    );
  }
}

/* ----------------------- MODELS ----------------------- */

class PlantSpot {
  final String plant;
  final String desc;
  final String quality; // high/medium/low
  final double? lat;
  final double? lng;
  final String photoUrlSeed; // بنستخدمه لتوليد صورة ثابتة من Picsum

  PlantSpot({
    required this.plant,
    required this.desc,
    required this.quality,
    required this.lat,
    required this.lng,
    required this.photoUrlSeed,
  });

  // صورة ثابتة من Picsum (seed = plant name)
  String get imageUrl =>
      'https://picsum.photos/seed/${Uri.encodeComponent(photoUrlSeed.isEmpty ? plant : photoUrlSeed)}/400/260';
}

/* ----------------------- WIDGETS ---------------------- */

class _HistoryView extends StatelessWidget {
  const _HistoryView({
    required this.history,
    required this.onClearAll,
    required this.onTapItem,
  });

  final List<String> history;
  final VoidCallback onClearAll;
  final ValueChanged<String> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text('Search history', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: onClearAll,
                child: Text('Clear All', style: GoogleFonts.poppins(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('Start exploring blooms…', style: GoogleFonts.poppins(color: Colors.black54)),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Color(0xFF2E7D32)),
                  title: Text(history[i]),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                  onTap: () => onTapItem(history[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<PlantSpot> results;

  Color _qualityChip(String q) {
    switch (q) {
      case 'high':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFF66A36B);
      case 'low':
        return const Color(0xFF9CC8A1);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة مع Placeholder وفالباك
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: p.imageUrl,
                  fit: BoxFit.cover,
                  height: 160,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: const Color(0xFFDFF0E3),
                    child: const Center(
                      child: SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF2E7D32))),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFFDFF0E3),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: Color(0xFF2E7D32)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.plant.isEmpty ? 'Unknown plant' : p.plant,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (p.desc.isNotEmpty)
                      Text(p.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _qualityChip(p.quality).withOpacity(.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p.quality.isEmpty ? 'quality: n/a' : p.quality,
                              style: GoogleFonts.poppins(color: _qualityChip(p.quality), fontSize: 12)),
                        ),
                        const Spacer(),
                        if (p.lat != null && p.lng != null)
                          Row(
                            children: [
                              const Icon(Icons.place, size: 16, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text('${p.lat!.toStringAsFixed(2)}, ${p.lng!.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
