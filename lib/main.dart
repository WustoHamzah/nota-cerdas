import 'package:flutter/material.dart';
import 'landing_page.dart'; // Tambahkan import ini
// import 'login_page.dart'; // Sebenarnya ini sudah tidak dipakai di sini, bisa dihapus atau dibiarkan

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota Cerdas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Ubah bagian ini dari LoginPage menjadi LandingPage
      home: const LandingPage(), 
    );
  }
}