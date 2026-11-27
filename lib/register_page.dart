import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── Palet Warna (sama dengan LoginPage) ──────────────────
  static const Color _bg      = Color(0xFF0D1117);
  static const Color _primary = Color(0xFF6366F1);
  static const Color _pLight  = Color(0xFF818CF8);
  static const Color _accent  = Color(0xFF8B5CF6);
  static const Color _ink     = Color(0xFF1E293B);
  static const Color _muted   = Color(0xFF64748B);
  static const Color _fieldBg = Color(0xFFF8FAFC);

  static const LinearGradient _heroGrad = LinearGradient(
    colors: [Color(0xFF1A1040), _bg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _btnGrad = LinearGradient(
    colors: [_pLight, _primary, _accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final _formKey      = GlobalKey<FormState>();
  final _namaCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool   _isLoading      = false;
  bool   _obscurePass    = true;
  bool   _obscureConfirm = true;
  bool   _agreeTerms     = false;
  String _passValue      = '';

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _prosesRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _snack('Centang Syarat & Ketentuan terlebih dahulu.', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.register(
      nama: _namaCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final bool ok = res['success'] == true;
    _snack(
      res['message'] ?? (ok ? 'Registrasi berhasil' : 'Registrasi gagal'),
      error: !ok,
    );

    if (ok) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(msg)),
        ]),
        backgroundColor:
            error ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: LayoutBuilder(
          builder: (ctx, cons) =>
              cons.maxWidth >= 900 ? _wide() : _compact(ctx),
        ),
      ),
    );
  }

  // ── Layar lebar ──────────────────────────────────────────
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
                    child: _animIn(_form()),
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
      decoration: const BoxDecoration(gradient: _heroGrad),
      child: Stack(
        children: [
          Positioned(top: -80, right: -80,
              child: _orb(360, _primary, 0.15)),
          Positioned(bottom: -60, left: -60,
              child: _orb(280, _accent, 0.12)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logoRow(),
                    const SizedBox(height: 56),
                    ShaderMask(
                      shaderCallback: (b) => _btnGrad.createShader(b),
                      child: const Text(
                        'Buat akun,\nmulai mencatat.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daftar gratis dalam hitungan detik.\nLangsung simpan nota dan lacak pengeluaran.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 16,
                          height: 1.65),
                    ),
                    const SizedBox(height: 48),
                    _receiptMock(),
                    const SizedBox(height: 48),
                    _benefitList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoRow() => Row(
        children: [
          _logoBadge(52, 28),
          const SizedBox(width: 14),
          const Text('Nota Cerdas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6)),
        ],
      );

  Widget _benefitList() {
    final items = [
      (Icons.card_giftcard_rounded, 'Gratis selamanya'),
      (Icons.sync_rounded, 'Sinkron otomatis'),
      (Icons.block_rounded, 'Tanpa iklan'),
      (Icons.shield_outlined, 'Data terenkripsi'),
    ];
    return Column(
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.$1, color: _pLight, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(e.$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _receiptMock() {
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
              color: _primary.withValues(alpha: 0.25),
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
                        gradient: _btnGrad,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Nota #0001',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            fontSize: 15)),
                  ],
                ),
                _badge('Baru', _primary, const Color(0xFFEEF2FF)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 10),
            _rLine('Akun dibuat', '✓',
                valueColor: const Color(0xFF16A34A)),
            _rLine('Biaya pendaftaran', 'Rp 0',
                valueColor: const Color(0xFF16A34A)),
            _rLine('Akses fitur', 'Penuh'),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selamat bergabung!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        fontSize: 14)),
                const Text('🎉', style: TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rLine(String a, String b, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a, style: const TextStyle(color: _muted, fontSize: 13.5)),
            Text(b,
                style: TextStyle(
                    color: valueColor ?? _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _badge(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  // ── Layar kompak (HP) ────────────────────────────────────
  Widget _compact(BuildContext ctx) {
    final media        = MediaQuery.of(ctx);
    final bottomInset  = media.viewPadding.bottom;
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Container(
      decoration: const BoxDecoration(gradient: _heroGrad),
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
                              24,
                              keyboardOpen ? 10 : 20,
                              24,
                              keyboardOpen ? 14 : 24),
                          child: keyboardOpen
                              ? _logoRow()
                              : Column(
                                  children: [
                                    _logoBadge(68, 36),
                                    const SizedBox(height: 14),
                                    ShaderMask(
                                      shaderCallback: (b) =>
                                          _btnGrad.createShader(b),
                                      child: const Text('Nota Cerdas',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Buat akun, mulai mencatat.',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.65),
                                            fontSize: 14)),
                                  ],
                                ),
                        ),
                        // Sheet putih
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
                                    24, 28, 24, 20 + bottomInset),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: _animIn(_form()),
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

  // ── Form ─────────────────────────────────────────────────
  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Buat akun baru ✨',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 6),
          const Text('Isi data di bawah untuk mulai mengelola nota Anda.',
              style: TextStyle(fontSize: 14.5, color: _muted, height: 1.4)),
          const SizedBox(height: 24),

          // Nama
          _lbl('Nama lengkap'),
          TextFormField(
            controller: _namaCtrl,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            enabled: !_isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _deco(hint: 'Nama Anda',
                icon: Icons.person_outline_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
              if (v.trim().length < 3) return 'Nama minimal 3 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          _lbl('Email'),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !_isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _deco(hint: 'nama@email.com',
                icon: Icons.alternate_email_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!rx.hasMatch(v.trim())) return 'Format email salah';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _lbl('Password'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (v) => setState(() => _passValue = v),
            decoration: _deco(
              hint: 'Minimal 6 karakter',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _muted, size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          if (_passValue.isNotEmpty) ...[
            const SizedBox(height: 8),
            _strengthBar(_passValue),
          ],
          const SizedBox(height: 16),

          // Konfirmasi password
          _lbl('Konfirmasi password'),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _deco(
              hint: 'Ulangi password',
              icon: Icons.lock_reset_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _muted, size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }
              if (v != _passCtrl.text) return 'Password tidak sama';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Syarat & Ketentuan
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      activeColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 13.5, color: _ink, height: 1.4),
                          children: [
                            TextSpan(text: 'Saya setuju dengan '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _gradBtn(),
          const SizedBox(height: 20),

          _divider('ATAU'),
          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Sudah punya akun? Masuk',
                style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),

          _footer('Data Anda tersimpan aman & terenkripsi'),
        ],
      ),
    );
  }

  // ── Indikator kekuatan password ──────────────────────────
  Widget _strengthBar(String pwd) {
    int score = 0;
    if (pwd.length >= 6) score++;
    if (pwd.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) score++;
    score = score.clamp(1, 4);

    const labels = ['', 'Lemah', 'Cukup', 'Bagus', 'Kuat'];
    const colors = [
      Colors.transparent,
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFF22C55E),
    ];

    return Row(
      children: [
        ...List.generate(4, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < score
                      ? colors[score]
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
        const SizedBox(width: 10),
        Text(labels[score],
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors[score])),
      ],
    );
  }

  // ── Helper ───────────────────────────────────────────────
  Widget _gradBtn() {
    return Opacity(
      opacity: _isLoading ? 0.75 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _btnGrad,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : _prosesRegister,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Daftar Sekarang',
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
                fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
      );

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
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
            borderSide: const BorderSide(
                color: Color(0xFFEF4444), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFEF4444), width: 2)),
      );

  Widget _logoBadge(double size, double iconSize) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: _btnGrad,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.receipt_long_rounded,
            size: iconSize, color: Colors.white),
      );

  Widget _orb(double size, Color color, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: alpha * 0.6),
                blurRadius: 80,
                spreadRadius: 10),
          ],
        ),
      );

  Widget _divider(String label) => Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      );

  Widget _footer(String text) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(text,
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      );

  Widget _animIn(Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutQuart,
        builder: (_, v, c) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 28 * (1 - v)), child: c),
        ),
        child: child,
      );
}