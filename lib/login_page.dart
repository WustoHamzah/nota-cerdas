import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── Palet Warna ──────────────────────────────────────────
  static const Color _bg = Color(0xFF0D1117);           // latar gelap
  // static const Color _surface = Color(0xFF161B22);   // DIHAPUS: Tidak digunakan
  static const Color _primary = Color(0xFF6366F1);      // indigo
  static const Color _primaryLight = Color(0xFF818CF8); // indigo muda
  static const Color _accent = Color(0xFF8B5CF6);       // violet
  static const Color _ink = Color(0xFF1E293B);           // teks gelap
  static const Color _muted = Color(0xFF64748B);         // teks abu
  static const Color _fieldBg = Color(0xFFF8FAFC);      // latar input

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

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Logika login ─────────────────────────────────────────
  Future<void> _prosesLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await ApiService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('nama', res['user']['nama'].toString());
      await prefs.setString('email', res['user']['email'].toString());
      if (!mounted) return;
      _snack('Login berhasil! Selamat datang 🎉');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _snack(res['message'] ?? 'Login gagal', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: LayoutBuilder(
          builder: (ctx, cons) =>
              cons.maxWidth >= 900 ? _wide() : _compact(ctx),
        ),
      ),
    );
  }

  // ── Layout Lebar (laptop / web) ───────────────────────────
  Widget _wide() {
    return Row(
      children: [
        Expanded(flex: 5, child: _heroPanel()),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _animatedIn(_form()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroPanel() {
    return Container(
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: Stack(
        children: [
          Positioned(top: -80, right: -80,
              child: _orb(360, _primary, 0.15)),
          Positioned(bottom: -60, left: -60,
              child: _orb(280, _accent, 0.12)),
          Positioned(top: 200, left: 40,
              child: _orb(120, _primaryLight, 0.08)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logoRow(),
                    const SizedBox(height: 56),
                    _heroText(),
                    const SizedBox(height: 48),
                    _floatingReceipt(),
                    const SizedBox(height: 48),
                    _statsRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoRow() {
    return Row(
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

  Widget _heroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (b) => _btnGradient.createShader(b),
          child: const Text(
            'Kelola nota,\nlebih cerdas.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 50,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Simpan struk, lacak pengeluaran, dan atur\nkeuangan Anda dalam satu platform aman.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65), // Perbaikan withOpacity
            fontSize: 16,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statChip(Icons.receipt_long_rounded, '1.200+', 'Nota tersimpan'),
        const SizedBox(width: 16),
        _statChip(Icons.people_outline_rounded, '500+', 'Pengguna aktif'),
        const SizedBox(width: 16),
        _statChip(Icons.verified_user_outlined, '100%', 'Data aman'),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06), // Perbaikan withOpacity
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)), // Perbaikan withOpacity
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _primaryLight, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), // Perbaikan withOpacity
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _floatingReceipt() {
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.25), // Perbaikan withOpacity
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _btnGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Nota #0231',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            fontSize: 15)),
                  ],
                ),
                _badge('Lunas', const Color(0xFF16A34A),
                    const Color(0xFFDCFCE7)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 10),
            _rLine('Kopi Susu x2', 'Rp 36.000'),
            _rLine('Roti Bakar', 'Rp 18.000'),
            _rLine('Air Mineral', 'Rp 5.000'),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        fontSize: 15)),
                ShaderMask(
                  shaderCallback: (b) => _btnGradient.createShader(b),
                  child: const Text('Rp 59.000',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rLine(String a, String b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a,
                style: const TextStyle(color: _muted, fontSize: 13.5)),
            Text(b,
                style: const TextStyle(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _badge(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  // ── Layout Kompak (HP) ────────────────────────────────────
  Widget _compact(BuildContext ctx) {
    final media = MediaQuery.of(ctx);
    final bottomInset = media.viewPadding.bottom;
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Container(
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _orb(280, _primary, 0.18)),
          Positioned(top: 80, left: -80, child: _orb(200, _accent, 0.12)),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (_, cons) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.fromLTRB(
                              24, keyboardOpen ? 12 : 24, 24,
                              keyboardOpen ? 16 : 28),
                          child: keyboardOpen
                              ? _logoRow()
                              : Column(
                                  children: [
                                    _logoBadge(68, 36),
                                    const SizedBox(height: 16),
                                    ShaderMask(
                                      shaderCallback: (b) =>
                                          _btnGradient.createShader(b),
                                      child: const Text(
                                        'Nota Cerdas',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kelola nota, lebih cerdas.',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.65), // Perbaikan withOpacity
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        // Card Form
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32)),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                    24, 32, 24, 24 + bottomInset),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: _animatedIn(_form()),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────
  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Judul
          const Text('Selamat datang kembali 👋',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink)),
          const SizedBox(height: 6),
          const Text(
            'Masuk untuk melanjutkan mengelola nota Anda.',
            style: TextStyle(fontSize: 14.5, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Email
          _lbl('Email'),
          _field(
            ctrl: _emailCtrl,
            hint: 'nama@email.com',
            icon: Icons.alternate_email_rounded,
            type: TextInputType.emailAddress,
            action: TextInputAction.next,
            hints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email salah';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Password
          _lbl('Password'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _prosesLogin(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _deco(
              hint: 'Masukkan password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _muted,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Password wajib diisi'
                : null,
          ),
          const SizedBox(height: 10),

          // Ingat saya & lupa password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: _primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Ingat saya',
                        style: TextStyle(color: _ink, fontSize: 13.5)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Lupa password?',
                    style: TextStyle(
                        color: _primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tombol Login
          _gradBtn(),
          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('ATAU',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 20),

          // Daftar
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterPage())),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Buat akun baru',
              style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text('Data Anda tersimpan aman & terenkripsi',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper Widget ─────────────────────────────────────────
  Widget _gradBtn() {
    return Opacity(
      opacity: _isLoading ? 0.75 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _btnGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.4), // Perbaikan withOpacity
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : _prosesLogin,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Masuk',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _ink)),
      );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    Iterable<String>? hints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textInputAction: action,
      autofillHints: hints,
      enabled: !_isLoading,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _deco(hint: hint, icon: icon),
      validator: validator,
    );
  }

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.5),
      prefixIcon: Icon(icon, color: _muted, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldBg,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2)),
    );
  }

  Widget _logoBadge(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _btnGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.45), // Perbaikan withOpacity
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.receipt_long_rounded,
          size: iconSize, color: Colors.white),
    );
  }

  Widget _orb(double size, Color color, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha), // Perbaikan withOpacity
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: alpha * 0.6), // Perbaikan withOpacity
                blurRadius: 80,
                spreadRadius: 10),
          ],
        ),
      );

  Widget _animatedIn(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 28 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}