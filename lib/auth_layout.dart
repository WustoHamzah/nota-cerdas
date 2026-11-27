import 'package:flutter/material.dart';

class AuthColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color primary = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color ink = Color(0xFF1E293B);
  static const Color muted = Color(0xFF64748B);
  static const Color fieldBg = Color(0xFFF1F5F9);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [navy, deepBlue, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Kerangka halaman login/register.
/// Layar >= 900px: split-screen. Layar kecil: header gradasi + sheet putih.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool showBack;

  const AuthLayout({super.key, required this.child, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= 900
              ? _buildWide(context)
              : _buildCompact(context);
        },
      ),
    );
  }

  // ---------- Layar lebar ----------
  Widget _buildWide(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 4,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AuthAnimatedIn(child: child),
                    ),
                  ),
                ),
                if (showBack)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      tooltip: 'Kembali',
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AuthColors.ink),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- HP / tablet portrait ----------
  Widget _buildCompact(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthColors.brandGradient),
      child: Stack(
        children: [
          Positioned(top: -90, right: -70, child: authCircle(260, 0.07)),
          Positioned(top: 90, left: -80, child: authCircle(180, 0.05)),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, cons) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: cons.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                            child: Column(
                              children: [
                                authLogoBadge(size: 72, iconSize: 38),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nota Cerdas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Catat nota, tanpa ribet.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(36)),
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 32, 24, 24),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 460),
                                    child: AuthAnimatedIn(child: child),
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
              },
            ),
          ),
          if (showBack)
            Positioned(
              top: 0,
              left: 4,
              child: SafeArea(
                child: IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================= Panel brand (layar lebar) =======================
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthColors.brandGradient),
      child: Stack(
        children: [
          Positioned(top: -120, right: -80, child: authCircle(320, 0.06)),
          Positioned(bottom: -140, left: -100, child: authCircle(380, 0.07)),
          Positioned(top: 180, left: -60, child: authCircle(160, 0.05)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          authLogoBadge(size: 48, iconSize: 26),
                          const SizedBox(width: 12),
                          const Text(
                            'Nota Cerdas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Catat nota,\ntanpa ribet.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kelola struk dan pengeluaran Anda di satu tempat, rapi dan mudah dicari.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Transform.rotate(angle: -0.04, child: _receiptMock()),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _featureChip(Icons.document_scanner_outlined,
                              'Simpan nota digital'),
                          _featureChip(
                              Icons.insights_outlined, 'Rekap pengeluaran'),
                          _featureChip(Icons.lock_outline, 'Data aman'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptMock() {
    Widget line(String a, String b, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a,
                  style: TextStyle(
                    fontSize: 13,
                    color: bold ? AuthColors.ink : AuthColors.muted,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  )),
              Text(b,
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthColors.ink,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  )),
            ],
          ),
        );

    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AuthColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Nota #0231',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AuthColors.ink)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Lunas',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Divider(height: 22),
          line('Kopi Susu x2', 'Rp 36.000'),
          line('Roti Bakar', 'Rp 18.000'),
          line('Air Mineral', 'Rp 5.000'),
          const Divider(height: 22),
          line('Total', 'Rp 59.000', bold: true),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ======================= Komponen bersama =======================

Widget authCircle(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );

Widget authLogoBadge({required double size, required double iconSize}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Icon(Icons.receipt_long_rounded,
        size: iconSize, color: AuthColors.primary),
  );
}

/// Label kecil di atas input.
class AuthLabel extends StatelessWidget {
  final String text;
  const AuthLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AuthColors.ink),
      ),
    );
  }
}

InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIcon: Icon(icon, color: AuthColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: AuthColors.fieldBg,
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(AuthColors.primary, 1.8),
    errorBorder: border(Colors.redAccent),
    focusedErrorBorder: border(Colors.redAccent, 1.8),
  );
}

/// Tombol gradasi utama.
class AuthGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLoading ? 0.8 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AuthColors.lightBlue, AuthColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AuthColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(icon, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animasi muncul (fade + geser naik).
class AuthAnimatedIn extends StatelessWidget {
  final Widget child;
  const AuthAnimatedIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

void showAuthSnack(BuildContext context, String message,
    {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}