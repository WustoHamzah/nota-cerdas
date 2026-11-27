import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Palet Warna (sama dengan landing & login) ────────────
  static const Color _bg = Color(0xFF0D1117);
  static const Color _surface = Color(0xFF161B22);
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryLight = Color(0xFF818CF8);
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _success = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _pink = Color(0xFFEC4899);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [Color(0xFF1A1040), Color(0xFF0D1117)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _btnGradient = LinearGradient(
    colors: [_primaryLight, _primary, _accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const double _wideBreakpoint = 900;

  // ── State ────────────────────────────────────────────────
  String _nama = 'Pengguna';
  String _email = '';
  int _tab = 0;

  // ── Data contoh (TODO: ganti dengan data dari ApiService) ─
  final int _totalBulanIni = 2450000;
  final int _anggaran = 3000000;
  final int _jumlahNota = 48;
  final int _belumLunas = 3;

  final List<String> _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _hariPenuh = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<int> _mingguan = [120, 80, 200, 150, 90, 260, 180]; // ribuan Rp

  final List<Map<String, dynamic>> _kategori = [
    {'nama': 'Makan & Minum', 'persen': 0.42, 'nilai': 1029000, 'warna': const Color(0xFF6366F1), 'icon': Icons.restaurant_rounded},
    {'nama': 'Transportasi', 'persen': 0.23, 'nilai': 563500, 'warna': const Color(0xFF8B5CF6), 'icon': Icons.directions_car_rounded},
    {'nama': 'Belanja', 'persen': 0.20, 'nilai': 490000, 'warna': const Color(0xFF22C55E), 'icon': Icons.shopping_bag_rounded},
    {'nama': 'Lainnya', 'persen': 0.15, 'nilai': 367500, 'warna': const Color(0xFFF59E0B), 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _notaTerbaru = [
    {'judul': 'Kopi Kenangan', 'tanggal': 'Hari ini, 09:12', 'total': 36000, 'lunas': true, 'icon': Icons.local_cafe_rounded, 'warna': const Color(0xFFF59E0B)},
    {'judul': 'Indomaret', 'tanggal': 'Kemarin, 18:40', 'total': 128500, 'lunas': true, 'icon': Icons.storefront_rounded, 'warna': const Color(0xFF22C55E)},
    {'judul': 'Grab Ride', 'tanggal': 'Kemarin, 07:55', 'total': 42000, 'lunas': false, 'icon': Icons.directions_car_rounded, 'warna': const Color(0xFF8B5CF6)},
    {'judul': 'Warung Bu Tini', 'tanggal': '25 Nov, 12:30', 'total': 27000, 'lunas': true, 'icon': Icons.restaurant_rounded, 'warna': const Color(0xFF6366F1)},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nama = prefs.getString('nama') ?? 'Pengguna';
      _email = prefs.getString('email') ?? '';
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Anda harus login lagi untuk mengakses nota.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: _danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('nama');
    await prefs.remove('email');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _soon(String fitur) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$fitur segera hadir'),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
  }

  String _rp(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  String get _salam {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scaler = media.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);

    return MediaQuery(
      data: media.copyWith(textScaler: scaler),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: Container(
            decoration: const BoxDecoration(gradient: _heroGradient),
            child: Stack(
              children: [
                Positioned(top: -100, right: -100, child: _orb(380, _primary, 0.15)),
                Positioned(bottom: 120, left: -150, child: _orb(320, _accent, 0.10)),
                LayoutBuilder(
                  builder: (ctx, cons) =>
                      cons.maxWidth >= _wideBreakpoint ? _wide() : _compact(ctx, cons.maxWidth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LAYOUT KOMPAK (HP & tablet portrait)
  // ══════════════════════════════════════════════════════════
  Widget _compact(BuildContext ctx, double width) {
    final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
    final hPad = width < 360 ? 14.0 : 20.0;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Stack(
            children: [
              _animatedIn(
                ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 120 + bottomInset),
                  children: [
                    _compactHeader(),
                    const SizedBox(height: 22),
                    _summaryCard(),
                    const SizedBox(height: 22),
                    _quickActions(),
                    const SizedBox(height: 22),
                    _insightCard(),
                    const SizedBox(height: 22),
                    _weeklyChart(),
                    const SizedBox(height: 28),
                    _categories(),
                    const SizedBox(height: 28),
                    _recentNotes(),
                  ],
                ),
              ),
              // Fade di bawah agar konten tidak "bocor" di belakang bottom nav
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 130 + bottomInset,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_bg.withValues(alpha: 0), _bg.withValues(alpha: 0.92), _bg],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomNav(bottomInset, hPad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactHeader() {
    return Row(
      children: [
        _avatar(48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_salam 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
              const SizedBox(height: 2),
              Text(_nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _notifButton(),
        const SizedBox(width: 8),
        _profileMenu(),
      ],
    );
  }

  Widget _bottomNav(double bottomInset, double hPad) {
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 0, hPad, 12 + bottomInset),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_rounded, 'Beranda'),
          _navItem(1, Icons.receipt_long_rounded, 'Riwayat'),
          Expanded(
            child: GestureDetector(
              onTap: () => _soon('Scan nota'),
              child: Container(
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: _btnGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
          _navItem(2, Icons.pie_chart_rounded, 'Laporan'),
          _navItem(3, Icons.person_rounded, 'Profil'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _tab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (index == 0) {
            setState(() => _tab = 0);
          } else {
            _soon(label);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: active ? _primaryLight : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: active ? _primaryLight : Colors.white.withValues(alpha: 0.4))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LAYOUT LEBAR (laptop / web): sidebar + konten grid
  // ══════════════════════════════════════════════════════════
  Widget _wide() {
    return Row(
      children: [
        _sidebar(),
        Expanded(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _animatedIn(
                  ListView(
                    padding: const EdgeInsets.fromLTRB(36, 28, 36, 40),
                    children: [
                      _wideTopBar(),
                      const SizedBox(height: 28),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: _summaryCard()),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _quickActions(grid: true)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _insightCard(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _weeklyChart()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _categories()),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _recentNotes(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.85),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _logoBadge(44, 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Nota Cerdas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              _sideItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _sideItem(1, Icons.receipt_long_rounded, 'Riwayat Nota'),
              _sideItem(2, Icons.document_scanner_rounded, 'Scan Nota'),
              _sideItem(3, Icons.pie_chart_rounded, 'Laporan'),
              const Spacer(),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _btnGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _soon('Scan nota'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Nota Baru',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDeco(radius: 16),
                child: Row(
                  children: [
                    _avatar(38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                          if (_email.isNotEmpty)
                            Text(_email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Keluar',
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: _danger, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideItem(int index, IconData icon, String label) {
    final active = _tab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (index == 0) {
            setState(() => _tab = 0);
          } else {
            _soon(label);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active ? _primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? _primary.withValues(alpha: 0.4) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: active ? _primaryLight : Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.6))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_salam 👋',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
              const SizedBox(height: 4),
              Text('Halo, $_nama',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _notifButton(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  KOMPONEN BERSAMA
  // ══════════════════════════════════════════════════════════
  Widget _avatar(double size) {
    final inisial = _nama.trim().isEmpty ? '?' : _nama.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _btnGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: Text(inisial,
          style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w900)),
    );
  }

  Widget _notifButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _soon('Notifikasi'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDeco(radius: 14),
        child: Stack(
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileMenu() {
    return PopupMenuButton<String>(
      color: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 50),
      onSelected: (v) {
        if (v == 'logout') _logout();
        if (v == 'profil') _soon('Profil');
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(_email.isEmpty ? _nama : _email,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'profil',
          child: Row(children: [
            Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Profil', style: TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout_rounded, color: _danger, size: 20),
            SizedBox(width: 10),
            Text('Keluar', style: TextStyle(color: _danger)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDeco(radius: 14),
        child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Kartu Ringkasan ──────────────────────────────────────
  Widget _summaryCard() {
    final double pakai = (_totalBulanIni / _anggaran).clamp(0.0, 1.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _btnGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.45), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Dekorasi lingkaran
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Pengeluaran bulan ini',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_down_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('12%',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_rp(_totalBulanIni),
                      maxLines: 1,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ),
                const SizedBox(height: 4),
                Text('Lebih hemat dari bulan lalu',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
                const SizedBox(height: 18),
                // Progress anggaran
                Row(
                  children: [
                    Expanded(
                      child: Text('Anggaran ${_rp(_anggaran)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ),
                    Text('${(pakai * 100).round()}% terpakai',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pakai),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      _miniStat('$_jumlahNota', 'Total nota'),
                      _vDivider(),
                      _miniStat('$_belumLunas', 'Belum lunas'),
                      _vDivider(),
                      _miniStat(_rp((_totalBulanIni / 30).round()).replaceFirst('Rp ', ''), 'Rata-rata/hari'),
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

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2));

  // ── Aksi Cepat (semua kotak berukuran sama) ──────────────
  // grid = true → 2x2 horizontal (layout lebar); false → 4 kolom (HP)
  Widget _quickActions({bool grid = false}) {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.document_scanner_rounded, 'label': 'Scan Nota', 'color': _primaryLight},
      {'icon': Icons.edit_note_rounded, 'label': 'Tambah Manual', 'color': _success},
      {'icon': Icons.bar_chart_rounded, 'label': 'Laporan', 'color': _warning},
      {'icon': Icons.category_rounded, 'label': 'Kategori', 'color': _pink},
    ];

    Widget item(int i) => _actionItem(
          items[i]['icon'] as IconData,
          items[i]['label'] as String,
          items[i]['color'] as Color,
          () => _soon(items[i]['label'] as String),
          horizontal: grid,
        );

    if (grid) {
      return Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: item(0)), const SizedBox(width: 14), Expanded(child: item(1))],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: item(2)), const SizedBox(width: 14), Expanded(child: item(3))],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: item(i)),
        ],
      ],
    );
  }

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap, {bool horizontal = false}) {
    final iconBox = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 23),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: horizontal ? null : 128, // tinggi tetap + ruang cadangan → semua kotak sama
          padding: EdgeInsets.symmetric(horizontal: horizontal ? 16 : 6, vertical: 12),
          decoration: _cardDeco(radius: 22),
          child: horizontal
              ? Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconBox,
                    const SizedBox(height: 8),
                    // Area label tinggi tetap (muat 2 baris) agar semua kotak seragam
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Insight Cerdas ───────────────────────────────────────
  Widget _insightCard() {
    int maxIdx = 0;
    for (int i = 1; i < _mingguan.length; i++) {
      if (_mingguan[i] > _mingguan[maxIdx]) maxIdx = i;
    }
    final nilai = _rp(_mingguan[maxIdx] * 1000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_warning.withValues(alpha: 0.16), _warning.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: _warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Insight Cerdas',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Pengeluaran tertinggi minggu ini jatuh di hari ${_hariPenuh[maxIdx]} ($nilai). '
                  'Cek nota hari itu untuk cari yang bisa dihemat.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grafik Mingguan (tanpa overflow) ─────────────────────
  Widget _weeklyChart() {
    final maxVal = _mingguan.reduce((a, b) => a > b ? a : b);
    final total = _mingguan.fold<int>(0, (a, b) => a + b) * 1000;
    const chartH = 200.0;
    const dayLabelH = 26.0;
    const valueLabelH = 22.0; // 16 teks + 6 jarak

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: _cardDeco(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengeluaran Mingguan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Total ${_rp(total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('7 hari',
                    style: TextStyle(color: _primaryLight, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: chartH,
            child: Stack(
              children: [
                // Garis bantu
                Positioned.fill(
                  bottom: dayLabelH,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (_) => Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                    ),
                  ),
                ),
                // Batang
                Row(
                  children: List.generate(_mingguan.length, (i) {
                    final v = _mingguan[i];
                    final isMax = v == maxVal;
                    return Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, c) {
                                final maxBar = (c.maxHeight - valueLabelH - 4).clamp(0.0, 400.0);
                                final h = (v / maxVal) * maxBar;
                                final barW = (c.maxWidth * 0.55).clamp(10.0, 34.0).toDouble();
                                return SizedBox(
                                  width: c.maxWidth,
                                  height: c.maxHeight,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: h),
                                    duration: Duration(milliseconds: 600 + i * 80),
                                    curve: Curves.easeOutCubic,
                                    // Stack + Positioned: tidak bisa memicu "BOTTOM OVERFLOWED"
                                    builder: (_, val, __) => Stack(
                                      alignment: Alignment.bottomCenter,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: val + 6,
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text('${v}k',
                                                  style: TextStyle(
                                                      color: isMax
                                                          ? Colors.white
                                                          : Colors.white.withValues(alpha: 0.45),
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: barW,
                                          height: val,
                                          decoration: BoxDecoration(
                                            gradient: isMax
                                                ? const LinearGradient(
                                                    colors: [_primaryLight, _accent],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter)
                                                : null,
                                            color: isMax ? null : Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(9),
                                            boxShadow: isMax
                                                ? [
                                                    BoxShadow(
                                                        color: _primary.withValues(alpha: 0.45),
                                                        blurRadius: 14,
                                                        offset: const Offset(0, 4))
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: dayLabelH,
                            child: Center(
                              child: Text(_hari[i],
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: isMax ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11.5,
                                      fontWeight: isMax ? FontWeight.w800 : FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Kategori ─────────────────────────────────────────────
  Widget _categories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Per Kategori', onMore: () => _soon('Kategori')),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDeco(radius: 24),
          child: Column(
            children: List.generate(_kategori.length, (i) {
              final k = _kategori[i];
              final Color c = k['warna'] as Color;
              final double p = k['persen'] as double;
              return Padding(
                padding: EdgeInsets.only(bottom: i == _kategori.length - 1 ? 0 : 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(k['icon'] as IconData, color: c, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(k['nama'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(_rp(k['nilai'] as int),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 34,
                          child: Text('${(p * 100).round()}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: p),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(c),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Nota Terbaru (1 kolom di HP, 2 kolom di layar lebar) ─
  Widget _recentNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Nota Terbaru', onMore: () => _soon('Riwayat nota')),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, cons) {
            final twoCols = cons.maxWidth >= 640;
            const gap = 14.0;
            final itemW = twoCols ? (cons.maxWidth - gap) / 2 : cons.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: 12,
              children: _notaTerbaru.map((n) => SizedBox(width: itemW, child: _notaTile(n))).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _notaTile(Map<String, dynamic> n) {
    final bool lunas = n['lunas'] as bool;
    final Color warna = n['warna'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(n['icon'] as IconData, color: warna, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['judul'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(n['tanggal'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rp(n['total'] as int),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: (lunas ? _success : _warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(lunas ? 'Lunas' : 'Pending',
                    style: TextStyle(
                        color: lunas ? _success : _warning, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: const Text('Lihat semua',
                style: TextStyle(color: _primaryLight, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  // ── Helper ───────────────────────────────────────────────
  BoxDecoration _cardDeco({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  Widget _logoBadge(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _btnGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(Icons.receipt_long_rounded, size: iconSize, color: Colors.white),
    );
  }

  Widget _orb(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [BoxShadow(color: color.withValues(alpha: alpha * 0.6), blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }

  Widget _animatedIn(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 28 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}
