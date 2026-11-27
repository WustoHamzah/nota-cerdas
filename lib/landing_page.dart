import 'dart:async'; // Tambahkan import ini untuk Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  // ── Palet Warna (Disamakan dengan LoginPage) ─────────────
  static const Color _bg = Color(0xFF0D1117);           
  static const Color _primary = Color(0xFF6366F1);      
  static const Color _primaryLight = Color(0xFF818CF8); 
  static const Color _accent = Color(0xFF8B5CF6);       
  static const Color _ink = Color(0xFF1E293B);          

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

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  // ── State untuk Pop-up Nota Berganti-ganti ───────────────
  int _currentNotaIndex = 0;
  Timer? _notaTimer;

  // Data Nota yang akan ditampilkan
  final List<Map<String, dynamic>> _listNota = [
    {
      'judul': 'Nota Makan',
      'icon': Icons.restaurant_rounded,
      'item1': 'Kopi Susu',
      'harga1': 'Rp 36.000',
      'item2': 'Roti Bakar',
      'harga2': 'Rp 18.000',
      'total': 'Rp 54.000',
    },
    {
      'judul': 'Nota Belanja',
      'icon': Icons.shopping_basket_rounded,
      'item1': 'Beras 5kg',
      'harga1': 'Rp 75.000',
      'item2': 'Minyak 2L',
      'harga2': 'Rp 34.000',
      'total': 'Rp 109.000',
    },
    {
      'judul': 'Nota Transport',
      'icon': Icons.directions_car_rounded,
      'item1': 'Bensin',
      'harga1': 'Rp 50.000',
      'item2': 'Parkir',
      'harga2': 'Rp 5.000',
      'total': 'Rp 55.000',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Animasi melayang
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Animasi masuk halaman
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();

    // Timer untuk mengganti nota setiap 3 detik
    _notaTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentNotaIndex = (_currentNotaIndex + 1) % _listNota.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entryController.dispose();
    _notaTimer?.cancel(); // Hentikan timer saat halaman ditutup
    super.dispose();
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: Container(
          decoration: const BoxDecoration(gradient: _heroGradient),
          child: Stack(
            children: [
              Positioned(top: -100, right: -100, child: _orb(400, _primary, 0.15)),
              Positioned(bottom: 100, left: -150, child: _orb(350, _accent, 0.1)),
              
              SafeArea(
                child: FadeTransition(
                  opacity: _entryAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(_entryAnimation),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480), 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 32),
                              _buildHeroText(),
                              
                              // Ruang Ilustrasi & Pop-up Nota
                              Expanded(
                                flex: 4,
                                child: _buildIllustration(),
                              ),
                              
                              const SizedBox(height: 24),
                              _buildFeatureRow(),
                              const SizedBox(height: 32),
                              _buildMainButton(),
                              const SizedBox(height: 20),
                              _buildDots(), // Titik-titik yang sekarang berfungsi
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _logoBadge(52, 28),
        const SizedBox(width: 14),
        const Text(
          'Nota Cerdas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22, 
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ── 2. Teks Utama ──────────────────────────────────────
  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (b) => _btnGradient.createShader(b),
          child: const Text(
            'Kelola nota,\nlebih cerdas.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Simpan struk belanja, lacak pengeluaran, dan atur keuangan Anda dalam satu platform yang aman, cerdas, dan terintegrasi.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 15, 
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── 3. Ilustrasi 3D & Pop-up Nota Berganti ─────────────
  Widget _buildIllustration() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxIllSize = constraints.maxHeight > 280 ? 280 : constraints.maxHeight;
        final nota = _listNota[_currentNotaIndex]; 

        return Center(
          child: SizedBox(
            height: maxIllSize,
            width: maxIllSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Cahaya
                Container(
                  width: maxIllSize * 0.85,
                  height: maxIllSize * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_primary.withValues(alpha: 0.2), Colors.transparent],
                    ),
                  ),
                ),
                
                // Mockup HP
                Positioned(
                  bottom: maxIllSize * 0.05,
                  child: Container(
                    width: maxIllSize * 0.5,
                    height: maxIllSize * 0.8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _primary.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.receipt_long_rounded, size: maxIllSize * 0.2, color: _primary.withValues(alpha: 0.2)),
                    ),
                  ),
                ),

                // Pop-up Kertas Nota (Berganti-ganti)
                Positioned(
                  top: maxIllSize * 0.05,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.6),
                        child: Transform.rotate(
                          angle: -0.1,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey<int>(_currentNotaIndex), 
                              // Lebar diperbesar dari 0.45 ke 0.55 agar lebih lega
                              width: maxIllSize * 0.55, 
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Nota
                                  Row(
                                    children: [
                                      Icon(nota['icon'], size: maxIllSize * 0.06, color: _primary),
                                      const SizedBox(width: 6),
                                      Expanded( // Mencegah overflow pada judul
                                        child: Text(
                                          nota['judul'],
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: maxIllSize * 0.05, color: _ink),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey.shade300, height: 1),
                                  const SizedBox(height: 8),
                                  
                                  // Item 1
                                  _notaRow(nota['item1'], nota['harga1'], maxIllSize),
                                  const SizedBox(height: 6),
                                  // Item 2
                                  _notaRow(nota['item2'], nota['harga2'], maxIllSize),
                                  
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.grey.shade300, height: 1),
                                  const SizedBox(height: 8),
                                  
                                  // Total
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: maxIllSize * 0.045, color: _ink)),
                                      Text(nota['total'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: maxIllSize * 0.045, color: _primary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Ikon Kalkulator
                Positioned(
                  bottom: maxIllSize * 0.1,
                  right: maxIllSize * 0.05,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: _floatingIcon(Icons.calculate_rounded),
                      );
                    },
                  ),
                ),

                // Ikon Grafik (Digeser sedikit ke kanan agar tidak terpotong)
                Positioned(
                  top: maxIllSize * 0.15,
                  left: 10, 
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_floatAnimation.value),
                        child: _floatingIcon(Icons.show_chart_rounded),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Helper untuk baris item di nota (DIPERBAIKI)
  Widget _notaRow(String item, String harga, double size) {
    return Row(
      children: [
        // Teks nama item menggunakan Expanded agar bisa menyesuaikan ruang
        Expanded(
          child: Text(
            item, 
            style: TextStyle(fontSize: size * 0.04, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis, // Jika terlalu panjang, otomatis jadi "..."
          ),
        ),
        const SizedBox(width: 8), // Jarak antara nama dan harga
        // Teks harga
        Text(
          harga, 
          style: TextStyle(fontSize: size * 0.04, fontWeight: FontWeight.w600, color: _ink),
        ),
      ],
    );
  }

  Widget _floatingIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Icon(icon, color: _primaryLight, size: 22),
    );
  }

  // ── 4. Baris Fitur ─────────────────────────────────────
  Widget _buildFeatureRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(Icons.bolt_rounded, 'Transaksi\nCepat'),
          Container(width: 1, height: 35, color: Colors.white.withValues(alpha: 0.1)),
          _buildFeatureItem(Icons.shield_rounded, 'Data\nAman'),
          Container(width: 1, height: 35, color: Colors.white.withValues(alpha: 0.1)),
          _buildFeatureItem(Icons.bar_chart_rounded, 'Laporan\nLengkap'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _primaryLight, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ── 5. Tombol Utama ────────────────────────────────────
  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _btnGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _goToLogin,
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Login', 
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 6. Indikator Titik (Dots) ──────────────────────────
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_listNota.length, (index) {
        bool isActive = index == _currentNotaIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _primary : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── Helper ─────────────────────────────────────────────
  Widget _logoBadge(double size, double iconSize) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: _btnGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(color: _primary.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: iconSize),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: _primary, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: alpha * 0.6), blurRadius: 80, spreadRadius: 10),
        ],
      ),
    );
  }
}