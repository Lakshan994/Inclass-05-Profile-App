import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const kNavy = Color(0xFF0F172A), kBlue = Color(0xFF1E3A8A);
const kGold = Color(0xFFFBBF24), kGreen = Color(0xFF10B981);
const _names = ['Bronze', 'Silver', 'Gold', 'Platinum'];
const _min = [0, 100, 300, 600];

int _lvl(int p) => _min.lastIndexWhere((m) => p >= m);
double _prog(int p) {
  final i = _lvl(p);
  return i == 3 ? 1.0 : (p - _min[i]) / (_min[i + 1] - _min[i]);
}

// Global theme switch (light / dark)
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

// ---------------------------------------------------------------------------
// Colors that change with the theme
// ---------------------------------------------------------------------------
class Pal {
  final bool dark;
  Pal(this.dark);
  factory Pal.of(BuildContext c) => Pal(Theme.of(c).brightness == Brightness.dark);

  Color get text => dark ? Colors.white : kNavy;
  Color get sub => dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  Color get glass => dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.55);
  Color get border => dark ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.85);
  Color get sheet => dark ? kNavy.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.85);
  Color get chip => dark ? Colors.white.withValues(alpha: 0.10) : kBlue.withValues(alpha: 0.08);
  Color get accent => dark ? const Color(0xFF3B82F6) : kNavy;
}

// ---------------------------------------------------------------------------
// Glass panel (blur + translucent fill + light border)
// ---------------------------------------------------------------------------
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding, margin;
  final double radius;
  final Color? color;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? p.glass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: p.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient background with soft glowing blobs
// ---------------------------------------------------------------------------
class AppBg extends StatelessWidget {
  final Widget child;
  const AppBg({super.key, required this.child});

  Widget _blob(double size, Color c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0)]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final d = Pal.of(context).dark;
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: d
                ? const [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E1B4B)]
                : const [Color(0xFFE0E7FF), Color(0xFFF1F5F9), Color(0xFFDBEAFE)],
          ),
        ),
      ),
      Positioned(top: -80, right: -60, child: _blob(300, d ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA))),
      Positioned(top: 320, left: -110, child: _blob(280, d ? const Color(0xFF7C3AED) : const Color(0xFFA78BFA))),
      Positioned(bottom: -90, right: -40, child: _blob(280, d ? const Color(0xFF06B6D4) : const Color(0xFF67E8F9))),
      child,
    ]);
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: b),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeMode,
    builder: (_, mode, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const ProfileScreen(),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'Lakshan Aroshana', email = 'gylayapa@students.nsbm.ac.lk';
  int points = 0;
  final List<DateTime> history = [];
  Uint8List? photo;

  // One glass bottom sheet helper for everything
  Future<T?> _sheet<T>(Widget Function(BuildContext) b) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (c) {
      final p = Pal.of(c);
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.of(c).viewInsets.bottom),
        child: SafeArea(
          child: Glass(
            radius: 28,
            color: p.sheet,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.sub.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                b(c),
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _pick(ImageSource s) async {
    final f = await ImagePicker().pickImage(source: s, maxWidth: 800, imageQuality: 85);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() => photo = bytes);
  }

  void _photoMenu() => _sheet((c) => Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(
      leading: const Icon(Icons.photo_library_outlined),
      title: const Text('Choose from gallery'),
      onTap: () {
        Navigator.pop(c);
        _pick(ImageSource.gallery);
      },
    ),
    if (!kIsWeb)
      ListTile(
        leading: const Icon(Icons.photo_camera_outlined),
        title: const Text('Take a photo'),
        onTap: () {
          Navigator.pop(c);
          _pick(ImageSource.camera);
        },
      ),
    if (photo != null)
      ListTile(
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
        onTap: () {
          Navigator.pop(c);
          setState(() => photo = null);
        },
      ),
  ]));

  void _pointsSheet() => _sheet((c) => StatefulBuilder(builder: (c, set) {
    final p = Pal.of(c);
    final i = _lvl(points);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [kNavy, kBlue]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_names[i]} level', style: const TextStyle(color: kGold, fontWeight: FontWeight.w600)),
          Text('$points pts',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _prog(points),
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: Colors.white24,
            color: kGold,
          ),
          const SizedBox(height: 8),
          Text(
            i == 3 ? 'Top level reached' : '${_min[i + 1] - points} more points to ${_names[i + 1]}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Text('RECENT ACTIVITY',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: p.sub, letterSpacing: 1)),
      if (history.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('No activity yet.', style: TextStyle(color: p.sub)),
        )
      else
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView(shrinkWrap: true, children: [
            for (final t in history)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline, color: kGreen),
                title: const Text('Earned points'),
                subtitle: Text(TimeOfDay.fromDateTime(t).format(c)),
                trailing: const Text('+10', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            setState(() {
              points += 10;
              history.insert(0, DateTime.now());
            });
            set(() {});
          },
          icon: const Icon(Icons.add),
          label: const Text('Earn +10 points'),
          style: FilledButton.styleFrom(
            backgroundColor: p.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ]);
  }));

  Future<void> _edit() async {
    final r = await _sheet<List<String>>((c) => _EditForm(name: name, email: email));
    if (r == null || !mounted) return;
    setState(() {
      name = r[0];
      email = r[1];
    });
  }

  Widget _card(IconData icon, String title, String value, {Color? color, VoidCallback? onTap}) {
    final p = Pal.of(context);
    return Glass(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: p.text),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 12, color: p.sub)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? p.text)),
                ]),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.sub),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return AppBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: p.text,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('My Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
          actions: [
            IconButton(
              tooltip: p.dark ? 'Light mode' : 'Dark mode',
              icon: Icon(p.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: () => themeMode.value = p.dark ? ThemeMode.light : ThemeMode.dark,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ---------------- Header (glass) ----------------
            Glass(
              radius: 32,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  GestureDetector(
                    onTap: _photoMenu,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: p.dark ? Colors.white24 : Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: photo == null ? null : MemoryImage(photo!),
                          child: photo == null
                              ? const Icon(Icons.person, size: 70, color: Color(0xFF64748B))
                              : null,
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Color(0xFF2563EB),
                            child: Icon(Icons.photo_camera, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: p.text)),
                  const SizedBox(height: 4),
                  Text('NSBM Student', style: TextStyle(fontSize: 14, color: p.sub)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.workspace_premium, color: kGold, size: 18),
                      const SizedBox(width: 6),
                      Text('${_names[_lvl(points)]} • $points pts',
                          style: TextStyle(color: p.text, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Text('ACCOUNT INFORMATION',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: p.sub, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _card(Icons.person_outline, 'Full Name', name),
            _card(Icons.mail_outline, 'Email Address', email),
            _card(Icons.star_border_rounded, 'Points Earned (tap to view)', '$points Points',
                color: const Color(0xFFD97706), onTap: _pointsSheet),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _edit,
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _EditForm extends StatefulWidget {
  final String name, email;
  const _EditForm({required this.name, required this.email});
  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _key = GlobalKey<FormState>();
  late final _n = TextEditingController(text: widget.name);
  late final _e = TextEditingController(text: widget.email);

  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    super.dispose();
  }

  InputDecoration _dec(String l, IconData i) {
    final p = Pal.of(context);
    return InputDecoration(
      labelText: l,
      prefixIcon: Icon(i),
      filled: true,
      fillColor: p.chip,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  void _save() {
    if (_key.currentState!.validate()) Navigator.pop(context, [_n.text.trim(), _e.text.trim()]);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Form(
      key: _key,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          controller: _n,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _dec('Full Name', Icons.person_outline),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _e,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _save(),
          decoration: _dec('Email Address', Icons.mail_outline),
          validator: (v) => RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch((v ?? '').trim())
              ? null
              : 'Enter a valid email',
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: p.accent, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ),
        ]),
      ]),
    );
  }
}